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
        // $database->closeConnection();

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

            if ($row['estacion_tipo'] == 'ESTACION') {
                // OBTENER MIEMBROS DE LA TROPA
                // $database = new Database();
                $database->query("SELECT t.tropa_id,t.fk_dist_pelo_id,t.fk_personal_id,t.tropa_cargo, concat( persona_apellidos,' ',persona_nombres, ' - ', puesto_nombre ) as tropa_nombre_completo FROM operaciones.tb_tropas t inner join tthh.tb_personal_puestos pp ON pp.ppersonal_id = t.fk_personal_id  INNER JOIN tthh.tb_personal p ON p.personal_id = pp.fk_personal_id inner join tthh.tb_puestos pu on pu.puesto_id = pp.fk_puesto_id inner join resources.tb_personas pe on pe.persona_id = fk_persona_id WHERE t.fk_dist_pelo_id = :fk_dist_pelo_id ORDER BY tropa_id ASC");
                $database->bind('fk_dist_pelo_id', $row['dist_pelo_id']);
                $rowsTropas = $database->resultset();

                $rowsEncargados = array_filter($rowsTropas, function ($tropa) {
                    return $tropa['tropa_cargo'] === 'ENCARGADO DE ESTACION';
                });
                $rowsResponsables = array_filter($rowsTropas, function ($tropa) {
                    return $tropa['tropa_cargo'] === 'RESPONSABLE DE GUARDIA';
                });
                $rowsSubalternos = array_filter($rowsTropas, function ($tropa) {
                    return $tropa['tropa_cargo'] === 'SUBALTERNO DE GUARDIA';
                });
                $rowsResponsablesEquipos = array_filter($rowsTropas, function ($tropa) {
                    return $tropa['tropa_cargo'] === 'RESPONSABLE DE EQUIPOS DE RESCATE';
                });
                $rowsOperadores = array_filter($rowsTropas, function ($tropa) {
                    return $tropa['tropa_cargo'] === 'OPERADOR';
                });
                $rowsApoyoEmergencias = array_filter($rowsTropas, function ($tropa) {
                    return $tropa['tropa_cargo'] === 'APOYO A EMERGENCIAS';
                });
                $rowsAtencionAPH = array_filter($rowsTropas, function ($tropa) {
                    return $tropa['tropa_cargo'] === 'ATENCION PREHOSPITALARIA';
                });
                $rowsAsistenteAPH = array_filter($rowsTropas, function ($tropa) {
                    return $tropa['tropa_cargo'] === 'ASISTENTE PREHOSPITALARIA';
                });
                $rowsApoyoSbj = array_filter($rowsTropas, function ($tropa) {
                    return $tropa['tropa_cargo'] === 'APOYO DE SUBJEFATURA DE BOMBEROS';
                });
                $rowsApoyoCapacitacion = array_filter($rowsTropas, function ($tropa) {
                    return $tropa['tropa_cargo'] === 'APOYO CAPACITACION EN PREVENCION Y PRIMEROS AUXILIOS';
                });
                $rowsEcu911 = array_filter($rowsTropas, function ($tropa) {
                    return $tropa['tropa_cargo'] === 'ECU-911 CONSOLA DE DESPACHO Y APOYO A EMERGENCIAS';
                });


                $estaciones[$id]['pelotones'][] = [
                    'peloton_id' => $row['peloton_id'],
                    'peloton_nombre' => $row['peloton_nombre'],
                    'dist_pelo_id' => $row['dist_pelo_id'],
                    'fk_distributivo_id' => $row['fk_distributivo_id'],
                    'cargos' => array(
                        array("cargo_nombre" => "ENCARGADO DE ESTACION", "puestos" => array_values($rowsEncargados)),
                        array("cargo_nombre" => "RESPONSABLE DE GUARDIA", "puestos" => array_values($rowsResponsables)),
                        array("cargo_nombre" => "SUBALTERNO DE GUARDIA", "puestos" => array_values($rowsSubalternos)),
                        array("cargo_nombre" => "RESPONSABLE DE EQUIPOS DE RESCATE", "puestos" => array_values($rowsResponsablesEquipos)),
                        array("cargo_nombre" => "OPERADOR", "puestos" => array_values($rowsOperadores)),
                        array("cargo_nombre" => "APOYO A EMERGENCIAS", "puestos" => array_values($rowsApoyoEmergencias)),
                        array("cargo_nombre" => "ATENCION PREHOSPITALARIA", "puestos" => array_values($rowsAtencionAPH)),
                        array("cargo_nombre" => "ASISTENTE PREHOSPITALARIA", "puestos" => array_values($rowsAsistenteAPH)),
                        array("cargo_nombre" => "APOYO DE SUBJEFATURA DE BOMBEROS", "puestos" => array_values($rowsApoyoSbj)),
                        array("cargo_nombre" => "APOYO CAPACITACION EN PREVENCION Y PRIMEROS AUXILIOS", "puestos" => array_values($rowsApoyoCapacitacion)),
                        array("cargo_nombre" => "ECU-911 CONSOLA DE DESPACHO Y APOYO A EMERGENCIAS", "puestos" => array_values($rowsEcu911)),
                    )
                ];
            }

            if ($row['estacion_tipo'] == 'GRUPO' && $row["estacion_id"] == 9) { //GRUPO DE CANES DE BUSQUEDA Y LOCALIZACIÓN
                $database->query("SELECT t.tropa_id,t.fk_dist_pelo_id,t.fk_personal_id,t.tropa_cargo, concat( persona_apellidos,' ',persona_nombres, ' - ', puesto_nombre ) as tropa_nombre_completo FROM operaciones.tb_tropas t inner join tthh.tb_personal_puestos pp ON pp.ppersonal_id = t.fk_personal_id  INNER JOIN tthh.tb_personal p ON p.personal_id = pp.fk_personal_id inner join tthh.tb_puestos pu on pu.puesto_id = pp.fk_puesto_id inner join resources.tb_personas pe on pe.persona_id = fk_persona_id WHERE t.fk_dist_pelo_id = :fk_dist_pelo_id ORDER BY tropa_id ASC");
                $database->bind('fk_dist_pelo_id', $row['dist_pelo_id']);
                $rowsTropas = $database->resultset();

                $rowsLider = array_filter($rowsTropas, function ($tropa) {
                    return $tropa['tropa_cargo'] === 'LIDER DE GRUPO';
                });

                $rowsMiembros = array_filter($rowsTropas, function ($tropa) {
                    return $tropa['tropa_cargo'] === 'MIEMBRO DE GRUPO';
                });

                $estaciones[$id]['pelotones'][] = [
                    'peloton_id' => $row['peloton_id'],
                    'peloton_nombre' => $row['peloton_nombre'],
                    'dist_pelo_id' => $row['dist_pelo_id'],
                    'fk_distributivo_id' => $row['fk_distributivo_id'],
                    'cargos' => array(
                        array("cargo_nombre" => "LIDER DE GRUPO", "puestos" => array_values($rowsLider)),
                        array("cargo_nombre" => "MIEMBRO DE GRUPO", "puestos" => array_values($rowsMiembros)),
                    )
                ];
            }
            
            if ($row['estacion_tipo'] == 'GRUPO' && $row["estacion_id"] == 10) { //GRUPO DE DRONES
                $database->query("SELECT t.tropa_id,t.fk_dist_pelo_id,t.fk_personal_id,t.tropa_cargo, concat( persona_apellidos,' ',persona_nombres, ' - ', puesto_nombre ) as tropa_nombre_completo FROM operaciones.tb_tropas t inner join tthh.tb_personal_puestos pp ON pp.ppersonal_id = t.fk_personal_id  INNER JOIN tthh.tb_personal p ON p.personal_id = pp.fk_personal_id inner join tthh.tb_puestos pu on pu.puesto_id = pp.fk_puesto_id inner join resources.tb_personas pe on pe.persona_id = fk_persona_id WHERE t.fk_dist_pelo_id = :fk_dist_pelo_id ORDER BY tropa_id ASC");
                $database->bind('fk_dist_pelo_id', $row['dist_pelo_id']);
                $rowsTropas = $database->resultset();

                $rowsLider = array_filter($rowsTropas, function ($tropa) {
                    return $tropa['tropa_cargo'] === 'LIDER DE GRUPO';
                });

                $rowsMiembros = array_filter($rowsTropas, function ($tropa) {
                    return $tropa['tropa_cargo'] === 'MIEMBRO DE GRUPO';
                });

                $estaciones[$id]['pelotones'][] = [
                    'peloton_id' => $row['peloton_id'],
                    'peloton_nombre' => $row['peloton_nombre'],
                    'dist_pelo_id' => $row['dist_pelo_id'],
                    'fk_distributivo_id' => $row['fk_distributivo_id'],
                    'cargos' => array(
                        array("cargo_nombre" => "LIDER DE GRUPO", "puestos" => array_values($rowsLider)),
                        array("cargo_nombre" => "MIEMBRO DE GRUPO", "puestos" => array_values($rowsMiembros)),
                    )
                ];
            }
            
            if ($row['estacion_tipo'] == 'DIRECCION' && $row["estacion_id"] == 11) { // EFEESB
                $database->query("SELECT t.tropa_id,t.fk_dist_pelo_id,t.fk_personal_id,t.tropa_cargo, concat( persona_apellidos,' ',persona_nombres, ' - ', puesto_nombre ) as tropa_nombre_completo FROM operaciones.tb_tropas t inner join tthh.tb_personal_puestos pp ON pp.ppersonal_id = t.fk_personal_id  INNER JOIN tthh.tb_personal p ON p.personal_id = pp.fk_personal_id inner join tthh.tb_puestos pu on pu.puesto_id = pp.fk_puesto_id inner join resources.tb_personas pe on pe.persona_id = fk_persona_id WHERE t.fk_dist_pelo_id = :fk_dist_pelo_id ORDER BY tropa_id ASC");
                $database->bind('fk_dist_pelo_id', $row['dist_pelo_id']);
                $rowsTropas = $database->resultset();

                $rowsLider = array_filter($rowsTropas, function ($tropa) {
                    return $tropa['tropa_cargo'] === 'RESPONSABLE DE LA EFEESB';
                });

                $rowsMiembros = array_filter($rowsTropas, function ($tropa) {
                    return $tropa['tropa_cargo'] === 'APOYO EFEESB';
                });

                $estaciones[$id]['pelotones'][] = [
                    'peloton_id' => $row['peloton_id'],
                    'peloton_nombre' => $row['peloton_nombre'],
                    'dist_pelo_id' => $row['dist_pelo_id'],
                    'fk_distributivo_id' => $row['fk_distributivo_id'],
                    'cargos' => array(
                        array("cargo_nombre" => "RESPONSABLE DE LA EFEESB", "puestos" => array_values($rowsLider)),
                        array("cargo_nombre" => "APOYO EFEESB", "puestos" => array_values($rowsMiembros)),
                    )
                ];
            }
        }
        $database->closeConnection();
        $rows = array_values($estaciones);
    }
    echo json_encode($rows);
} catch (Throwable $th) {
    // throw $th;
    $respuesta = json_encode(array('err' => false, 'mensaje' => $th), JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
    echo $respuesta;
}
