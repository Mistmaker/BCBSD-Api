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

    $sqlOrdenes = "SELECT orden_id, orden_serie, orden_estado, orden_codigo, vehiculo_sigla, vehiculo_placa, vehiculo_chasis, vehiculo_motor, orden_hora_salida, orden_kilometraje_salida, orden_motivo_salida, orden_destino, orden_hora_entrada, orden_kilometraje_entrada, orden_registro 
    ,(select nombre_completo from tthh.vw_personal_simple p1 where p1.ppersonal_id =  o.director_administrativo)  as dir_administrativo
    ,(select nombre_completo from tthh.vw_personal_simple p1 where p1.ppersonal_id =  o.personal_solicita)  as solicita
    ,(select nombre_completo from tthh.vw_conductores c1 where c1.conductor_id =  o.operador_id order by c1.ppersonal_id desc limit 1)  as operador
    ,(select usuario_login from admin.tb_usuarios u where u.usuario_id =  o.fk_usuario_id)  as usuario
    FROM logistica.tb_ordenesmovilizacion o
    inner join administrativo.tb_vehiculos v on v.vehiculo_id = o.fk_unidad_id ORDER BY orden_id DESC";

    $sqlInter = "SELECT * FROM operaciones.tb_distributivo_peloton dp INNER JOIN operaciones.tb_pelotones p ON p.peloton_id = dp.fk_peloton_id";

    if (!isset($_GET['id'])) {
        $database = new Database();
        $database->query($sqlInter);
        $rows = $database->resultset();
        $database->closeConnection();
    } else {
        // limpia el parametro
        $id = htmlentities($_GET['id']);
        $database = new Database();
        $database->query("SELECT * FROM operaciones.tb_distributivo_peloton dp INNER JOIN operaciones.tb_pelotones p ON p.peloton_id = dp.fk_peloton_id INNER JOIN operaciones.tb_estaciones e ON e.estacion_id = p.fk_estacion_id WHERE fk_distributivo_id = :id ORDER BY fk_estacion_id");
        $database->bind('id', $id);
        $rows = $database->resultset();
        // $rows = $database->single();
        $database->closeConnection();

        $estaciones = [];
        foreach ($rows as $row) {
            $id = $row['estacion_id'];

            if (!isset($estaciones[$id])) {
                $estaciones[$id] = [
                    'estacion_id' => $row['estacion_id'],
                    'estacion_nombre' => $row['estacion_nombre'],
                    'estacion_estado' => $row['estacion_estado'],
                    'pelotones' => []
                ];
            }

            $estaciones[$id]['pelotones'][] = [
                'peloton_id' => $row['peloton_id'],
                'peloton_nombre' => $row['peloton_nombre'],
                'dist_pelo_id' => $row['dist_pelo_id'],
                'fk_distributivo_id' => $row['fk_distributivo_id']
            ];
        }
        $rows = array_values($estaciones);
    }
    echo json_encode($rows);
} catch (Throwable $th) {
    // throw $th;
    $respuesta = json_encode(array('err' => false, 'mensaje' => $th), JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
    echo $respuesta;
}
