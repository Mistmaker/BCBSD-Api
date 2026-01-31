<?php
// use Spipu\Html2Pdf\Html2Pdf;
// DB configuration
include_once("../../classes/dbconfig.php");
include_once '../../classes/database.class.php';

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

    $sqlInter = "SELECT fk_rol_id FROM admin.tb_usuario_rol ";

    if (!isset($_GET['id'])) {
        $database = new Database();
        $database->query($sqlInter);
        $rows = $database->resultset();
        $database->closeConnection();
    } else {
        // limpia el parametro
        $id = htmlentities($_GET['id']);
        $database = new Database();
        $database->query("SELECT fk_rol_id FROM admin.tb_usuario_rol WHERE fk_usuario_id = :fk_usuario_id");
        $database->bind('fk_usuario_id', $id);
        $rowsRol = $database->resultset();
        $database->closeConnection();
        $rows = array_map(function($item) {
            return $item['fk_rol_id'];
        }, $rowsRol);
    }
    echo json_encode($rows);
} catch (Throwable $th) {
    // throw $th;
    $respuesta = json_encode(array('err' => false, 'mensaje' => $th), JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
    echo $respuesta;
}
