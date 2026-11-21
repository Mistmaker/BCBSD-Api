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
    $codigo = $e instanceof ValidacionException ? 422 : 500;
    if ($e instanceof PDOException && ($e->errorInfo[0] ?? '') === '23505') {
        $codigo = 409;
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
