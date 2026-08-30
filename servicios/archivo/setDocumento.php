<?php
// error_reporting(E_ALL);
// ini_set('display_errors', 1);
// DB configuration
include_once("../../classes/dbconfig.php");
include_once '../../classes/database.class.php';

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

    if (!isset($request->distributivo_id)) {

        $database->query('INSERT INTO archivo.documentos (
            documento_direccion_origen_id,
            documento_direccion_destino_id,
            documento_tipo_documento_id,
            documento_numero_documento,
            documento_numero_folio,
            documento_fecha_documento,
            documento_remitente,
            documento_destinatario,
            documento_asunto,
            documento_archivo_escaneado,
            documento_ubicacion_fisica,
            documento_anio
        ) VALUES (
            :documento_direccion_origen_id,
            :documento_direccion_destino_id,
            :documento_tipo_documento_id,
            :documento_numero_documento,
            :documento_numero_folio,
            :documento_fecha_documento,
            :documento_remitente,
            :documento_destinatario,
            :documento_asunto,
            :documento_archivo_escaneado,
            :documento_ubicacion_fisica,
            :documento_anio
        ) RETURNING documento_id');

        $request->documento_archivo_escaneado = 'tmp.agregar';
        $request->documento_anio = date('Y', strtotime($request->documento_fecha_documento));

        $database->bind(':documento_direccion_origen_id', prop($request, 'documento_direccion_origen_id'));
        $database->bind(':documento_direccion_destino_id', prop($request, 'documento_direccion_destino_id'));
        $database->bind(':documento_tipo_documento_id', prop($request, 'documento_tipo_documento_id'));
        $database->bind(':documento_numero_documento', prop($request, 'documento_numero_documento'));
        $database->bind(':documento_numero_folio', prop($request, 'documento_numero_folio'));
        $database->bind(':documento_fecha_documento', prop($request, 'documento_fecha_documento'));
        $database->bind(':documento_remitente', prop($request, 'documento_remitente'));
        $database->bind(':documento_destinatario', prop($request, 'documento_destinatario'));
        $database->bind(':documento_asunto', prop($request, 'documento_asunto'));
        $database->bind(':documento_archivo_escaneado', prop($request, 'documento_archivo_escaneado'));
        $database->bind(':documento_ubicacion_fisica', prop($request, 'documento_ubicacion_fisica'));
        $database->bind(':documento_anio', prop($request, 'documento_anio'));
        $inserted = $database->single(); // ejecuta y devuelve resultado
        if (!$inserted) {
            jsonResponse(['error' => 'Error al insertar', 'msg' => $database->getErrors()[2]], 500);
        }

        $database->endTransaction();
        $database->closeConnection();
        jsonResponse(['msg' => 'Registro creado con exito', 'id' => $inserted['documento_id']], 201);
    } else {

        $database->query('UPDATE archivo.documentos SET
            documento_direccion_origen_id = :documento_direccion_origen_id,
            documento_direccion_destino_id = :documento_direccion_destino_id,
            documento_tipo_documento_id = :documento_tipo_documento_id,
            documento_numero_documento = :documento_numero_documento,
            documento_numero_folio = :documento_numero_folio,
            documento_fecha_documento = :documento_fecha_documento,
            documento_remitente = :documento_remitente,
            documento_destinatario = :documento_destinatario,
            documento_asunto = :documento_asunto,
            documento_archivo_escaneado = :documento_archivo_escaneado,
            documento_ubicacion_fisica = :documento_ubicacion_fisica,
            documento_anio = :documento_anio
        WHERE documento_id = :documento_id');

        $request->documento_archivo_escaneado = 'tmp.agregar';
        $request->documento_anio = date('Y', strtotime($request->documento_fecha_documento));

        $database->bind(':documento_id', prop($request, 'documento_id'));
        $database->bind(':documento_direccion_origen_id', prop($request, 'documento_direccion_origen_id'));
        $database->bind(':documento_direccion_destino_id', prop($request, 'documento_direccion_destino_id'));
        $database->bind(':documento_tipo_documento_id', prop($request, 'documento_tipo_documento_id'));
        $database->bind(':documento_numero_documento', prop($request, 'documento_numero_documento'));
        $database->bind(':documento_numero_folio', prop($request, 'documento_numero_folio'));
        $database->bind(':documento_fecha_documento', prop($request, 'documento_fecha_documento'));
        $database->bind(':documento_remitente', prop($request, 'documento_remitente'));
        $database->bind(':documento_destinatario', prop($request, 'documento_destinatario'));
        $database->bind(':documento_asunto', prop($request, 'documento_asunto'));
        $database->bind(':documento_archivo_escaneado', prop($request, 'documento_archivo_escaneado'));
        $database->bind(':documento_ubicacion_fisica', prop($request, 'documento_ubicacion_fisica'));
        $database->bind(':documento_anio', prop($request, 'documento_anio'));

        $success = $database->execute();

        if (!$success) {
            jsonResponse(['error' => 'Error al actualizar', 'msg' => $database->getErrors()[2]], 500);
        }
        $database->endTransaction();
        $database->closeConnection();
        jsonResponse(['msg' => 'Registro actualizado con exito', 'id' => $request->documento_id], 200);
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
