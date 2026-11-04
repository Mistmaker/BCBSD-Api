<?php
include_once("../../classes/dbconfig.php");
include_once '../../classes/database.class.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    header('Allow: GET, OPTIONS');
    echo json_encode(
        array('err' => true, 'mensaje' => 'Metodo no soportado'),
        JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE
    );
    exit;
}

try {
    $database = new Database();
    $database->query(
        "SELECT * FROM tthh.tb_jornadas_trabajo
         WHERE jornada_estado = 'ACTIVO'
         ORDER BY jornada_nombre"
    );
    $rows = $database->resultset();
    $database->closeConnection();

    echo json_encode($rows, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
} catch (Throwable $exception) {
    http_response_code(500);
    echo json_encode(
        array('err' => true, 'mensaje' => 'Error al consultar las jornadas de trabajo'),
        JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE
    );
}
