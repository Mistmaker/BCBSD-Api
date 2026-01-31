<?php
// use Spipu\Html2Pdf\Html2Pdf;
// DB configuration
include_once("../../classes/dbconfig.php");
include_once '../../classes/database.class.php';
// Retorna un json
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

try {

    $requestMethod = $_SERVER["REQUEST_METHOD"];
    $arrQueryStringParams = array();
    parse_str($_SERVER['QUERY_STRING'], $arrQueryStringParams);
    if (strtoupper($requestMethod) != 'GET') {
        $respuesta = json_encode(array('err' => true, 'mensaje' => 'Metodo no soportado'), JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
    }

    $sqlConductores = "select ppersonal_id, personal_id,persona_doc_identidad,persona_apellidos, persona_nombres, puesto_nombre, concat( persona_apellidos,' ',persona_nombres, ' ', puesto_nombre ) as nombre_completo from tthh.tb_personal p 
    inner join tthh.tb_personal_puestos pp ON pp.fk_personal_id = p.personal_id inner join tthh.tb_puestos pu on pu.puesto_id = pp.fk_puesto_id
    inner join resources.tb_personas pe on pe.persona_id = fk_persona_id WHERE ppersonal_estado ='EN FUNCIONES' order by persona_apellidos, persona_nombres";

    if (!isset($_GET['id'])) {
        $database = new Database();
        $database->query($sqlConductores);
        $rows = $database->resultset();
        $database->closeConnection();
    } else {
        // limpia el parametro
        $id = htmlentities($_GET['id']);
        $database = new Database();
        $database->query($sqlConductores);
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
