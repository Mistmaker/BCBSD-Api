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

    // VALIDAR QUE NO SER REPITAN, VOLUNTARIO, FECHA Y ESTACION
    $sqlValidacion = "SELECT asignacion_id from subjefatura.tb_voluntarios_asignacion where fk_voluntario_id = :fk_voluntario_id AND fk_estacion_id = :fk_estacion_id and asignacion_fecha_inicio = :asignacion_fecha_inicio ORDER BY asignacion_id desc limit 1";
    $database->query($sqlValidacion);
    $database->bind(':fk_voluntario_id', prop($request, 'fk_voluntario_id'));
    $database->bind(':fk_estacion_id', prop($request, 'fk_estacion_id'));
    $database->bind(':asignacion_fecha_inicio', prop($request, 'asignacion_fecha_inicio'));
    $asignacion = $database->single();
    if ($asignacion) {
        jsonResponse(['error' => '<b>¡Asignacion duplicada!</b>', 'msg' => "Ya existe una asignacion en esta fecha para el voluntario asignado, intente con otra fecha o estación"], 500);
    }

    // Manejo de asignaciones
    if (!isset($request->asignacion_id)) {

        // Insertar una nueva asignación
        $database->query('INSERT INTO subjefatura.tb_voluntarios_asignacion (
            fk_voluntario_id,
            fk_estacion_id,
            fk_unidad_id,
            asignacion_fecha_inicio,
            asignacion_fecha_fin
        ) VALUES (
            :fk_voluntario_id,
            :fk_estacion_id,
            :fk_unidad_id,
            :asignacion_fecha_inicio,
            :asignacion_fecha_fin
        ) RETURNING asignacion_id');

        $database->bind(':fk_voluntario_id', prop($request, 'fk_voluntario_id'));
        $database->bind(':fk_estacion_id', prop($request, 'fk_estacion_id'));
        $database->bind(':fk_unidad_id', prop($request, 'fk_unidad_id'));
        $database->bind(':asignacion_fecha_inicio', prop($request, 'asignacion_fecha_inicio'));
        $database->bind(':asignacion_fecha_fin', prop($request, 'asignacion_fecha_fin'));

        $inserted = $database->single();
        if (!$inserted) {
            jsonResponse(['error' => 'Error al insertar asignación', 'msg' => $database->getErrors()[2]], 500);
        }
        $database->endTransaction();
        $database->closeConnection();
        jsonResponse(['msg' => 'Asignación creada con éxito', 'asignacion_id' => $inserted['asignacion_id']], 201);
    } else {
        // Actualizar una asignación existente
        $database->query('UPDATE subjefatura.tb_voluntarios_asignacion SET
            fk_voluntario_id = :fk_voluntario_id,
            fk_estacion_id = :fk_estacion_id,
            fk_unidad_id = :fk_unidad_id,
            asignacion_fecha_inicio = :asignacion_fecha_inicio,
            asignacion_fecha_fin = :asignacion_fecha_fin
        WHERE asignacion_id = :asignacion_id');

        $database->bind(':asignacion_id', prop($request, 'asignacion_id'));
        $database->bind(':fk_voluntario_id', prop($request, 'fk_voluntario_id'));
        $database->bind(':fk_estacion_id', prop($request, 'fk_estacion_id'));
        $database->bind(':fk_unidad_id', prop($request, 'fk_unidad_id'));
        $database->bind(':asignacion_fecha_inicio', prop($request, 'asignacion_fecha_inicio'));
        $database->bind(':asignacion_fecha_fin', prop($request, 'asignacion_fecha_fin'));

        $success = $database->execute();
        if (!$success) {
            jsonResponse(['error' => 'Error al actualizar asignación', 'msg' => $database->getErrors()[2]], 500);
        }
        $database->endTransaction();
        $database->closeConnection();
        jsonResponse(['msg' => 'Asignación actualizada con éxito', 'asignacion_id' => $request->asignacion_id], 200);
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
