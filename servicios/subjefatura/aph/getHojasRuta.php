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
        $database->query("SELECT * FROM subjefatura.tb_aph_hojaruta");
        $rows = $database->resultset();
        $database->closeConnection();
    } else {
        // limpia el parametro
        $id = htmlentities($_GET['id']);
        $database = new Database();
        $database->query("SELECT aph_hojaruta_id, fk_responsable_atencion, fk_tipo_emergencia, fk_estacion_id,s.state_id, t.town_id, fk_parroquia_id, aph_hojaruta_registro, aph_hojaruta_codigo, aph_hojaruta_codigo002, aph_hojaruta_fecha::date, aph_hojaruta_direccion, aph_hojaruta_hora_salida_estacion, aph_hojaruta_hora_retorno_estacion FROM subjefatura.tb_aph_hojaruta JOIN resources.parishes p on p.parish_id = fk_parroquia_id JOIN resources.towns t on t.town_id = p.fk_town_id JOIN resources.states s ON s.state_id = t.fk_state_id WHERE aph_hojaruta_id = :id");
        $database->bind('id', $id);
        $rows = $database->single();

        // obtener vehiculos
        $database->query("SELECT v.*,v1.vehiculo_sigla as fk_vehiculo_sigla,concat( persona_apellidos,' ',persona_nombres, ' - ', puesto_nombre ) as fk_operador_nombres 
        FROM subjefatura.tb_aph_hojaruta_vehiculos v 
        INNER JOIN administrativo.tb_vehiculos v1 on v.fk_vehiculo = v1.vehiculo_id
        inner join tthh.tb_personal_puestos pp ON pp.ppersonal_id = v.fk_operador 
        inner join tthh.tb_personal p on  p.personal_id = pp.fk_personal_id 
        inner join tthh.tb_puestos pu on pu.puesto_id = pp.fk_puesto_id 
        inner join resources.tb_personas pe on pe.persona_id = p.fk_persona_id ");
        $rows_v = $database->resultset();
        $rows['vehiculos'] = $rows_v;

        //obtener pacientes
        $database->query("SELECT * FROM subjefatura.tb_aph_hojaruta_pacientes");
        $rows_p = $database->resultset();
        $rows['pacientes'] = $rows_p;



        $database->closeConnection();
    }
    echo json_encode($rows);
} catch (Throwable $th) {
    // throw $th;
    $respuesta = json_encode(array('err' => false, 'mensaje' => $th), JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
    echo $respuesta;
}
