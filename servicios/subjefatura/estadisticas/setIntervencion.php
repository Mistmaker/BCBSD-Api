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
    // $sqlDirAdmin = "select ppersonal_id,personal_id,persona_doc_identidad,persona_apellidos, persona_nombres, puesto_nombre, concat( persona_apellidos,' ',persona_nombres, ' ', puesto_nombre ) as nombre_completo from tthh.tb_personal p 
    // inner join tthh.tb_personal_puestos pp ON pp.fk_personal_id = p.personal_id inner join tthh.tb_puestos pu on pu.puesto_id = pp.fk_puesto_id
    // inner join resources.tb_personas pe on pe.persona_id = fk_persona_id WHERE ppersonal_estado ='EN FUNCIONES' and puesto_id=4 order by persona_apellidos, persona_nombres";

    // $database->query($sqlDirAdmin);
    // $database->bind('id', $id);
    // $dataDirAdmin = $database->single();
    // $request->director_administrativo = $dataDirAdmin["ppersonal_id"];

    if (!isset($request->intervencion_id)) {

        // VALIDAR ORDEN YA EXISTENTE
        // $sqlOrden = "SELECT orden_id, orden_kilometraje_salida, orden_kilometraje_entrada from logistica.tb_ordenesmovilizacion where fk_unidad_id = :fk_unidad_id and orden_estado = 'SALIDA' ORDER BY orden_id desc limit 1";
        // $database->query($sqlOrden);
        // $database->bind('fk_unidad_id', prop($request, 'fk_unidad_id'));
        // $orden = $database->single();
        // if ($orden) {
        //     jsonResponse(['error' => 'Error al guardar', 'msg' => "Ya existe una orden generada para la unidad seleccionada, no se puede emitir una nueva orden hasta que la misma retorne a la estación"], 500);
        // }

        // VALIDAR KILOMETRAJE
        // $sqlOrdenKm = "SELECT orden_id, orden_kilometraje_salida, orden_kilometraje_entrada from logistica.tb_ordenesmovilizacion where fk_unidad_id = :fk_unidad_id and orden_estado = 'ESTACION' ORDER BY orden_id desc limit 1";
        // $database->query($sqlOrdenKm);
        // $database->bind('fk_unidad_id', prop($request, 'fk_unidad_id'));
        // $dataKm = $database->single();

        // if ($dataKm) {
        //     if ($dataKm["orden_kilometraje_entrada"] <> $request->orden_kilometraje_salida) {
        //         jsonResponse(['error' => 'Error al guardar', 'msg' => "El kilometraje de salida {$request->orden_kilometraje_salida} no coincide con el último kilometraje de entrada {$dataKm["orden_kilometraje_entrada"]} de la unidad seleccionada"], 500);
        //     }
        // }

        // Obtener serie y codigo
        // $datosCodigo = nextCodeProject('');
        // print_r($datosCodigo);
        // $request->orden_codigo = $datosCodigo["code"];
        // $request->orden_codigo_serie = $datosCodigo["orden_codigo_serie"];
        // $request->orden_serie = $datosCodigo["serie"];

        // if ($request->orden_hora_salida_tipo == 'SISTEMA') {
        //     $request->orden_hora_salida = date("Y-m-d H:i:s");
        // }

        $database->query('INSERT INTO subjefatura.tb_intervenciones (
            fk_incidencia_id, fk_emergencia_id, fk_estacion_id, fk_causa_id, fk_naturaleza_id, fk_unidad_id, fk_personal_id, fk_parroquia_id, intervencion_fecha, intervencion_direccion, incidencia_beneficiarios, incidencia_fallecidos, intervencion_longitud, intervencion_latitud
        ) VALUES (
            :fk_incidencia_id, :fk_emergencia_id, :fk_estacion_id, :fk_causa_id, :fk_naturaleza_id, :fk_unidad_id, :fk_personal_id, :fk_parroquia_id, :intervencion_fecha, :intervencion_direccion, :incidencia_beneficiarios, :incidencia_fallecidos, :intervencion_longitud, :intervencion_latitud
        ) RETURNING intervencion_id
        ');

        // $database->bind(':intervencion_id', prop($request, 'intervencion_id'));
        $database->bind(':fk_incidencia_id', prop($request, 'fk_incidencia_id'));
        $database->bind(':fk_estacion_id', prop($request, 'fk_estacion_id'));
        $database->bind(':fk_emergencia_id', prop($request, 'fk_emergencia_id'));
        $database->bind(':fk_causa_id', prop($request, 'fk_causa_id'));
        $database->bind(':fk_naturaleza_id', prop($request, 'fk_naturaleza_id'));
        $database->bind(':fk_unidad_id', prop($request, 'fk_unidad_id'));
        $database->bind(':fk_personal_id', prop($request, 'fk_personal_id'));
        $database->bind(':fk_parroquia_id', prop($request, 'fk_parroquia_id'));
        $database->bind(':intervencion_latitud', prop($request, 'intervencion_latitud'));
        $database->bind(':intervencion_longitud', prop($request, 'intervencion_longitud'));
        // $database->bind(':intervencion_estado', prop($request, 'intervencion_estado'));
        // $database->bind(':intervencion_registro', prop($request, 'intervencion_registro'));
        $database->bind(':intervencion_fecha', prop($request, 'intervencion_fecha'));
        $database->bind(':intervencion_direccion', prop($request, 'intervencion_direccion'));
        $database->bind(':incidencia_beneficiarios', prop($request, 'incidencia_beneficiarios'));
        $database->bind(':incidencia_fallecidos', prop($request, 'incidencia_fallecidos'));

        $inserted = $database->single(); // ejecuta y devuelve resultado
        if (!$inserted) {
            jsonResponse(['error' => 'Error al insertar', 'msg' => $database->getErrors()[2]], 500);
        }
        $database->endTransaction();
        $database->closeConnection();
        jsonResponse(['msg' => 'Registro creado con exito', 'id' => $inserted['intervencion_id']], 201);
    } else {

        // if ($request->orden_hora_entrada_tipo == 'SISTEMA') {
        //     $request->orden_hora_entrada = date("Y-m-d H:i:s");
        // }

        $database->query(' UPDATE subjefatura.tb_intervenciones SET
            fk_incidencia_id = :fk_incidencia_id,
            fk_estacion_id = :fk_estacion_id,
            fk_emergencia_id = :fk_emergencia_id,
            fk_causa_id = :fk_causa_id,
            fk_naturaleza_id = :fk_naturaleza_id,
            fk_unidad_id = :fk_unidad_id,
            fk_personal_id = :fk_personal_id,
            intervencion_latitud = :intervencion_latitud,
            intervencion_longitud = :intervencion_longitud,
            intervencion_estado = :intervencion_estado,
            intervencion_registro = :intervencion_registro,
            intervencion_fecha = :intervencion_fecha,
            intervencion_direccion = :intervencion_direccion,
            incidencia_beneficiarios = :incidencia_beneficiarios,
            incidencia_fallecidos = :incidencia_fallecidos
        WHERE intervencion_id = :intervencion_id');

        $database->bind(':intervencion_id', prop($request, 'intervencion_id'));
        $database->bind(':fk_incidencia_id', prop($request, 'fk_incidencia_id'));
        $database->bind(':fk_estacion_id', prop($request, 'fk_estacion_id'));
        $database->bind(':fk_emergencia_id', prop($request, 'fk_emergencia_id'));
        $database->bind(':fk_causa_id', prop($request, 'fk_causa_id'));
        $database->bind(':fk_naturaleza_id', prop($request, 'fk_naturaleza_id'));
        $database->bind(':fk_unidad_id', prop($request, 'fk_unidad_id'));
        $database->bind(':fk_personal_id', prop($request, 'fk_personal_id'));
        $database->bind(':intervencion_latitud', prop($request, 'intervencion_latitud'));
        $database->bind(':intervencion_longitud', prop($request, 'intervencion_longitud'));
        $database->bind(':intervencion_estado', prop($request, 'intervencion_estado'));
        $database->bind(':intervencion_registro', prop($request, 'intervencion_registro'));
        $database->bind(':intervencion_fecha', prop($request, 'intervencion_fecha'));
        $database->bind(':intervencion_direccion', prop($request, 'intervencion_direccion'));
        $database->bind(':incidencia_beneficiarios', prop($request, 'incidencia_beneficiarios'));
        $database->bind(':incidencia_fallecidos', prop($request, 'incidencia_fallecidos'));

        $success = $database->execute();

        if (!$success) {
            jsonResponse(['error' => 'Error al actualizar', 'msg' => $database->getErrors()[2]], 500);
        }
        $database->endTransaction();
        $database->closeConnection();
        jsonResponse(['msg' => 'Registro actualizado con exito', 'id' => $request->intervencion_id], 200);
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
function nextCodeProject($entity)
{
    // DEFINIR PREFIJO DE SERIE
    $pref = "CBSD";
    // DEFINIR AÑO EN CURSO
    $year = date('y');
    // DEFINIR SIGUIENTE ID DE PROYECTO
    // $entityId = getNextId($entity);
    // OBTENER PREFIJO DE PROYECTO
    $project = 'MOV';
    // CONSULTAR ÚLTIMO ID DE CÓDIGO GENERADO DEL AÑO
    $database = new Database();
    $database->query("SELECT MAX(orden_codigo_serie) as id FROM logistica.tb_ordenesmovilizacion WHERE (date_part('year',orden_registro)=date_part('year',CURRENT_DATE))");
    $row = $database->single();
    $database->closeConnection();
    $id = ($row['id'] == null ? 0 : $row['id']) + 1;
    // CONSULTAR ULTIMA SERIE
    $database = new Database();
    $database->query("SELECT MAX(orden_serie) as serie FROM logistica.tb_ordenesmovilizacion WHERE (date_part('year',orden_registro)=date_part('year',CURRENT_DATE)) AND orden_estado <> 'ORDEN ANULADA' ");
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
    return array('orden_codigo_serie' => $id, 'code' => "{$pref}{$year}{$project}{$serie}", 'serie' => $n_serie);
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
