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
    parse_str($_SERVER['QUERY_STRING'], $arrQueryStringParams);
    if (strtoupper($requestMethod) != 'GET') {
        $respuesta = json_encode(array('err' => false, 'mensaje' => 'Metodo no soportado'), JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
    }

    if (!isset($_GET['id'])) {
        $database = new Database();
        $database->query("SELECT vehiculo_id, vehiculo_sigla, vehiculo_placa, vehiculo_marca, vehiculo_modelo, vehiculo_tipo 
        FROM administrativo.tb_vehiculos v
        left join tthh.tb_direcciones d on d.direccion_id = v.fk_direccion_id
        left join operaciones.tb_estaciones e on e.estacion_id = v.fk_estacion_id
        WHERE vehiculo_id not in (select fk_unidad_id from logistica.tb_ordenesmovilizacion where orden_estado = 'SALIDA') 
        and v.vehiculo_area is not null and (d.direccion_nombre is not null or e.estacion_nombre is not null)
        ORDER BY vehiculo_sigla");
        $rows = $database->resultset();
        $database->closeConnection();
    } else {
        // limpia el parametro
        $id = htmlentities($_GET['id']);
        $database = new Database();
        $database->query("SELECT * FROM administrativo.tb_vehiculos WHERE vehiculo_id = :id");
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
