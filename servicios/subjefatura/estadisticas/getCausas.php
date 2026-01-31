<?php
// use Spipu\Html2Pdf\Html2Pdf;
// DB configuration
include_once("../../../classes/dbconfig.php");
include_once '../../../classes/database.class.php';
// Retorna un json
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

try {

    $requestMethod = $_SERVER["REQUEST_METHOD"];
    $arrQueryStringParams = array();
    parse_str($_SERVER['QUERY_STRING'], $arrQueryStringParams);
    if (strtoupper($requestMethod) != 'GET') {
        $respuesta = json_encode(array('err' => false, 'mensaje' => 'Metodo no soportado'), JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
    }

    if (isset($_GET['id_tipo'])) {
        $id_tipo = htmlentities($_GET['id_tipo']);
        $database = new Database();
        $database->query("SELECT * FROM subjefatura.tb_causas WHERE fk_incidencia_id = :id_tipo");
        $database->bind('id_tipo', $id_tipo);
        $rows = $database->resultset();
        $database->closeConnection();
    } else if (!isset($_GET['id'])) {
        $database = new Database();
        $database->query("SELECT * FROM subjefatura.tb_causas");
        $rows = $database->resultset();
        $database->closeConnection();
    } else {
        // limpia el parametro
        $id = htmlentities($_GET['id']);
        $database = new Database();
        $database->query("SELECT * FROM subjefatura.tb_causas WHERE causa_id = :id");
        $database->bind('id', $id);
        $rows = $database->single();
        $database->closeConnection();
    }
    echo json_encode($rows);
} catch (Throwable $th) {
    // throw $th;
    $respuesta = json_encode(array('err' => false, 'mensaje' => $th), JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
    echo $respuesta;
}
