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

    // Manejo de voluntarios
    if (!isset($request->voluntario_id)) {
        // Insertar un nuevo voluntario
        $database->query('INSERT INTO subjefatura.tb_voluntarios (voluntario_tipo_doc,voluntario_doc_identidad,voluntario_nombres,voluntario_apellidos,voluntario_sexo,voluntario_imagen,voluntario_direccion,voluntario_telefono,voluntario_correo,voluntario_fnacimiento,voluntario_nacionalidad,voluntario_celular,voluntario_estadocivil,voluntario_tiposangre,voluntario_pass,fk_parroquia_id,voluntario_principal,voluntario_secundaria,voluntario_no_casa,voluntario_referencia,voluntario_barrio_ciudadela,voluntario_barrio_sector,voluntario_titulo,voluntario_anexo_cedula,voluntario_cemergencia_nombre,voluntario_cemergencia_parentesco,voluntario_cemergencia_direccion,voluntario_cemergencia_telefono,voluntario_discapacidad_tiene,voluntario_discapacidad_tipo,voluntario_discapacidad_porcentaje,voluntario_discapacidad_conadis,voluntario_discapacidad_conadis_numero,voluntario_enfermedad_cronica,voluntario_enfermedad_cronica_describa
        ) VALUES (
            :voluntario_tipo_doc,:voluntario_doc_identidad,:voluntario_nombres,:voluntario_apellidos,:voluntario_sexo,:voluntario_imagen,:voluntario_direccion,:voluntario_telefono,:voluntario_correo,:voluntario_fnacimiento,:voluntario_nacionalidad,:voluntario_celular,:voluntario_estadocivil,:voluntario_tiposangre,:voluntario_pass,:fk_parroquia_id,:voluntario_principal,:voluntario_secundaria,:voluntario_no_casa,:voluntario_referencia,:voluntario_barrio_ciudadela,:voluntario_barrio_sector,:voluntario_titulo,:voluntario_anexo_cedula,:voluntario_cemergencia_nombre,:voluntario_cemergencia_parentesco,:voluntario_cemergencia_direccion,:voluntario_cemergencia_telefono,:voluntario_discapacidad_tiene,:voluntario_discapacidad_tipo,:voluntario_discapacidad_porcentaje,:voluntario_discapacidad_conadis,:voluntario_discapacidad_conadis_numero,:voluntario_enfermedad_cronica,:voluntario_enfermedad_cronica_describa
        ) RETURNING voluntario_id');

        $database->bind(':voluntario_tipo_doc', prop($request, 'voluntario_tipo_doc', 'CEDULA'));
        $database->bind(':voluntario_doc_identidad', prop($request, 'voluntario_doc_identidad'));
        $database->bind(':voluntario_nombres', prop($request, 'voluntario_nombres'));
        $database->bind(':voluntario_apellidos', prop($request, 'voluntario_apellidos'));
        $database->bind(':voluntario_sexo', prop($request, 'voluntario_sexo'));
        $database->bind(':voluntario_imagen', prop($request, 'voluntario_imagen', 'default.png'));
        $database->bind(':voluntario_direccion', prop($request, 'voluntario_direccion'));
        $database->bind(':voluntario_telefono', prop($request, 'voluntario_telefono'));
        $database->bind(':voluntario_correo', prop($request, 'voluntario_correo'));
        $database->bind(':voluntario_fnacimiento', prop($request, 'voluntario_fnacimiento'));
        $database->bind(':voluntario_nacionalidad', prop($request, 'voluntario_nacionalidad', 'ECUATORIANA'));
        $database->bind(':voluntario_celular', prop($request, 'voluntario_celular'));
        $database->bind(':voluntario_estadocivil', prop($request, 'voluntario_estadocivil'));
        $database->bind(':voluntario_tiposangre', prop($request, 'voluntario_tiposangre'));
        $database->bind(':voluntario_pass', md5(prop($request, 'voluntario_doc_identidad')));
        $database->bind(':fk_parroquia_id', prop($request, 'fk_parroquia_id', 230151));
        $database->bind(':voluntario_principal', prop($request, 'voluntario_principal'));
        $database->bind(':voluntario_secundaria', prop($request, 'voluntario_secundaria'));
        $database->bind(':voluntario_no_casa', prop($request, 'voluntario_no_casa'));
        $database->bind(':voluntario_referencia', prop($request, 'voluntario_referencia'));
        $database->bind(':voluntario_barrio_ciudadela', prop($request, 'voluntario_barrio_ciudadela'));
        $database->bind(':voluntario_barrio_sector', prop($request, 'voluntario_barrio_sector'));
        $database->bind(':voluntario_titulo', prop($request, 'voluntario_titulo'));
        $database->bind(':voluntario_anexo_cedula', prop($request, 'voluntario_anexo_cedula', 'NO'));
        $database->bind(':voluntario_cemergencia_nombre', prop($request, 'voluntario_cemergencia_nombre'));
        $database->bind(':voluntario_cemergencia_parentesco', prop($request, 'voluntario_cemergencia_parentesco'));
        $database->bind(':voluntario_cemergencia_direccion', prop($request, 'voluntario_cemergencia_direccion'));
        $database->bind(':voluntario_cemergencia_telefono', prop($request, 'voluntario_cemergencia_telefono'));
        $database->bind(':voluntario_discapacidad_tiene', prop($request, 'voluntario_discapacidad_tiene', 'NO'));
        $database->bind(':voluntario_discapacidad_tipo', prop($request, 'voluntario_discapacidad_tipo'));
        $database->bind(':voluntario_discapacidad_porcentaje', prop($request, 'voluntario_discapacidad_porcentaje'));
        $database->bind(':voluntario_discapacidad_conadis', prop($request, 'voluntario_discapacidad_conadis', 'NO'));
        $database->bind(':voluntario_discapacidad_conadis_numero', prop($request, 'voluntario_discapacidad_conadis_numero'));
        $database->bind(':voluntario_enfermedad_cronica', prop($request, 'voluntario_enfermedad_cronica', 'NO'));
        $database->bind(':voluntario_enfermedad_cronica_describa', prop($request, 'voluntario_enfermedad_cronica_describa'));

        $inserted = $database->single();
        if (!$inserted) {
            jsonResponse(['error' => 'Error al insertar voluntario', 'msg' => $database->getErrors()[2]], 500);
        }
        $database->endTransaction();
        $database->closeConnection();
        jsonResponse(['msg' => 'Voluntario creado con éxito', 'id' => $inserted['voluntario_id']], 201);
    } else {
        // Actualizar un voluntario existente
        $database->query('UPDATE subjefatura.tb_voluntarios SET
            voluntario_tipo_doc = :voluntario_tipo_doc, voluntario_estado = :voluntario_estado,voluntario_doc_identidad = :voluntario_doc_identidad,voluntario_nombres = :voluntario_nombres,voluntario_apellidos = :voluntario_apellidos,voluntario_sexo = :voluntario_sexo,voluntario_imagen = :voluntario_imagen,voluntario_direccion = :voluntario_direccion,voluntario_telefono = :voluntario_telefono,voluntario_correo = :voluntario_correo,voluntario_fnacimiento = :voluntario_fnacimiento,voluntario_nacionalidad = :voluntario_nacionalidad,voluntario_celular = :voluntario_celular,voluntario_estadocivil = :voluntario_estadocivil,voluntario_tiposangre = :voluntario_tiposangre,fk_parroquia_id = :fk_parroquia_id,voluntario_principal = :voluntario_principal,voluntario_secundaria = :voluntario_secundaria,voluntario_no_casa = :voluntario_no_casa,voluntario_referencia = :voluntario_referencia,voluntario_barrio_ciudadela = :voluntario_barrio_ciudadela,voluntario_barrio_sector = :voluntario_barrio_sector,voluntario_titulo = :voluntario_titulo,voluntario_anexo_cedula = :voluntario_anexo_cedula,voluntario_cemergencia_nombre = :voluntario_cemergencia_nombre,voluntario_cemergencia_parentesco = :voluntario_cemergencia_parentesco,voluntario_cemergencia_direccion = :voluntario_cemergencia_direccion,voluntario_cemergencia_telefono = :voluntario_cemergencia_telefono,voluntario_discapacidad_tiene = :voluntario_discapacidad_tiene,voluntario_discapacidad_tipo = :voluntario_discapacidad_tipo,voluntario_discapacidad_porcentaje = :voluntario_discapacidad_porcentaje,voluntario_discapacidad_conadis = :voluntario_discapacidad_conadis,voluntario_discapacidad_conadis_numero = :voluntario_discapacidad_conadis_numero,voluntario_enfermedad_cronica = :voluntario_enfermedad_cronica,voluntario_enfermedad_cronica_describa = :voluntario_enfermedad_cronica_describa
        WHERE voluntario_id = :voluntario_id');

        $database->bind(':voluntario_id', prop($request, 'voluntario_id'));
        $database->bind(':voluntario_tipo_doc', prop($request, 'voluntario_tipo_doc', 'CEDULA'));
        $database->bind(':voluntario_estado', prop($request, 'voluntario_estado'));
        $database->bind(':voluntario_doc_identidad', prop($request, 'voluntario_doc_identidad'));
        $database->bind(':voluntario_nombres', prop($request, 'voluntario_nombres'));
        $database->bind(':voluntario_apellidos', prop($request, 'voluntario_apellidos'));
        $database->bind(':voluntario_sexo', prop($request, 'voluntario_sexo'));
        $database->bind(':voluntario_imagen', prop($request, 'voluntario_imagen', 'default.png'));
        $database->bind(':voluntario_direccion', prop($request, 'voluntario_direccion'));
        $database->bind(':voluntario_telefono', prop($request, 'voluntario_telefono'));
        $database->bind(':voluntario_correo', prop($request, 'voluntario_correo'));
        $database->bind(':voluntario_fnacimiento', prop($request, 'voluntario_fnacimiento'));
        $database->bind(':voluntario_nacionalidad', prop($request, 'voluntario_nacionalidad', 'ECUATORIANA'));
        $database->bind(':voluntario_celular', prop($request, 'voluntario_celular'));
        $database->bind(':voluntario_estadocivil', prop($request, 'voluntario_estadocivil'));
        $database->bind(':voluntario_tiposangre', prop($request, 'voluntario_tiposangre'));
        $database->bind(':fk_parroquia_id', prop($request, 'fk_parroquia_id', 230151));
        $database->bind(':voluntario_principal', prop($request, 'voluntario_principal'));
        $database->bind(':voluntario_secundaria', prop($request, 'voluntario_secundaria'));
        $database->bind(':voluntario_no_casa', prop($request, 'voluntario_no_casa'));
        $database->bind(':voluntario_referencia', prop($request, 'voluntario_referencia'));
        $database->bind(':voluntario_barrio_ciudadela', prop($request, 'voluntario_barrio_ciudadela'));
        $database->bind(':voluntario_barrio_sector', prop($request, 'voluntario_barrio_sector'));
        $database->bind(':voluntario_titulo', prop($request, 'voluntario_titulo'));
        $database->bind(':voluntario_anexo_cedula', prop($request, 'voluntario_anexo_cedula', 'NO'));
        $database->bind(':voluntario_cemergencia_nombre', prop($request, 'voluntario_cemergencia_nombre'));
        $database->bind(':voluntario_cemergencia_parentesco', prop($request, 'voluntario_cemergencia_parentesco'));
        $database->bind(':voluntario_cemergencia_direccion', prop($request, 'voluntario_cemergencia_direccion'));
        $database->bind(':voluntario_cemergencia_telefono', prop($request, 'voluntario_cemergencia_telefono'));
        $database->bind(':voluntario_discapacidad_tiene', prop($request, 'voluntario_discapacidad_tiene', 'NO'));
        $database->bind(':voluntario_discapacidad_tipo', prop($request, 'voluntario_discapacidad_tipo'));
        $database->bind(':voluntario_discapacidad_porcentaje', prop($request, 'voluntario_discapacidad_porcentaje'));
        $database->bind(':voluntario_discapacidad_conadis', prop($request, 'voluntario_discapacidad_conadis', 'NO'));
        $database->bind(':voluntario_discapacidad_conadis_numero', prop($request, 'voluntario_discapacidad_conadis_numero'));
        $database->bind(':voluntario_enfermedad_cronica', prop($request, 'voluntario_enfermedad_cronica', 'NO'));
        $database->bind(':voluntario_enfermedad_cronica_describa', prop($request, 'voluntario_enfermedad_cronica_describa'));

        $success = $database->execute();
        if (!$success) {
            jsonResponse(['error' => 'Error al actualizar voluntario', 'msg' => $database->getErrors()[2]], 500);
        }
        $database->endTransaction();
        $database->closeConnection();
        jsonResponse(['msg' => 'Voluntario actualizado con éxito', 'id' => $request->voluntario_id], 200);
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
