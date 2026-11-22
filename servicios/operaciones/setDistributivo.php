<?php
require_once __DIR__ . '/../../classes/auth.php';
$auth = requireAuth();
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

        $database->query('INSERT INTO operaciones.tb_distributivo (
                fk_usuario_id,
                distributivo_codigo,
                distributivo_periodo_inicio
            ) VALUES (
                :fk_usuario_id,
                :distributivo_codigo,
                :distributivo_periodo_inicio
            ) RETURNING distributivo_id
        ');

        $database->bind(':fk_usuario_id', authUsuarioId() ?? prop($request, 'fk_usuario_id'));
        $database->bind(':distributivo_codigo', prop($request, 'distributivo_codigo'));
        $database->bind(':distributivo_periodo_inicio', prop($request, 'distributivo_periodo_inicio'));
        $inserted = $database->single(); // ejecuta y devuelve resultado
        if (!$inserted) {
            jsonResponse(['error' => 'Error al insertar', 'msg' => $database->getErrors()[2]], 500);
        }


        // Obtener todos los pelotones activos
        $database->query("SELECT peloton_id FROM operaciones.tb_pelotones WHERE peloton_estado = 'ACTIVO'");
        $pelotonesActivos = $database->resultset();

        // Insertar vínculos en tb_distributivo_peloton
        foreach ($pelotonesActivos as $peloton) {
            $database->query("INSERT INTO operaciones.tb_distributivo_peloton (
                    fk_peloton_id, fk_distributivo_id
                ) VALUES (
                    :fk_peloton_id, :fk_distributivo_id
                )");

            $database->bind(':fk_peloton_id', $peloton['peloton_id']);
            $database->bind(':fk_distributivo_id', $inserted['distributivo_id']);
            $database->execute();
        }

        $database->endTransaction();
        $database->closeConnection();
        jsonResponse(['msg' => 'Registro creado con exito, ahora debe asignar al personal a cada estacion y grupo', 'id' => $inserted['distributivo_id']], 201);
    } else {

        $database->query('UPDATE operaciones.tb_distributivo SET
                fk_usuario_id = :fk_usuario_id,
                distributivo_codigo = :distributivo_codigo,
                distributivo_periodo_inicio = :distributivo_periodo_inicio,
                distributivo_periodo_cierre = :distributivo_periodo_cierre,
                distributivo_jornadas = :distributivo_jornadas,
                distributivo_ingreso_guardia = :distributivo_ingreso_guardia,
                distributivo_salida_guardia = :distributivo_salida_guardia,
                distributivo_estado = :distributivo_estado
            WHERE distributivo_id = :distributivo_id
        ');

        $database->bind(':fk_usuario_id', authUsuarioId() ?? prop($request, 'fk_usuario_id'));
        $database->bind(':distributivo_codigo', prop($request, 'distributivo_codigo'));
        $database->bind(':distributivo_periodo_inicio', prop($request, 'distributivo_periodo_inicio'));
        $database->bind(':distributivo_periodo_cierre', prop($request, 'distributivo_periodo_cierre'));
        $database->bind(':distributivo_jornadas', prop($request, 'distributivo_jornadas'));
        $database->bind(':distributivo_ingreso_guardia', prop($request, 'distributivo_ingreso_guardia'));
        $database->bind(':distributivo_salida_guardia', prop($request, 'distributivo_salida_guardia'));
        $database->bind(':distributivo_estado', prop($request, 'distributivo_estado'));
        $database->bind(':distributivo_id', prop($request, 'distributivo_id'));
        $success = $database->execute();

        // REGISTRO EN LA TABLA TROPAS ACORDE AL OBJETO RECIBIDO
        $grupos = prop($request, 'grupos', []);
        foreach ($grupos as $grupo) {
            $pelotones = prop($grupo, 'pelotones', []);
            foreach ($pelotones as $peloton) {
                // ELIMINAR DE LA TABLA DE TROPAS TODOS LOS REGISTROS PARA VOLVERLOS A INGRESAR
                $database->query('DELETE FROM operaciones.tb_tropas WHERE fk_dist_pelo_id = :fk_dist_pelo_id');
                $database->bind(':fk_dist_pelo_id', prop($peloton, 'dist_pelo_id'));
                $database->execute();
                // recorrer los cargos del peloton
                $cargos = prop($peloton, 'cargos', []);
                foreach ($cargos as $cargo) {
                    // $cargo_nombre = prop($cargo, 'cargo_nombre');
                    $puestos = prop($cargo, 'puestos', []);
                    foreach ($puestos as $puesto) {
                        // Insertar en la tabla de tropas
                        $database->query('INSERT INTO operaciones.tb_tropas (
                            fk_dist_pelo_id, tropa_cargo, fk_personal_id
                        ) VALUES (
                            :fk_dist_pelo_id, :tropa_cargo, :fk_personal_id
                        )');

                        $database->bind(':fk_dist_pelo_id', prop($puesto, 'fk_dist_pelo_id'));
                        $database->bind(':tropa_cargo', prop($puesto, 'tropa_cargo'));
                        $database->bind(':fk_personal_id', prop($puesto, 'fk_personal_id'));
                        $database->execute();
                    }
                }
            }
        }

        if (!$success) {
            jsonResponse(['error' => 'Error al actualizar', 'msg' => $database->getErrors()[2]], 500);
        }
        $database->endTransaction();
        $database->closeConnection();
        jsonResponse(['msg' => 'Registro actualizado con exito', 'id' => $request->distributivo_id], 200);
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

