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

    if (!isset($_GET['id'])) {
        $database = new Database();
        $database->query("SELECT a.*,e.estacion_nombre,CONCAT(voluntario_apellidos, ' ', voluntario_nombres) AS voluntario_nombre_completo FROM subjefatura.tb_voluntarios_asignacion a INNER JOIN subjefatura.tb_voluntarios v ON v.voluntario_id = a.fk_voluntario_id INNER JOIN operaciones.tb_estaciones e ON e.estacion_id = a.fk_estacion_id order by asignacion_id LIMIT 100");
        $rows = $database->resultset();
        $database->closeConnection();
    } else {
        // limpia el parametro
        $id = htmlentities($_GET['id']);
        $database = new Database();
        $database->query("SELECT * FROM subjefatura.tb_voluntarios_asignacion WHERE asignacion_id = :id");
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
