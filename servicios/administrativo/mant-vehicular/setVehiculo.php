<?php
// error_reporting(E_ALL);
// ini_set('display_errors', 1);

// DB configuration
include_once("../../../classes/dbconfig.php");
include_once '../../../classes/database.class.php';

// Retorna un json
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header("Access-Control-Allow-Headers: Origin, Content-Type, Accept");
header("Access-Control-Allow-Methods: POST, PUT, OPTIONS");

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
// fin de funciones utilitarias

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

	if (!isset($request->vehiculo_id)) {

		$database->query('INSERT INTO administrativo.tb_vehiculos (
			fk_usuario_id, fk_estacion_id, fk_marca_id, 
			vehiculo_placa, vehiculo_toneladas, vehiculo_tipo, vehiculo_color1, vehiculo_marca, 
			custodio_id, vehiculo_modelo, vehiculo_chasis, vehiculo_motor, 
			vehiculo_combustible, vehiculo_avaluo, vehiculo_anio, vehiculo_pais, vehiculo_corroceria, 
			vehiculo_pasajeros, vehiculo_cilindraje, vehiculo_color2, vehiculo_proposito, 
			vehiculo_anio_matricula, vehiculo_ramv, vehiculo_sigla
		) VALUES (
			:fk_usuario_id, :fk_estacion_id, :fk_marca_id, 
			:vehiculo_placa, :vehiculo_toneladas, :vehiculo_tipo, :vehiculo_color1, :vehiculo_marca, 
			:custodio_id, :vehiculo_modelo, :vehiculo_chasis, :vehiculo_motor, 
			:vehiculo_combustible, :vehiculo_avaluo, :vehiculo_anio, :vehiculo_pais, :vehiculo_corroceria, 
			:vehiculo_pasajeros, :vehiculo_cilindraje, :vehiculo_color2, :vehiculo_proposito, 
			:vehiculo_anio_matricula, :vehiculo_ramv, :vehiculo_sigla
		) RETURNING vehiculo_id ');

		$request->fk_usuario_id = 1;
		$request->fk_estacion_id = 1;
		$request->fk_marca_id = 1;
		$request->custodio_id = 1;
		$database->bind(':fk_usuario_id', prop($request, 'fk_usuario_id'));
		$database->bind(':fk_estacion_id', prop($request, 'fk_estacion_id'));
		$database->bind(':fk_marca_id', prop($request, 'fk_marca_id'));
		// $database->bind(':vehiculo_direccion', $request->vehiculo_direccion);
		$database->bind(':vehiculo_placa', prop($request, 'vehiculo_placa'));
		$database->bind(':vehiculo_toneladas', prop($request, 'vehiculo_toneladas'));
		$database->bind(':vehiculo_tipo', prop($request, 'vehiculo_tipo'));
		$database->bind(':vehiculo_color1', prop($request, 'vehiculo_color1'));
		$database->bind(':vehiculo_marca', prop($request, 'vehiculo_marca'));
		// $database->bind(':vehiculo_fingreso', $request->vehiculo_fingreso);
		$database->bind(':custodio_id', prop($request, 'custodio_id'));
		$database->bind(':vehiculo_modelo', prop($request, 'vehiculo_modelo'));
		$database->bind(':vehiculo_chasis', prop($request, 'vehiculo_chasis'));
		$database->bind(':vehiculo_motor', prop($request, 'vehiculo_motor'));
		$database->bind(':vehiculo_combustible', prop($request, 'vehiculo_combustible'));
		$database->bind(':vehiculo_avaluo', prop($request, 'vehiculo_avaluo'));
		$database->bind(':vehiculo_anio', prop($request, 'vehiculo_anio'));
		$database->bind(':vehiculo_pais', prop($request, 'vehiculo_pais'));
		$database->bind(':vehiculo_corroceria', prop($request, 'vehiculo_corroceria'));
		$database->bind(':vehiculo_pasajeros', prop($request, 'vehiculo_pasajeros'));
		$database->bind(':vehiculo_cilindraje', prop($request, 'vehiculo_cilindraje'));
		$database->bind(':vehiculo_color2', prop($request, 'vehiculo_color2'));
		$database->bind(':vehiculo_proposito', prop($request, 'vehiculo_proposito'));
		$database->bind(':vehiculo_anio_matricula', prop($request, 'vehiculo_anio_matricula'));
		$database->bind(':vehiculo_ramv', prop($request, 'vehiculo_ramv'));
		$database->bind(':vehiculo_sigla', prop($request, 'vehiculo_sigla'));

		$inserted = $database->single(); // ejecuta y devuelve resultado
		if (!$inserted) {
			jsonResponse(['error' => 'Error al insertar', 'msg' => $database->getErrors()[2]], 500);
		}
		$database->endTransaction();
		$database->closeConnection();
		jsonResponse(['msg' => 'Registro creado con exito', 'id' => $inserted['vehiculo_id']], 201);
	} else {

		// $database = new Database();
		$database->query('UPDATE administrativo.tb_vehiculos SET 
						fk_usuario_id = :fk_usuario_id,
						fk_estacion_id = :fk_estacion_id,
						fk_marca_id = :fk_marca_id,
						vehiculo_estado = :vehiculo_estado,
						vehiculo_direccion = :vehiculo_direccion,
						vehiculo_placa = :vehiculo_placa,
						vehiculo_toneladas = :vehiculo_toneladas,
						vehiculo_tipo = :vehiculo_tipo,
						vehiculo_color1 = :vehiculo_color1,
						vehiculo_marca = :vehiculo_marca,
						vehiculo_fingreso = :vehiculo_fingreso,
						custodio_id = :custodio_id,
						vehiculo_modelo = :vehiculo_modelo,
						vehiculo_chasis = :vehiculo_chasis,
						vehiculo_motor = :vehiculo_motor,
						vehiculo_combustible = :vehiculo_combustible,
						vehiculo_avaluo = :vehiculo_avaluo,
						vehiculo_anio = :vehiculo_anio,
						vehiculo_pais = :vehiculo_pais,
						vehiculo_corroceria = :vehiculo_corroceria,
						vehiculo_pasajeros = :vehiculo_pasajeros,
						vehiculo_cilindraje = :vehiculo_cilindraje,
						vehiculo_color2 = :vehiculo_color2,
						vehiculo_proposito = :vehiculo_proposito,
						vehiculo_anio_matricula = :vehiculo_anio_matricula,
						vehiculo_ramv = :vehiculo_ramv,
						vehiculo_sigla = :vehiculo_sigla
					WHERE vehiculo_id = :vehiculo_id');


		$database->bind(':vehiculo_id', prop($request, 'vehiculo_id'));
		$database->bind(':fk_usuario_id', prop($request, 'fk_usuario_id'));
		$database->bind(':fk_estacion_id', prop($request, 'fk_estacion_id'));
		$database->bind(':fk_marca_id', prop($request, 'fk_marca_id'));
		$database->bind(':vehiculo_estado', prop($request, 'vehiculo_estado'));
		$database->bind(':vehiculo_direccion', prop($request, 'vehiculo_direccion'));
		$database->bind(':vehiculo_placa', prop($request, 'vehiculo_placa'));
		$database->bind(':vehiculo_toneladas', prop($request, 'vehiculo_toneladas'));
		$database->bind(':vehiculo_tipo', prop($request, 'vehiculo_tipo'));
		$database->bind(':vehiculo_color1', prop($request, 'vehiculo_color1'));
		$database->bind(':vehiculo_marca', prop($request, 'vehiculo_marca'));
		$database->bind(':vehiculo_fingreso', prop($request, 'vehiculo_fingreso'));
		$database->bind(':custodio_id', prop($request, 'custodio_id'));
		$database->bind(':vehiculo_modelo', prop($request, 'vehiculo_modelo'));
		$database->bind(':vehiculo_chasis', prop($request, 'vehiculo_chasis'));
		$database->bind(':vehiculo_motor', prop($request, 'vehiculo_motor'));
		$database->bind(':vehiculo_combustible', prop($request, 'vehiculo_combustible'));
		$database->bind(':vehiculo_avaluo', prop($request, 'vehiculo_avaluo'));
		$database->bind(':vehiculo_anio', prop($request, 'vehiculo_anio'));
		$database->bind(':vehiculo_pais', prop($request, 'vehiculo_pais'));
		$database->bind(':vehiculo_corroceria', prop($request, 'vehiculo_corroceria'));
		$database->bind(':vehiculo_pasajeros', prop($request, 'vehiculo_pasajeros'));
		$database->bind(':vehiculo_cilindraje', prop($request, 'vehiculo_cilindraje'));
		$database->bind(':vehiculo_color2', prop($request, 'vehiculo_color2'));
		$database->bind(':vehiculo_proposito', prop($request, 'vehiculo_proposito'));
		$database->bind(':vehiculo_anio_matricula', prop($request, 'vehiculo_anio_matricula'));
		$database->bind(':vehiculo_ramv', prop($request, 'vehiculo_ramv'));
		$database->bind(':vehiculo_sigla', prop($request, 'vehiculo_sigla'));

		$success = $database->execute();

		if (!$success) {
			jsonResponse(['error' => 'Error al actualizar', 'msg' => $database->getErrors()[2]], 500);
		}
		$database->endTransaction();
		$database->closeConnection();
		jsonResponse(['msg' => 'Registro actualizado con exito', 'id' => $request->vehiculo_id], 200);
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
