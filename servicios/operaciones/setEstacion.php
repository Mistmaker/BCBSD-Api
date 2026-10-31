<?php
// DB configuration
include_once("../../classes/dbconfig.php");
include_once '../../classes/database.class.php';

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header("Access-Control-Allow-Headers: Origin, Content-Type, Accept");
header("Access-Control-Allow-Methods: POST, PUT, OPTIONS");

date_default_timezone_set('America/Guayaquil');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$database = null;
$transactionStarted = false;

try {
    $requestMethod = strtoupper($_SERVER['REQUEST_METHOD']);
    if (!in_array($requestMethod, ['POST', 'PUT'], true)) {
        jsonResponse(['error' => 'Método no permitido'], 405);
    }

    $request = json_decode(file_get_contents('php://input'));
    if (json_last_error() !== JSON_ERROR_NONE || !is_object($request)) {
        jsonResponse(['error' => 'Datos JSON inválidos'], 400);
    }

    $estacionNombre = prop($request, 'estacion_nombre');
    if (!is_string($estacionNombre) || trim($estacionNombre) === '') {
        jsonResponse(['error' => 'El nombre de la estación es obligatorio'], 400);
    }

    $database = new Database();
    if (!$database->beginTransaction()) {
        throw new RuntimeException('No se pudo iniciar la transacción');
    }
    $transactionStarted = true;

    if (!isset($request->estacion_id)) {
        $database->query('INSERT INTO operaciones.tb_estaciones (
            estacion_nombre,
            estacion_tipo,
            estacion_subtipo,
            estacion_jornada,
            estacion_ubicacion,
            estacion_ubicacion_x,
            estacion_ubicacion_y,
            estacion_estado
        ) VALUES (
            :estacion_nombre,
            :estacion_tipo,
            :estacion_subtipo,
            :estacion_jornada,
            :estacion_ubicacion,
            :estacion_ubicacion_x,
            :estacion_ubicacion_y,
            :estacion_estado
        ) RETURNING estacion_id');

        $database->bind(':estacion_nombre', $estacionNombre);
        $database->bind(':estacion_tipo', prop($request, 'estacion_tipo') ?? 'ESTACION');
        $database->bind(':estacion_subtipo', prop($request, 'estacion_subtipo') ?? 'URBANA');
        $database->bind(':estacion_jornada', prop($request, 'estacion_jornada') ?? '24 HORAS');
        $database->bind(':estacion_ubicacion', prop($request, 'estacion_ubicacion'));
        $database->bind(':estacion_ubicacion_x', prop($request, 'estacion_ubicacion_x'));
        $database->bind(':estacion_ubicacion_y', prop($request, 'estacion_ubicacion_y'));
        $database->bind(':estacion_estado', prop($request, 'estacion_estado') ?? 'ACTIVO');

        $inserted = $database->single();
        if (!$inserted) {
            $database->cancelTransaction();
            jsonResponse(['error' => 'Error al insertar', 'msg' => $database->getErrors()[2]], 500);
        }

        $database->endTransaction();
        $database->closeConnection();
        jsonResponse([
            'msg' => 'Estación creada con éxito',
            'id' => $inserted['estacion_id']
        ], 201);
    }

    $database->query('UPDATE operaciones.tb_estaciones SET
        estacion_nombre = :estacion_nombre,
        estacion_tipo = :estacion_tipo,
        estacion_subtipo = :estacion_subtipo,
        estacion_jornada = :estacion_jornada,
        estacion_ubicacion = :estacion_ubicacion,
        estacion_ubicacion_x = :estacion_ubicacion_x,
        estacion_ubicacion_y = :estacion_ubicacion_y,
        estacion_estado = :estacion_estado
    WHERE estacion_id = :estacion_id');

    $database->bind(':estacion_id', prop($request, 'estacion_id'));
    $database->bind(':estacion_nombre', $estacionNombre);
    $database->bind(':estacion_tipo', prop($request, 'estacion_tipo') ?? 'ESTACION');
    $database->bind(':estacion_subtipo', prop($request, 'estacion_subtipo') ?? 'URBANA');
    $database->bind(':estacion_jornada', prop($request, 'estacion_jornada') ?? '24 HORAS');
    $database->bind(':estacion_ubicacion', prop($request, 'estacion_ubicacion'));
    $database->bind(':estacion_ubicacion_x', prop($request, 'estacion_ubicacion_x'));
    $database->bind(':estacion_ubicacion_y', prop($request, 'estacion_ubicacion_y'));
    $database->bind(':estacion_estado', prop($request, 'estacion_estado') ?? 'ACTIVO');

    $success = $database->execute();
    if (!$success) {
        $database->cancelTransaction();
        jsonResponse(['error' => 'Error al actualizar', 'msg' => $database->getErrors()[2]], 500);
    }

    if ($database->rowCount() === 0) {
        $database->cancelTransaction();
        jsonResponse(['error' => 'No se encontró la estación'], 404);
    }

    $database->endTransaction();
    $database->closeConnection();
    jsonResponse([
        'msg' => 'Estación actualizada con éxito',
        'id' => $request->estacion_id
    ]);
} catch (Throwable $th) {
    if ($database instanceof Database) {
        if ($transactionStarted) {
            $database->cancelTransaction();
        }
        $database->closeConnection();
    }

    jsonResponse([
        'error' => 'Excepción no controlada',
        'message' => $th->getMessage()
    ], 500);
}

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
