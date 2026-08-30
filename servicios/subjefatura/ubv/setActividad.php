<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);
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

$entity = 'tb_voluntarios_actividades';

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

    // Manejo de voluntarios
    if (!isset($request->actividad_id)) {
        // Insertar un nuevo voluntario
        $database->query('INSERT INTO subjefatura.tb_voluntarios_actividades (
            fk_voluntario_id,
            actividad_actividad,
            actividad_descripcion,
            actividad_fecha_inicio,
            actividad_fecha_finalizacion,
            actividad_evidencia,
            fk_ppersonal_id
        ) VALUES (
            :fk_voluntario_id,
            :actividad_actividad,
            :actividad_descripcion,
            :actividad_fecha_inicio,
            :actividad_fecha_finalizacion,
            :actividad_evidencia,
            :fk_ppersonal_id
        ) RETURNING actividad_id');

        $database->bind(':fk_voluntario_id', prop($request, 'fk_voluntario_id'));
        $database->bind(':actividad_actividad', prop($request, 'actividad_actividad'));
        $database->bind(':actividad_descripcion', prop($request, 'actividad_descripcion'));
        $database->bind(':actividad_fecha_inicio', prop($request, 'actividad_fecha_inicio'));
        $database->bind(':actividad_fecha_finalizacion', prop($request, 'actividad_fecha_finalizacion'));
        $database->bind(':actividad_evidencia', prop($request, 'actividad_evidencia'));
        $database->bind(':fk_ppersonal_id', prop($request, 'fk_ppersonal_id'));

        $inserted = $database->single();
        if (!$inserted) {
            jsonResponse(['error' => 'Error al insertar actividad', 'msg' => $database->getErrors()[2]], 500);
        }
        $database->endTransaction();
        $database->closeConnection();
        jsonResponse(['msg' => 'Actividad registrada con éxito', 'id' => $inserted['actividad_id']], 201);
    } else {
        // Actualizar un voluntario existente
        $database->query('UPDATE subjefatura.tb_voluntarios_actividades SET
            actividad_actividad = :actividad_actividad,
            actividad_descripcion = :actividad_descripcion,
            actividad_fecha_inicio = :actividad_fecha_inicio,
            actividad_fecha_finalizacion = :actividad_fecha_finalizacion,
            actividad_evidencia = :actividad_evidencia,
            actividad_estado = :actividad_estado,
            fk_ppersonal_id = :fk_ppersonal_id
        WHERE actividad_id = :actividad_id');

        $database->bind(':actividad_id', prop($request, 'actividad_id'));
        $database->bind(':actividad_actividad', prop($request, 'actividad_actividad'));
        $database->bind(':actividad_descripcion', prop($request, 'actividad_descripcion'));
        $database->bind(':actividad_fecha_inicio', prop($request, 'actividad_fecha_inicio'));
        $database->bind(':actividad_fecha_finalizacion', prop($request, 'actividad_fecha_finalizacion'));
        $database->bind(':actividad_evidencia', prop($request, 'actividad_evidencia'));
        $database->bind(':actividad_estado', prop($request, 'actividad_estado'));
        $database->bind(':fk_ppersonal_id', prop($request, 'fk_ppersonal_id'));

        $success = $database->execute();
        if (!$success) {
            jsonResponse(['error' => 'Error al actualizar actividad', 'msg' => $database->getErrors()[2]], 500);
        }
        $database->endTransaction();
        $database->closeConnection();
        jsonResponse(['msg' => 'Actividad actualizada con éxito', 'id' => $request->actividad_id], 200);
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
