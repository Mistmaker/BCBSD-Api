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

$entity = 'tb_aph_hojaruta_tipoemergencia';

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

    if (!isset($request->aph_hojaruta_id)) {

        $database->query('INSERT INTO subjefatura.tb_aph_hojaruta (fk_responsable_atencion,fk_tipo_emergencia,fk_estacion_id,fk_parroquia_id,aph_hojaruta_codigo,aph_hojaruta_codigo002,aph_hojaruta_fecha,aph_hojaruta_direccion,aph_hojaruta_hora_salida_estacion,aph_hojaruta_hora_retorno_estacion) 
        VALUES (:fk_responsable_atencion,:fk_tipo_emergencia,:fk_estacion_id,:fk_parroquia_id,:aph_hojaruta_codigo,:aph_hojaruta_codigo002,:aph_hojaruta_fecha,:aph_hojaruta_direccion,:aph_hojaruta_hora_salida_estacion,:aph_hojaruta_hora_retorno_estacion) 
        RETURNING aph_hojaruta_id
        ');


        // $database->bind(':intervencion_id', prop($request, 'intervencion_id'));
        $database->bind(':fk_responsable_atencion', prop($request, 'fk_responsable_atencion'));
        $database->bind(':fk_tipo_emergencia', prop($request, 'fk_estacion_id'));
        $database->bind(':fk_estacion_id', prop($request, 'fk_estacion_id'));
        $database->bind(':fk_parroquia_id', prop($request, 'fk_parroquia_id'));
        $database->bind(':aph_hojaruta_codigo', prop($request, 'aph_hojaruta_codigo'));
        $database->bind(':aph_hojaruta_codigo002', prop($request, 'aph_hojaruta_codigo002'));
        $database->bind(':aph_hojaruta_fecha', prop($request, 'aph_hojaruta_fecha'));
        $database->bind(':aph_hojaruta_direccion', prop($request, 'aph_hojaruta_direccion'));
        $database->bind(':aph_hojaruta_hora_salida_estacion', prop($request, 'aph_hojaruta_hora_salida_estacion'));
        $database->bind(':aph_hojaruta_hora_retorno_estacion', prop($request, 'aph_hojaruta_hora_retorno_estacion'));

        $inserted = $database->single(); // ejecuta y devuelve resultado
        if (!$inserted) {
            jsonResponse(['error' => 'Error al insertar', 'msg' => $database->getErrors()[2]], 500);
        }
        $database->endTransaction();
        $database->closeConnection();
        jsonResponse(['msg' => 'Registro creado con exito', 'id' => $inserted['aph_hojaruta_id']], 201);
    } else {

        // if ($request->orden_hora_entrada_tipo == 'SISTEMA') {
        //     $request->orden_hora_entrada = date("Y-m-d H:i:s");
        // }

        $database->query(' UPDATE subjefatura.tb_aph_hojaruta SET 
        fk_responsable_atencion = :fk_responsable_atencion, 
        fk_tipo_emergencia = :fk_tipo_emergencia,
        fk_estacion_id = :fk_estacion_id,
        fk_parroquia_id = :fk_parroquia_id,
        aph_hojaruta_codigo002 = :aph_hojaruta_codigo002,
        aph_hojaruta_fecha = :aph_hojaruta_fecha,
        aph_hojaruta_direccion = :aph_hojaruta_direccion,
        aph_hojaruta_hora_salida_estacion = :aph_hojaruta_hora_salida_estacion,
        aph_hojaruta_hora_retorno_estacion = :aph_hojaruta_hora_retorno_estacion
        WHERE aph_hojaruta_id = :aph_hojaruta_id');

        $database->bind(':aph_hojaruta_id', prop($request, 'aph_hojaruta_id'));
        $database->bind(':fk_responsable_atencion', prop($request, 'fk_responsable_atencion'));
        $database->bind(':fk_tipo_emergencia', prop($request, 'fk_estacion_id'));
        $database->bind(':fk_estacion_id', prop($request, 'fk_estacion_id'));
        $database->bind(':fk_parroquia_id', prop($request, 'fk_parroquia_id'));
        $database->bind(':aph_hojaruta_codigo002', prop($request, 'aph_hojaruta_codigo002'));
        $database->bind(':aph_hojaruta_fecha', prop($request, 'aph_hojaruta_fecha'));
        $database->bind(':aph_hojaruta_direccion', prop($request, 'aph_hojaruta_direccion'));
        $database->bind(':aph_hojaruta_hora_salida_estacion', prop($request, 'aph_hojaruta_hora_salida_estacion'));
        $database->bind(':aph_hojaruta_hora_retorno_estacion', prop($request, 'aph_hojaruta_hora_retorno_estacion'));

        $success = $database->execute();

        /*
        */
        // ELIMINAR PACIENTES Y VOLVERLOS A REGISTRAR
        $database->query('DELETE FROM subjefatura.tb_aph_hojaruta_pacientes WHERE fk_aph_hojaruta_id = :aph_hojaruta_id');
        $database->bind(':aph_hojaruta_id', prop($request, 'aph_hojaruta_id'));
        $database->execute();

        if (isset($request->pacientes) && is_array($request->pacientes)) {
            foreach ($request->pacientes as $paciente) {
                $database->query('INSERT INTO subjefatura.tb_aph_hojaruta_pacientes (fk_aph_hojaruta_id,fk_cie10,aph_hojaruta_paciente_cedula,aph_hojaruta_paciente_nombres,aph_hojaruta_paciente_apellidos,aph_hojaruta_paciente_edad,aph_hojaruta_paciente_sexo,aph_hojaruta_paciente_condicion_inicial,aph_hojaruta_paciente_condicion_final,aph_hojaruta_paciente_diagnostico_preliminar,aph_hojaruta_paciente_destino) 
                VALUES (:fk_aph_hojaruta_id,:fk_cie10,:aph_hojaruta_paciente_cedula,:aph_hojaruta_paciente_nombres,:aph_hojaruta_paciente_apellidos,:aph_hojaruta_paciente_edad,:aph_hojaruta_paciente_sexo,:aph_hojaruta_paciente_condicion_inicial,:aph_hojaruta_paciente_condicion_final,:aph_hojaruta_paciente_diagnostico_preliminar,:aph_hojaruta_paciente_destino)');
                $database->bind(':fk_aph_hojaruta_id', prop($request, 'aph_hojaruta_id'));
                $database->bind(':fk_cie10', prop($paciente, 'fk_cie10'));
                $database->bind(':aph_hojaruta_paciente_cedula', prop($paciente, 'aph_hojaruta_paciente_cedula'));
                $database->bind(':aph_hojaruta_paciente_nombres', prop($paciente, 'aph_hojaruta_paciente_nombres'));
                $database->bind(':aph_hojaruta_paciente_apellidos', prop($paciente, 'aph_hojaruta_paciente_apellidos'));
                $database->bind(':aph_hojaruta_paciente_edad', prop($paciente, 'aph_hojaruta_paciente_edad'));
                $database->bind(':aph_hojaruta_paciente_sexo', prop($paciente, 'aph_hojaruta_paciente_sexo'));
                $database->bind(':aph_hojaruta_paciente_condicion_inicial', prop($paciente, 'aph_hojaruta_paciente_condicion_inicial'));
                $database->bind(':aph_hojaruta_paciente_condicion_final', prop($paciente, 'aph_hojaruta_paciente_condicion_final'));
                $database->bind(':aph_hojaruta_paciente_diagnostico_preliminar', prop($paciente, 'aph_hojaruta_paciente_diagnostico_preliminar'));
                $database->bind(':aph_hojaruta_paciente_destino', prop($paciente, 'aph_hojaruta_paciente_destino'));
                $database->execute();
            }
        }

        // ELIMINAR VEHICULOS Y VOLVERLOS A CREAR
        $database->query('DELETE FROM subjefatura.tb_aph_hojaruta_vehiculos WHERE fk_aph_hojaruta_id = :aph_hojaruta_id');
        $database->bind(':aph_hojaruta_id', prop($request, 'aph_hojaruta_id'));
        $database->execute();

        if (isset($request->vehiculos) && is_array($request->vehiculos)) {
            foreach ($request->vehiculos as $vehiculo) {
                $database->query('INSERT INTO subjefatura.tb_aph_hojaruta_vehiculos (fk_aph_hojaruta_id,fk_vehiculo,fk_operador,aph_hojaruta_vehiculo_kilometraje_salida,aph_hojaruta_vehiculo_kilometraje_retorno,aph_hojaruta_vehiculo_hora_salida,aph_hojaruta_vehiculo_hora_arribo,aph_hojaruta_vehiculo_hora_retorno) 
                VALUES (:fk_aph_hojaruta_id,:fk_vehiculo,:fk_operador,:aph_hojaruta_vehiculo_kilometraje_salida,:aph_hojaruta_vehiculo_kilometraje_retorno,:aph_hojaruta_vehiculo_hora_salida,:aph_hojaruta_vehiculo_hora_arribo,:aph_hojaruta_vehiculo_hora_retorno)');
                $database->bind(':fk_aph_hojaruta_id', prop($request, 'aph_hojaruta_id'));
                $database->bind(':fk_vehiculo', prop($vehiculo, 'fk_vehiculo'));
                $database->bind(':fk_operador', prop($vehiculo, 'fk_operador'));
                $database->bind(':aph_hojaruta_vehiculo_kilometraje_salida', prop($vehiculo, 'aph_hojaruta_vehiculo_kilometraje_salida'));
                $database->bind(':aph_hojaruta_vehiculo_kilometraje_retorno', prop($vehiculo, 'aph_hojaruta_vehiculo_kilometraje_retorno'));
                $database->bind(':aph_hojaruta_vehiculo_hora_salida', prop($vehiculo, 'aph_hojaruta_vehiculo_hora_salida'));
                $database->bind(':aph_hojaruta_vehiculo_hora_arribo', prop($vehiculo, 'aph_hojaruta_vehiculo_hora_arribo'));
                $database->bind(':aph_hojaruta_vehiculo_hora_retorno', prop($vehiculo, 'aph_hojaruta_vehiculo_hora_retorno'));
                $database->execute();
            }
        }




        if (!$success) {
            jsonResponse(['error' => 'Error al actualizar', 'msg' => $database->getErrors()[2]], 500);
        }
        $database->endTransaction();
        $database->closeConnection();
        jsonResponse(['msg' => 'Registro actualizado con exito', 'id' => $request->aph_hojaruta_id], 200);
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
