<?php
//incluir la clase de la Bdd
include_once("../config.php");
include_once("../classes/database.class.php");

require('../validadores/validarIdentificacion.php');

// Retiorna un json
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header("Access-Control-Allow-Headers: Origin, X-Requested-With, Content-Type, Accept");
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE');

$postdata = file_get_contents("php://input");
$request = json_decode($postdata);
$valido = false;

// echo json_encode($request);
$validador = new ValidarIdentificacion();

// validar CI
if ($request->ins_documento != '9999999999999') {
	if (strlen($request->ins_documento) == 10) {
		if (!$validador->validarCedula($request->ins_documento) && $valido == false) {
			$respuesta = json_encode(array('err' => true, 'mensaje' => 'Cédula incorrecta: ' . $validador->getError()));
		} else {
			$valido = true;
		}
	} else {
		// validar RUC persona natural
		if (!$validador->validarRucPersonaNatural($request->ins_documento) && $valido == false) {
			$respuesta = json_encode(array('err' => true, 'mensaje' => 'RUC incorrecto: ' . $validador->getError()));
		} else {
			$valido = true;
		}

		// validar RUC sociedad privada
		if (!$validador->validarRucSociedadPrivada($request->ins_documento) && $valido == false) {
			$respuesta = json_encode(array('err' => true, 'mensaje' => 'RUC incorrecto: ' . $validador->getError()));
		} else {
			$valido = true;
		}

		// validar RUC sociedad ublica
		if (!$validador->validarRucSociedadPublica($request->ins_documento) && $valido == false) {
			$respuesta = json_encode(array('err' => true, 'mensaje' => 'RUC incorrecto: ' . $validador->getError()));
		} else {
			$valido = true;
		}
	}
} else {
	$valido = true;
}

if ($valido) {
	$database = new Database();
	$database->query("SELECT ins_id FROM instituciones where ins_documento = :documento");
	$database->bind(':documento', $request->ins_documento);
	$rows = $database->resultset();
	$database->closeConnection();
	if (count($rows) > 0 && $request->ins_documento != '9999999999999') {
		if (isset($request->ins_id)) {
			if ($request->ins_id !== $rows[0]["ins_id"]) {
				$respuesta = json_encode(array('err' => true, 'mensaje' => 'La cédula/Ruc ya está ingresada en otra institución'));
				$valido = false;
			}
		} else {
			$respuesta = json_encode(array('err' => true, 'mensaje' => 'La cédula/Ruc ya está ingresada en otra institución'));
			$valido = false;
		}
	}
}

if ($valido) {
	try {
		if (!isset($request->ins_id)) {
			$database = new Database();
			$database->query('SELECT MAX(ins_id)+1 AS CODIGO FROM instituciones');
			$id = $database->single();
			$database->closeConnection();

			$database = new Database();
			$database->query('INSERT INTO instituciones (ins_id, tin_id, per_id, zon_id, ins_tipodocumento, ins_documento, ins_nombre, ins_direccion, ins_telefono, ins_email, ins_latitud, ins_longitud, ins_empleados, ins_recinto, ins_estado) 
			VALUES (:id, :tipInstitucion, :idPersona, :zona, :tipDocumento, :documento, :nombre, :direccion, :telefono, :email, :latitud, :longitud, :empleados, :recinto, :estado)');
			$database->bind(':id', $id["CODIGO"]);
			$database->bind(':tipInstitucion', $request->tin_id);
			$database->bind(':idPersona', $request->per_id);
			$database->bind(':zona', $request->zon_id);
			$database->bind(':tipDocumento', 'C');
			$database->bind(':documento', $request->ins_documento);
			$database->bind(':nombre', $request->ins_nombre);
			$database->bind(':direccion', $request->ins_direccion);
			$database->bind(':telefono', $request->ins_telefono);
			$database->bind(':email', $request->ins_email);
			$database->bind(':latitud', $request->ins_latitud);
			$database->bind(':longitud', $request->ins_longitud);
			$database->bind(':empleados', $request->ins_empleados);
			$database->bind(':recinto', $request->ins_recinto);
			$database->bind(':estado', $request->ins_estado);
		} else {
			$database = new Database();
			$database->query('UPDATE instituciones SET 
							tin_id = :tipInstitucion, 
							per_id = :idPersona,
							zon_id = :zona,
							ins_tipodocumento = :tipDocumento, 
							ins_documento = :documento, 
							ins_nombre = :nombres, 
							ins_direccion = :direccion, 
							ins_telefono = :telefono, 
							ins_email = :email, 
							ins_latitud = :latitud, 
							ins_longitud = :longitud, 
							ins_empleados = :empleados,
							ins_recinto = :recinto, 
							ins_estado = :estado
							WHERE ins_id = :id');
			$database->bind(':id', $request->ins_id);
			$database->bind(':tipInstitucion', $request->tin_id);
			$database->bind(':idPersona', $request->per_id);
			$database->bind(':zona', $request->zon_id);
			$database->bind(':tipDocumento', 'C');
			$database->bind(':documento', $request->ins_documento);
			$database->bind(':nombres', $request->ins_nombre);
			$database->bind(':direccion', $request->ins_direccion);
			$database->bind(':telefono', $request->ins_telefono);
			$database->bind(':email', $request->ins_email);
			$database->bind(':latitud', $request->ins_latitud);
			$database->bind(':longitud', $request->ins_longitud);
			$database->bind(':empleados', $request->ins_empleados);
			$database->bind(':recinto', $request->ins_recinto);
			$database->bind(':estado', $request->ins_estado);
		}

		// $database->beginTransaction();
		$Hecho = $database->execute();
		// $database->cancelTransaction();
		$database->closeConnection();
		$respuesta = "";

		if ($Hecho == "1" && !isset($request->ins_id)) {
			$respuesta = json_encode(array('id' => $id["CODIGO"]));
		} elseif ($Hecho == "1") {
			// $respuesta = json_encode( array('err' => false, 'mensaje' => 'Registro Actualizado'));
			$respuesta = json_encode(array('id' => $request->ins_id));
		} else {
			$respuesta = json_encode(array('err' => true, 'mensaje' => $Hecho));
		}
	} catch (\Throwable $th) {
		//throw $th;
		$respuesta = json_encode(array('err' => true, 'mensaje' => $th));
	}
}

echo $respuesta;
