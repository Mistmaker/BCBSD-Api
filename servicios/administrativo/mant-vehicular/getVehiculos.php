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
        $database->query("SELECT v.*, d.direccion_nombre,e.estacion_nombre ,concat( persona_apellidos,' ',persona_nombres, ' - ', puesto_nombre ) as custodio_nombre  FROM administrativo.tb_vehiculos v
        inner join tthh.tb_personal_puestos pp ON pp.ppersonal_id = v.custodio_id 
        inner join tthh.tb_puestos pu on pu.puesto_id = pp.fk_puesto_id
        inner join tthh.tb_personal p on  p.personal_id = pp.fk_personal_id 
        inner join resources.tb_personas pe on pe.persona_id = p.fk_persona_id 
        left join tthh.tb_direcciones d on d.direccion_id = v.fk_direccion_id
        left join operaciones.tb_estaciones e on e.estacion_id = v.fk_estacion_id
        ORDER BY vehiculo_sigla");
        $rows = $database->resultset();
        $database->closeConnection();
    } else if ($_GET['id'] == 'asignados') {
        $database = new Database();
        $database->query("SELECT v.*, d.direccion_nombre,e.estacion_nombre ,concat( persona_apellidos,' ',persona_nombres, ' - ', puesto_nombre ) as custodio_nombre  FROM administrativo.tb_vehiculos v
        inner join tthh.tb_personal_puestos pp ON pp.ppersonal_id = v.custodio_id 
        inner join tthh.tb_puestos pu on pu.puesto_id = pp.fk_puesto_id
        inner join tthh.tb_personal p on  p.personal_id = pp.fk_personal_id 
        inner join resources.tb_personas pe on pe.persona_id = p.fk_persona_id 
        left join tthh.tb_direcciones d on d.direccion_id = v.fk_direccion_id
        left join operaciones.tb_estaciones e on e.estacion_id = v.fk_estacion_id
        WHERE v.vehiculo_area is not null and (d.direccion_nombre is not null or e.estacion_nombre is not null)
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
    $respuesta = json_encode(array('err' => true, 'mensaje' => $th), JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
    echo $respuesta;
}
