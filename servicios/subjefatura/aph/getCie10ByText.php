<?php
require_once __DIR__ . '/../../../classes/auth.php';
$auth = requireAuth();
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
    parse_str(($_SERVER['QUERY_STRING'] ?? ''), $arrQueryStringParams);
    if (strtoupper($requestMethod) != 'GET') {
        $respuesta = json_encode(array('err' => false, 'mensaje' => 'Metodo no soportado'), JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
    }
    $rows = array();
    if (isset($_GET['query'])) {
        // El texto se envía como parámetro (antes se pegaba en el SQL: inyección SQL). Busca también por código CIE-10.
        $texto = '%' . mb_strtoupper(trim((string) $_GET['query'])) . '%';
        $database = new Database();
        $database->query("SELECT cie_id, cie_codigo, cie_descripcion FROM resources.cie
                           WHERE upper(cie_descripcion) LIKE :t OR upper(cie_codigo) LIKE :t2 ORDER BY cie_descripcion LIMIT 100");
        $database->bind(':t', $texto);
        $database->bind(':t2', $texto);
        $rows = $database->resultset();
        $database->closeConnection();
    }
    echo json_encode($rows);
} catch (Throwable $th) {
    throw $th;
    $respuesta = json_encode(array('err' => false, 'mensaje' => $th), JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
    echo $respuesta;
}
