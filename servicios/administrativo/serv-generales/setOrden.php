<?php
// error_reporting(E_ALL);
// ini_set('display_errors', 1);
// use \Firebase\JWT\JWT;
// use \Firebase\JWT\Key;
// DB configuration
include_once("../../../classes/dbconfig.php");
include_once '../../../classes/database.class.php';

// Obtener el token desde el header Authorization
// $headers = getallheaders();
// $auth = $headers['Authorization'] ?? '';

// if (!$auth || !str_starts_with($auth, 'Bearer ')) {
//     http_response_code(401);
//     echo json_encode(['error' => 'Token no proporcionado']);
//     exit;
// }
// $token = str_replace('Bearer ', '', $auth);
// // Validar y decodificar
// try {
//     $key = JWT_SECPWD; // tu clave secreta
//     $decoded = JWT::decode($token, new Key($key, 'HS256'));
//     // Aquí accedes al usuario_id (que fue almacenado como "sub")
//     $usuario_id = $decoded->sub;
// } catch (Exception $e) {
//     http_response_code(401);
//     echo json_encode(['error' => 'Token inválido']);
//     exit;
// }

// Retorna un json
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header("Access-Control-Allow-Headers: Origin, Content-Type, Accept");
header("Access-Control-Allow-Methods: POST, PUT, OPTIONS");

// DEFINIR LA ZONA HORARIA
date_default_timezone_set('America/Guayaquil');

$entity = 'ordenesmovilizacion';

// Manejar la preflight request (OPTIONS)
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    // Respondemos con éxito sin continuar ejecución
    http_response_code(200);
    exit();
}

// echo json_encode($request);
try {

    // $arrQueryStringParams = array();
    // parse_str($_SERVER['QUERY_STRING'], $arrQueryStringParams);
    $requestMethod = $_SERVER["REQUEST_METHOD"];
    if (!in_array(strtoupper($requestMethod), array("POST", "PUT"))) {
        jsonResponse(['error' => 'Método no permitido'], 405);
    }

    $postdata = file_get_contents("php://input");
    $request = json_decode($postdata);
    if (!$request) {
        jsonResponse(['error' => 'Datos JSON inválidos'], 400);
    }

    $database = new Database();
    $database->beginTransaction();

    // Obtener al director administrativo
    // 'vw_personal',"WHERE puesto_id=4 AND ppersonal_estado='EN FUNCIONES'
    $sqlDirAdmin = "select ppersonal_id,personal_id,persona_doc_identidad,persona_apellidos, persona_nombres, puesto_nombre, concat( persona_apellidos,' ',persona_nombres, ' ', puesto_nombre ) as nombre_completo from tthh.tb_personal p 
    inner join tthh.tb_personal_puestos pp ON pp.fk_personal_id = p.personal_id inner join tthh.tb_puestos pu on pu.puesto_id = pp.fk_puesto_id
    inner join resources.tb_personas pe on pe.persona_id = fk_persona_id WHERE ppersonal_estado ='EN FUNCIONES' and puesto_id=4 order by persona_apellidos, persona_nombres";
    
    $sqlCustodio = "SELECT custodio_id,d.direccion_codigo,e.estacion_nombre
    FROM administrativo.tb_vehiculos v
    left join tthh.tb_direcciones d on d.direccion_id = v.fk_direccion_id
    left join operaciones.tb_estaciones e on e.estacion_id = v.fk_estacion_id
    where v.vehiculo_id = :vehiculo_id";

    $database->query($sqlCustodio);
    $database->bind('vehiculo_id', prop($request, 'fk_unidad_id'));
    $dataDirAdmin = $database->single();
    $request->director_administrativo = $dataDirAdmin["custodio_id"]; // TODO: reemplazar por custodio del vehiculo
    $origen = '';
    if (isset($dataDirAdmin["direccion_codigo"])) {
        $origen = $dataDirAdmin["direccion_codigo"];
    } else if (isset($dataDirAdmin["estacion_nombre"])) {
        $origen = $dataDirAdmin["estacion_nombre"];
    }

    if (!isset($request->orden_id)) {

        // VALIDAR ORDEN YA EXISTENTE
        $sqlOrden = "SELECT orden_id, orden_kilometraje_salida, orden_kilometraje_entrada from logistica.tb_ordenesmovilizacion where fk_unidad_id = :fk_unidad_id and orden_estado = 'SALIDA' ORDER BY orden_id desc limit 1";
        $database->query($sqlOrden);
        $database->bind('fk_unidad_id', prop($request, 'fk_unidad_id'));
        $orden = $database->single();
        if ($orden) {
            jsonResponse(['error' => 'Error al guardar', 'msg' => "Ya existe una orden generada para la unidad seleccionada, no se puede emitir una nueva orden hasta que la misma retorne a la estación"], 500);
        }

        // VALIDAR KILOMETRAJE
        $sqlOrdenKm = "SELECT orden_id, orden_kilometraje_salida, orden_kilometraje_entrada from logistica.tb_ordenesmovilizacion where fk_unidad_id = :fk_unidad_id and orden_estado = 'ESTACION' ORDER BY orden_id desc limit 1";
        $database->query($sqlOrdenKm);
        $database->bind('fk_unidad_id', prop($request, 'fk_unidad_id'));
        $dataKm = $database->single();

        if ($dataKm) {
            if ($dataKm["orden_kilometraje_entrada"] <> $request->orden_kilometraje_salida) {
                jsonResponse(['error' => 'Error al guardar', 'msg' => "El kilometraje de salida {$request->orden_kilometraje_salida} no coincide con el último kilometraje de entrada {$dataKm["orden_kilometraje_entrada"]} de la unidad seleccionada"], 500);
            }
        }

        // Obtener serie y codigo
        $datosCodigo = nextCodeProject($origen);
        // print_r($datosCodigo);
        $request->orden_codigo = $datosCodigo["code"];
        $request->orden_codigo_serie = $datosCodigo["orden_codigo_serie"];
        $request->orden_serie = $datosCodigo["serie"];

        if ($request->orden_hora_salida_tipo == 'SISTEMA') {
            $request->orden_hora_salida = date("Y-m-d H:i:s");
        }

        $database->query('INSERT INTO logistica.tb_ordenesmovilizacion (
            fk_usuario_id, fk_unidad_id, operador_id, director_administrativo, tecnico_servicios,
            orden_codigo, orden_codigo_serie, orden_serie, orden_destino, orden_motivo_salida, personal_solicita,
            orden_hora_salida_tipo, orden_hora_salida, orden_kilometraje_salida,
            orden_hora_entrada_tipo, orden_hora_entrada, orden_kilometraje_entrada, orden_observaciones
        ) VALUES (
            :fk_usuario_id, :fk_unidad_id, :operador_id, :director_administrativo, :tecnico_servicios,
            :orden_codigo, :orden_codigo_serie, :orden_serie, :orden_destino, :orden_motivo_salida, :personal_solicita,
            :orden_hora_salida_tipo, :orden_hora_salida, :orden_kilometraje_salida,
            :orden_hora_entrada_tipo, :orden_hora_entrada, :orden_kilometraje_entrada, :orden_observaciones
        ) RETURNING orden_id
        ');

        $database->bind(':fk_usuario_id', prop($request, 'fk_usuario_id'));
        $database->bind(':fk_unidad_id', prop($request, 'fk_unidad_id'));
        $database->bind(':operador_id', prop($request, 'operador_id'));
        $database->bind(':director_administrativo', prop($request, 'director_administrativo'));
        $database->bind(':tecnico_servicios', prop($request, 'tecnico_servicios'));
        $database->bind(':orden_codigo', prop($request, 'orden_codigo'));
        $database->bind(':orden_codigo_serie', prop($request, 'orden_codigo_serie')); //
        $database->bind(':orden_serie', prop($request, 'orden_serie'));
        $database->bind(':orden_destino', prop($request, 'orden_destino'));
        $database->bind(':orden_motivo_salida', prop($request, 'orden_motivo_salida'));
        $database->bind(':personal_solicita', prop($request, 'personal_solicita'));
        $database->bind(':orden_hora_salida_tipo', prop($request, 'orden_hora_salida_tipo'));
        $database->bind(':orden_hora_salida', prop($request, 'orden_hora_salida'));
        $database->bind(':orden_kilometraje_salida', prop($request, 'orden_kilometraje_salida'));
        $database->bind(':orden_hora_entrada_tipo', prop($request, 'orden_hora_entrada_tipo'));
        $database->bind(':orden_hora_entrada', prop($request, 'orden_hora_entrada'));
        $database->bind(':orden_kilometraje_entrada', prop($request, 'orden_kilometraje_entrada'));
        $database->bind(':orden_observaciones', prop($request, 'orden_observaciones'));

        $inserted = $database->single(); // ejecuta y devuelve resultado
        if (!$inserted) {
            jsonResponse(['error' => 'Error al insertar', 'msg' => $database->getErrors()[2]], 500);
        }
        $database->endTransaction();
        $database->closeConnection();
        jsonResponse(['msg' => 'Registro creado con exito', 'id' => $inserted['orden_id']], 201);
    } else {

        if ($request->orden_hora_entrada_tipo == 'SISTEMA') {
            $request->orden_hora_entrada = date("Y-m-d H:i:s");
        }

        $database->query('UPDATE logistica.tb_ordenesmovilizacion SET
                            orden_estado = :orden_estado,
                            orden_hora_entrada_tipo = :orden_hora_entrada_tipo,
                            orden_hora_entrada = :orden_hora_entrada,
                            orden_kilometraje_entrada = :orden_kilometraje_entrada,
                            orden_observaciones = :orden_observaciones
                        WHERE orden_id = :orden_id
        ');

        $database->bind(':orden_id', prop($request, 'orden_id'));
        $database->bind(':orden_estado', 'ESTACION');
        $database->bind(':orden_hora_entrada_tipo', prop($request, 'orden_hora_entrada_tipo'));
        $database->bind(':orden_hora_entrada', prop($request, 'orden_hora_entrada'));
        $database->bind(':orden_kilometraje_entrada', prop($request, 'orden_kilometraje_entrada'));
        $database->bind(':orden_observaciones', prop($request, 'orden_observaciones'));
        $success = $database->execute();

        if (!$success) {
            jsonResponse(['error' => 'Error al actualizar', 'msg' => $database->getErrors()[2]], 500);
        }
        $database->endTransaction();
        $database->closeConnection();
        jsonResponse(['msg' => 'Registro actualizado con exito', 'id' => $request->orden_id], 200);
    }
} catch (Throwable $th) {
    // throw $th;
    // $respuesta = json_encode(array('err' => true, 'mensaje2' => $th), JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
    $database->cancelTransaction();
    jsonResponse([
        'error' => 'Excepción no controlada',
        'message' => $th->getMessage(),
        'trace' => $th->getTraceAsString()
    ], 500);
}

/*
* FUNCIONES NECESARIAS PARA EL ARCHIVO
*/
// Función utilitaria para respuestas JSON con código HTTP
function jsonResponse($data, int $httpCode = 200)
{
    http_response_code($httpCode);
    echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}
function prop($obj, $prop, $default = null)
{
    return property_exists($obj, $prop) ? $obj->$prop : $default;
}

function getFecha($formato = 'Y-m-d')
{
    // $calendar=$this->getConfig('calendar');
    // $dias=$calendar['days'];
    // $meses=$calendar['months'];
    // $complete=$dias[date('w')].", ".date('d')." de ".$meses[date('n')-1]. " de ".date('Y');
    if ($formato == 'lastEndMonth') return date("Y-m-t", strtotime(getFecha() . "- 1 month"));
    elseif ($formato == 'currentEndMonth') return date("Y-m-t", strtotime(getFecha()));
    // elseif($formato=='complete')return $complete;
    // elseif($formato=='full')return "{$complete} - ".date('h:i:s A');
    elseif ($formato == 'dateTime') return date('Y-m-d H:i:s');
    else return date($formato);
}
// fin de funciones utilitarias

/*
* GENERADOR DE CÓDIGO DE PROYECTOS
*/
function nextCodeProject($origen)
{
    // DEFINIR PREFIJO DE SERIE
    $pref = "BCBSD";
    // DEFINIR AÑO EN CURSO
    $year = date('y');
    // DEFINIR SIGUIENTE ID DE PROYECTO
    // $entityId = getNextId($entity);
    // OBTENER PREFIJO DE PROYECTO
    $project = 'MOV';
    // CONSULTAR ÚLTIMO ID DE CÓDIGO GENERADO DEL AÑO
    $database = new Database();
    $database->query("SELECT MAX(orden_codigo_serie) as id FROM logistica.tb_ordenesmovilizacion WHERE (date_part('year',orden_registro)=date_part('year',CURRENT_DATE)) AND orden_codigo like '{$pref}{$year}{$project}{$origen}%'");
    $row = $database->single();
    $database->closeConnection();
    $id = ($row['id'] == null ? 0 : $row['id']) + 1;
    // CONSULTAR ÚLTIMO ID DE CÓDIGO GENERADO DEL AÑO POR ESTACION
    // $database = new Database();
    // $database->query("SELECT MAX(orden_codigo_serie) as id FROM logistica.tb_ordenesmovilizacion WHERE (date_part('year',orden_registro)=date_part('year',CURRENT_DATE))");
    // $row = $database->single();
    // $database->closeConnection();
    // $id = ($row['id'] == null ? 0 : $row['id']) + 1;
    // CONSULTAR ULTIMA SERIE
    $database = new Database();
    $database->query("SELECT MAX(orden_serie) as serie FROM logistica.tb_ordenesmovilizacion WHERE (date_part('year',orden_registro)=date_part('year',CURRENT_DATE)) AND orden_codigo like '{$pref}{$year}{$project}{$origen}%' and orden_estado <> 'ORDEN ANULADA' ");
    $row_serie = $database->single();
    $database->closeConnection();
    $n_serie = ($row_serie['serie'] == null ? 0 : $row_serie['serie']) + 1;
    // FORMATEAR A 5 NÚMEROS
    $serie = str_pad($id, 5, "0", STR_PAD_LEFT);
    // GENERAR MODELO DE SERIE
    // $barcode = array(
    //     'barcode_serie' => $id,
    //     'barcode_proyecto' => $project,
    //     'barcode_proyecto_id' => $entityId
    // );


    // REGISTRAR CÓDIGO DE PROYECTOS
    // RETORNAR CÓDIGO DE PROYECTO GENERADO
    return array('orden_codigo_serie' => $id, 'code' => "{$pref}{$year}{$project}{$origen}{$serie}", 'serie' => $n_serie);
}
/*
* OBTENER SIGUIENTE ID DE ENTIDAD
*/
// function getNextId($tb)
// {
//     // PARÁMETROS DE ENTIDAD
//     $cfg = $this->getParams($tb);
//     // GENERAR QUERY
//     $cfg = $this->findOne($this->getSQLSelect($this->setCustomTable($tb, "MAX({$cfg['serial']}) id", $cfg['table_schema'])));
//     return ($cfg['id'] == null ? 0 : $cfg['id']) + 1;
// }
