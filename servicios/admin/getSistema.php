<?php
require_once __DIR__ . '/../../classes/auth.php';
$auth = requireAuth();
require_once __DIR__ . '/../../classes/api.php';
// GET -> datos de la institución (nombre, siglas, logo, contacto) y parámetros por módulo (?modulo=MANTENIMIENTO)
apiMetodo(['GET']);
try {
    $db = new Database();
    $respuesta = institucion($db);
    if (!empty($_GET['modulo'])) {
        $db->query('SELECT param_key, param_value, param_type, param_name FROM admin.tb_params WHERE param_modulo = :m ORDER BY param_key');
        $db->bind(':m', (string) $_GET['modulo']);
        $respuesta['parametros'] = $db->resultset();
    }
    jsonResponse($respuesta);
} catch (Throwable $e) {
    apiError($e, 'Error al obtener los datos de la institución');
}
