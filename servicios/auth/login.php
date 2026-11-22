<?php
require_once __DIR__ . '/../../classes/auth.php';
// DB configuration
include_once("../../classes/dbconfig.php");
include_once '../../classes/database.class.php';
require_once __DIR__ . '/../../classes/usuarios.php';


// Retorna un json
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header("Access-Control-Allow-Headers: Origin, Content-Type, Accept, Authorization");
header("Access-Control-Allow-Methods: POST, PUT, OPTIONS");

// Función utilitaria para respuestas JSON con código HTTP
function jsonResponse($data, int $httpCode = 200)
{
    http_response_code($httpCode);
    echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}
function prop($obj, $prop, $default = null)
{
    return property_exists($obj, $prop) ? $obj->$prop : $default;
}
// fin de funciones utilitarias

// Manejar la preflight request (OPTIONS)
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    // Respondemos con éxito sin continuar ejecución
    http_response_code(200);
    exit();
}


$input = json_decode(file_get_contents("php://input"), true);
$usuario = trim((string) ($input['usuario'] ?? ''));
$password = (string) ($input['password'] ?? '');

$db = new Database();
$db->query("SELECT usuario_id, usuario_login, usuario_pass, COALESCE(usuario_estado, 'ACTIVO') AS usuario_estado, usuario_cambiar_pass
              FROM admin.tb_usuarios WHERE lower(usuario_login) = lower(:usuario) ORDER BY usuario_id LIMIT 1");
$db->bind(':usuario', $usuario);
$usuarioDb = $db->single();
[$claveValida, $nuevoHash] = usrVerificarClave($password, $usuarioDb['usuario_pass'] ?? null);

if (!$usuarioDb || !$claveValida) {
    jsonResponse(['error' => 'Credenciales inválidas'], 401);
}
if ($usuarioDb['usuario_estado'] !== 'ACTIVO') {
    jsonResponse(['error' => 'Usuario inactivo', 'msg' => 'Su usuario está inactivo. Comuníquese con el administrador del sistema.'], 403);
}
$usuarioId = (int) $usuarioDb['usuario_id'];
// Clave MD5 heredada (o algoritmo antiguo): se reemplaza por password_hash en este inicio de sesión
if ($nuevoHash) {
    $db->query('UPDATE admin.tb_usuarios SET usuario_pass = :h WHERE usuario_id = :id');
    $db->bind(':h', $nuevoHash);
    $db->bind(':id', $usuarioId);
    $db->execute();
}
try { // columna de la migración admin/01-usuarios-perfiles.sql: el login no debe fallar si aún no se ejecutó
    $db->query('UPDATE admin.tb_usuarios SET usuario_ultimo_acceso = CURRENT_TIMESTAMP(0) WHERE usuario_id = :id');
    $db->bind(':id', $usuarioId);
    $db->execute();
} catch (PDOException $e) {
}

try {
    $jwt = jwtEmitir(['tipo' => 'usuario', 'sub' => $usuarioId, 'nombre' => $usuarioDb['usuario_login'], 'modulo' => 'administrativo']);
} catch (AuthException $e) {
    jsonResponse(['error' => 'Configuración inválida', 'msg' => $e->getMessage()], 500);
}

// Privilegios efectivos: los del perfil + los adicionales del usuario
$privilegios = privilegiosUsuario($db, $usuarioId);
$db->closeConnection();

echo json_encode([
    'token' => $jwt,
    'expira_en' => JWT_EXP_SECONDS,
    'usuario' => [
        'usuario_id' => $usuarioId,
        'nombre' => $usuarioDb['usuario_login'],
        'menus' => menuUsuario($privilegios),
        'roles' => array_map('intval', array_column($privilegios, 'rol_id')),
        'permisos' => array_values(array_unique(array_filter(array_column($privilegios, 'rol_codigo')))),
        'rutas' => array_values(array_unique(array_filter(array_column($privilegios, 'rol_path')))),
        'cambiar_clave' => (bool) $usuarioDb['usuario_cambiar_pass'],
    ]
], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
