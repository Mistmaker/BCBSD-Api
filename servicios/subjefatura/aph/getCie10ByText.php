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
    $rows = array();
    if (isset($_GET['query'])) {
        $query = $_GET['query'];
        $searchParam = "'%" . strtoupper($query) . "%'";
        // print_r($searchParam);
        $database = new Database();
        $database->query("SELECT cie_id, cie_codigo, cie_descripcion FROM resources.cie WHERE cie_descripcion LIKE "."'%" . strtoupper($query) . "%'"." ORDER BY cie_descripcion LIMIT 100");
        // $database->bind('busqueda', $searchParam);
        $rows = $database->resultset();
        $database->closeConnection();
    }
    echo json_encode($rows);
} catch (Throwable $th) {
    throw $th;
    $respuesta = json_encode(array('err' => false, 'mensaje' => $th), JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
    echo $respuesta;
}
