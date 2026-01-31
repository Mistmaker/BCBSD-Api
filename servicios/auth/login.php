<?php
require_once '../../vendor/autoload.php';
// DB configuration
include_once("../../classes/dbconfig.php");
include_once '../../classes/database.class.php';

use \Firebase\JWT\JWT;

// Retorna un json
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header("Access-Control-Allow-Headers: Origin, Content-Type, Accept");
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


// Parámetros de configuración
$key = JWT_SECPWD;
$alg = 'HS256';

$input = json_decode(file_get_contents("php://input"), true);
$usuario = $input['usuario'] ?? '';
$password = $input['password'] ?? '';

$db = new Database();
$db->query("SELECT usuario_id, usuario_login, usuario_pass FROM admin.tb_usuarios WHERE usuario_login = :usuario");
$db->bind(':usuario', $usuario);
$usuarioDb = $db->single();
$db->closeConnection();

// if ($usuarioDb && password_verify($password, $usuarioDb['usuario_pass'])) {
if ($usuarioDb && $usuarioDb['usuario_pass'] == md5($password)) {
    $payload = [
        'iss' => 'cbsd-login-api',
        'iat' => time(),
        'exp' => time() + 3600,
        'sub' => $usuarioDb['usuario_id'],
        'nombre' => $usuarioDb['usuario_login']
    ];

    $jwt = JWT::encode($payload, $key, $alg);

    $db = new Database();
    $db->query("SELECT fk_usuario_id,rol_id,modulo_nombre,submodulo_nombre,rol_path FROM admin.tb_usuario_rol ur
                INNER JOIN admin.tb_roles r on r.rol_id = ur.fk_rol_id
                INNER JOIN admin.tb_submodulos s on s.submodulo_id = r.fk_submodulo_id
                INNER JOIN admin.tb_modulos m on m.modulo_id = s.fk_modulo_id WHERE rol_path IS NOT NULL AND fk_usuario_id = :fk_usuario_id");
    $db->bind(':fk_usuario_id', $usuarioDb['usuario_id']);
    $menusUsuario = $db->resultset();
    $db->closeConnection();
    
    $db = new Database();
    $db->query("SELECT fk_rol_id FROM admin.tb_usuario_rol WHERE fk_usuario_id = :fk_usuario_id");
    $db->bind(':fk_usuario_id', $usuarioDb['usuario_id']);
    $rolesUsuario = $db->resultset();
    $db->closeConnection();

    // Reestructuración
    foreach ($menusUsuario as $item) {
        $modulo = $item['modulo_nombre'];

        if (!isset($grouped[$modulo])) {
            $grouped[$modulo] = [
                'name' => $modulo,
                'url' => '/' . explode('/', $item['rol_path'])[1], // ej: "/admin", "/sbj"
                'icon' => 'fa fa-folder', // 👈 aquí puedes mapear íconos según el módulo
                'children' => []
            ];
        }

        $grouped[$modulo]['children'][] = [
            'name' => $item['submodulo_nombre'],
            'url'  => $item['rol_path'],
            'icon' => 'nav-icon-bullet'
        ];
    }

    $roles = array_map(function($item) {
        return $item['fk_rol_id'];
    }, $rolesUsuario);

    // Convertir en array numérico
    $navItems = array_values($grouped);

    echo json_encode([
        'token' => $jwt,
        'usuario' => [
            'usuario_id' => $usuarioDb['usuario_id'],
            'nombre' => $usuarioDb['usuario_login'],
            'menus' => $navItems,
            'roles' => $roles
        ]
    ]);
} else {
    http_response_code(401);
    echo json_encode(['error' => 'Credenciales inválidas']);
}
