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

    $sqlOrdenes = "SELECT orden_id, orden_serie, orden_estado, orden_codigo, vehiculo_sigla, vehiculo_placa, vehiculo_chasis, vehiculo_motor, orden_hora_salida, orden_kilometraje_salida, orden_motivo_salida, orden_destino, orden_hora_entrada, orden_kilometraje_entrada, orden_registro 
    ,(select nombre_completo from tthh.vw_personal_simple p1 where p1.ppersonal_id =  o.director_administrativo)  as dir_administrativo
    ,(select nombre_completo from tthh.vw_personal_simple p1 where p1.ppersonal_id =  o.personal_solicita)  as solicita
    ,(select nombre_completo from tthh.vw_conductores c1 where c1.conductor_id =  o.operador_id order by c1.ppersonal_id desc limit 1)  as operador
    ,(select usuario_login from admin.tb_usuarios u where u.usuario_id =  o.fk_usuario_id)  as usuario
    FROM logistica.tb_ordenesmovilizacion o
    inner join administrativo.tb_vehiculos v on v.vehiculo_id = o.fk_unidad_id ORDER BY orden_id DESC";

    $sqlInter = "SELECT * 
    FROM subjefatura.tb_intervenciones i
    INNER JOIN subjefatura.tb_tipoemergencia t ON i.fk_emergencia_id = t.emergencia_id
    INNER JOIN subjefatura.tb_causas c ON i.fk_causa_id = c.causa_id
    INNER JOIN subjefatura.tb_naturaleza n ON i.fk_naturaleza_id = n.naturaleza_id
    INNER JOIN subjefatura.tb_tipoincidencia ti ON i.fk_incidencia_id = ti.incidencia_id
    INNER JOIN operaciones.tb_estaciones e ON i.fk_estacion_id = e.estacion_id
    INNER JOIN administrativo.tb_vehiculos v ON i.fk_unidad_id = v.vehiculo_id
    INNER JOIN tthh.vw_personal_simple p ON i.fk_personal_id = p.ppersonal_id
    INNER JOIN resources.parishes pa on i.fk_parroquia_id = pa.parish_id";

    if (!isset($_GET['id'])) {
        $database = new Database();
        $database->query($sqlInter);
        $rows = $database->resultset();
        $database->closeConnection();
    } else {
        // limpia el parametro
        $id = htmlentities($_GET['id']);
        $database = new Database();
        $database->query("SELECT * FROM subjefatura.tb_intervenciones WHERE intervencion_id = :id");
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
