<?php
// use Spipu\Html2Pdf\Html2Pdf;
// DB configuration
include_once("../../../classes/dbconfig.php");
include_once '../../../classes/database.class.php';

// DEFINIR LA ZONA HORARIA
date_default_timezone_set('America/Guayaquil');

// Retorna un json
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

try {

    $requestMethod = $_SERVER["REQUEST_METHOD"];
    $arrQueryStringParams = array();
    parse_str($_SERVER['QUERY_STRING'], $arrQueryStringParams);
    if (strtoupper($requestMethod) != 'GET') {
        $respuesta = json_encode(array('err' => false, 'mensaje' => 'Metodo no soportado'), JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
        echo $respuesta;
        exit;
    }
    if (!isset($_GET['id'])) {
        $respuesta = json_encode(array('err' => false, 'mensaje' => 'Se requiere un id'), JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
        echo $respuesta;
        exit;
    }

    $sqlOrdenKm = "SELECT orden_id, orden_kilometraje_salida, orden_kilometraje_entrada from logistica.tb_ordenesmovilizacion where fk_unidad_id = :fk_unidad_id and orden_estado = 'ESTACION' ORDER BY orden_id desc limit 1";

    // limpia el parametro
    $id = htmlentities($_GET['id']);
    $database = new Database();
    $database->query($sqlOrdenKm);
    $database->bind('fk_unidad_id', $id);
    $rows = $database->single();
    $database->closeConnection();

    echo json_encode($rows);
} catch (Throwable $th) {
    // throw $th;
    $respuesta = json_encode(array('err' => false, 'mensaje' => $th), JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
    echo $respuesta;
}
