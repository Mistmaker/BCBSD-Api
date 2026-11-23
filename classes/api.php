<?php
/*
 * Utilidades comunes para endpoints JSON.
 * Uso: después de requireAuth(), require_once __DIR__ . '/../../../classes/api.php';
 */
require_once __DIR__ . '/dbconfig.php';
require_once __DIR__ . '/database.class.php';

date_default_timezone_set('America/Guayaquil');

if (!function_exists('jsonResponse')) {
    function jsonResponse($data, int $httpCode = 200)
    {
        http_response_code($httpCode);
        header('Content-Type: application/json');
        echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        exit;
    }
}

if (!function_exists('prop')) {
    function prop($obj, $prop, $default = null)
    {
        return (is_object($obj) && property_exists($obj, $prop)) ? $obj->$prop : $default;
    }
}

/** Corta la ejecución con 405 si el método HTTP no está permitido. Devuelve el método en mayúsculas. */
function apiMetodo(array $permitidos): string
{
    $metodo = strtoupper($_SERVER['REQUEST_METHOD'] ?? 'GET');
    if (!in_array($metodo, $permitidos, true)) {
        jsonResponse(['error' => 'Método no permitido'], 405);
    }
    return $metodo;
}

/** Cuerpo JSON de la petición como objeto; 400 si no es JSON válido. */
function apiCuerpoJson(): object
{
    $datos = json_decode(file_get_contents('php://input'));
    if (!is_object($datos)) {
        jsonResponse(['error' => 'Datos JSON inválidos'], 400);
    }
    return $datos;
}

/** Parámetro entero de la URL (?id=); null si no viene; 400 si no es un entero positivo. */
function apiParamId(string $nombre = 'id'): ?int
{
    if (!isset($_GET[$nombre]) || $_GET[$nombre] === '') {
        return null;
    }
    $valor = filter_var($_GET[$nombre], FILTER_VALIDATE_INT, ['options' => ['min_range' => 1]]);
    if ($valor === false) {
        jsonResponse(['error' => "Parámetro '$nombre' inválido"], 400);
    }
    return $valor;
}

/** Error genérico: registra el detalle en el log de PHP y devuelve un mensaje seguro. */
function apiError(Throwable $e, string $mensaje = 'Error al procesar la solicitud'): void
{
    error_log($e->getMessage() . "\n" . $e->getTraceAsString());
    $detalle = $e instanceof ValidacionException ? $e->getMessage() : null;
    if ($e instanceof PDOException && ($e->errorInfo[0] ?? '') === '23505') {
        $detalle = 'Ya existe un registro con esos datos.';
    }
    if ($e instanceof PDOException && ($e->errorInfo[0] ?? '') === '23503') {
        $detalle = 'Alguno de los registros relacionados (vehículo, persona, contrato...) no existe.';
    }
    $codigo = $e instanceof ValidacionException ? 422 : 500;
    if ($e instanceof PDOException && ($e->errorInfo[0] ?? '') === '23505') {
        $codigo = 409;
    }
    if ($e instanceof PDOException && ($e->errorInfo[0] ?? '') === '23503') {
        $codigo = 422;
    }
    jsonResponse(['error' => $mensaje, 'msg' => $detalle ?? $mensaje], $codigo);
}

class ValidacionException extends RuntimeException
{
}

/** Datos de la institución (admin.tb_sistema) con valores por defecto. */
function institucion(Database $db): array
{
    try {
        $db->query('SELECT * FROM admin.tb_sistema ORDER BY sistema_id LIMIT 1');
        $fila = $db->single() ?: [];
    } catch (PDOException $e) {
        $fila = [];
    }
    return array_merge(['sistema_nombre' => 'CUERPO DE BOMBEROS', 'sistema_siglas' => 'CBSD'], array_filter($fila, fn($v) => $v !== null));
}

/** Valor de un parámetro de admin.tb_params. */
function parametro(Database $db, string $clave, $porDefecto = null)
{
    try {
        $db->query('SELECT param_value FROM admin.tb_params WHERE param_key = :k');
        $db->bind(':k', $clave);
        $fila = $db->single();
    } catch (PDOException $e) {
        $fila = false;
    }
    return $fila ? $fila['param_value'] : $porDefecto;
}

/** Códigos de privilegio (admin.tb_roles.rol_codigo) asignados al usuario autenticado. */
function permisosUsuario(Database $db, ?int $usuarioId = null): array
{
    $usuarioId = $usuarioId ?? authUsuarioId();
    if ($usuarioId === null) {
        return [];
    }
    return array_values(array_unique(array_filter(array_column(privilegiosUsuario($db, $usuarioId), 'rol_codigo'))));
}

/**
 * Privilegios EFECTIVOS de un usuario: los de su perfil + los adicionales (vista admin.vw_usuario_privilegios), solo si
 * el usuario y el perfil están ACTIVOS. Filas: rol_id, rol_codigo, rol_path, rol_nombre, submodulo_nombre, modulo_nombre, origen.
 * En una base sin la migración de perfiles usa solo admin.tb_usuario_rol.
 */
function privilegiosUsuario(Database $db, int $usuarioId): array
{
    // Orden y grupos del menú con to_jsonb: el login funciona aunque aún no se haya ejecutado la migración del menú
    $sql = fn(string $fuente) => "SELECT DISTINCT ON (r.rol_id) r.rol_id, r.rol_codigo, r.rol_path, r.rol_nombre, s.submodulo_id, s.submodulo_nombre,
                     m.modulo_id, m.modulo_nombre, x.origen,
                     COALESCE((to_jsonb(m) ->> 'modulo_orden')::int, 100) AS modulo_orden,
                     COALESCE((to_jsonb(s) ->> 'submodulo_orden')::int, 100) AS submodulo_orden,
                     COALESCE(to_jsonb(s) ->> 'submodulo_menu', 'GRUPO') AS submodulo_menu,
                     COALESCE((to_jsonb(r) ->> 'rol_orden')::int, 100) AS rol_orden, to_jsonb(r) ->> 'rol_menu' AS rol_menu
              FROM $fuente x JOIN admin.tb_roles r ON r.rol_id = x.rol_id
              JOIN admin.tb_submodulos s ON s.submodulo_id = r.fk_submodulo_id JOIN admin.tb_modulos m ON m.modulo_id = s.fk_modulo_id
             WHERE x.usuario_id = :u AND (to_jsonb(r) ->> 'rol_estado') IS DISTINCT FROM 'INACTIVO'
             ORDER BY r.rol_id, (x.origen = 'PERFIL') DESC";
    try {
        $db->query($sql('admin.vw_usuario_privilegios'));
        $db->bind(':u', $usuarioId);
        return $db->resultset();
    } catch (PDOException $e) {
        $db->query($sql("(SELECT fk_usuario_id AS usuario_id, fk_rol_id AS rol_id, 'USUARIO'::text AS origen FROM admin.tb_usuario_rol)"));
        $db->bind(':u', $usuarioId);
        return $db->resultset();
    }
}

/**
 * Menú del usuario: módulo -> grupo (submódulo) -> pantalla, cada nivel por su orden (modulo_orden, submodulo_orden,
 * rol_orden; luego por nombre). Sin carpeta: los submódulos 'DIRECTO' (Panel), los grupos con una sola pantalla visible
 * y el grupo único de un módulo. El texto es rol_menu (corto) o rol_nombre.
 */
function menuUsuario(array $privilegios): array
{
    $pantallas = array_values(array_filter($privilegios, fn($p) => !empty($p['rol_path'])));
    $n = fn($p, $k, $d = 100) => (int) ($p[$k] ?? $d);
    usort($pantallas, fn($a, $b) => [$n($a, 'modulo_orden'), $a['modulo_nombre'], $n($a, 'submodulo_orden'), $a['submodulo_nombre'] ?? '',
        $n($a, 'rol_orden'), (int) $a['rol_id']] <=> [$n($b, 'modulo_orden'), $b['modulo_nombre'], $n($b, 'submodulo_orden'), $b['submodulo_nombre'] ?? '',
        $n($b, 'rol_orden'), (int) $b['rol_id']]);
    $modulos = [];
    foreach ($pantallas as $p) {
        $modulos[$p['modulo_nombre']][$p['submodulo_nombre'] ?? ''][] = $p;
    }
    $item = fn($p) => ['name' => ($p['rol_menu'] ?? null) ?: $p['rol_nombre'], 'url' => $p['rol_path'], 'icon' => 'nav-icon-bullet'];
    $menu = [];
    foreach ($modulos as $modulo => $grupos) {
        $primero = reset($grupos)[0];
        $url = '/' . explode('/', $primero['rol_path'])[1];
        $hijos = [];
        foreach ($grupos as $grupo => $items) {
            if (count($grupos) === 1 || count($items) === 1 || ($items[0]['submodulo_menu'] ?? 'GRUPO') === 'DIRECTO') {
                array_push($hijos, ...array_map($item, $items));
            } else {
                // El menú de CoreUI necesita la url del grupo: la del módulo (el grupo se abre al entrar al módulo)
                $hijos[] = ['name' => $grupo, 'url' => $url, 'icon' => 'fa fa-folder-open', 'children' => array_map($item, $items)];
            }
        }
        $menu[] = ['name' => $modulo, 'url' => $url, 'icon' => 'fa fa-folder', 'children' => $hijos];
    }
    return $menu;
}

/**
 * Corta con 403 si el usuario no tiene ninguno de los privilegios indicados.
 * Llamar ANTES de preparar otras sentencias (comparte la conexión).
 */
function requirePermiso(Database $db, string ...$codigos): void
{
    if (!array_intersect($codigos, permisosUsuario($db))) {
        jsonResponse(['error' => 'Sin permiso', 'msg' => 'No tiene el privilegio necesario para esta acción (' . implode(' o ', $codigos) . ').'], 403);
    }
}
