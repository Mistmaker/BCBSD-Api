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

$validador = new ValidarIdentificacion();

// validar CI
if (strlen($request->per_documento) == 10 ) {
	if (!$validador->validarCedula($request->per_documento) && $valido == false) {
		$respuesta = json_encode( array('err' => true, 'mensaje' => 'Cédula incorrecta: '.$validador->getError()));
	}else{
		$valido = true;
	}
} else {
	// validar RUC persona natural
	if (!$validador->validarRucPersonaNatural($request->per_documento) && $valido == false) {
		$respuesta = json_encode( array('err' => true, 'mensaje' => 'RUC incorrecto: '.$validador->getError()));
	}else{
		$valido = true;
	}

	// validar RUC sociedad privada
	if (!$validador->validarRucSociedadPrivada($request->per_documento) && $valido == false) {
		$respuesta = json_encode( array('err' => true, 'mensaje' => 'RUC incorrecto: '.$validador->getError()));
	}else{
		$valido = true;
	}

	// validar RUC sociedad ublica
	if (!$validador->validarRucSociedadPublica($request->per_documento) && $valido == false) {
		$respuesta = json_encode( array('err' => true, 'mensaje' => 'RUC incorrecto: '.$validador->getError()));
	}else{
		$valido = true;
	}
}

if ( $valido ) {
	$database = new Database();
    $database->query("SELECT * FROM personas where per_documento = :documento");
	$database->bind(':documento', $request->per_documento);
    $rows = $database->resultset();
	$database->closeConnection();
	if (count($rows) > 0){
		if ( isset($request->per_id) ) {
			if ( $request->per_id !== $rows[0]["per_id"] ) {
				$respuesta = json_encode( array('err' => true, 'mensaje' => 'La cédula/Ruc ya está ingresada en otra persona' ));
				$valido = false;
			}
		} else {
			$respuesta = json_encode( array('err' => true, 'mensaje' => 'La cédula/Ruc ya está ingresada en otra persona'));
			$valido = false;
		}
	}
}

if ($valido) {
	try {
		if ( !isset($request->per_id) ) {
			$database = new Database();
			$database->query('SELECT MAX(per_id)+1 AS CODIGO FROM personas');
			$id = $database->single();
			$database->closeConnection();
		
			$database = new Database();
			$database->query('INSERT INTO personas (per_id, tpe_id, zon_id, per_tipodocumento, per_documento, per_apellido, per_nombre, per_direccion, per_telefono, per_email, per_genero, per_fechanacimiento, per_estado) 
			VALUES (:id, :tipPersona, :zona, :tipDocumento, :documento, :apellidos, :nombres, :direccion, :telefono, :email, :genero, :fecha, :estado)');
			$database->bind(':id', $id["CODIGO"]);
			$database->bind(':tipPersona', $request->tpe_id);
			$database->bind(':zona', $request->zon_id);
			$database->bind(':tipDocumento','C');
			$database->bind(':documento', $request->per_documento);
			$database->bind(':apellidos', $request->per_apellido);
			$database->bind(':nombres', $request->per_nombre);
			$database->bind(':direccion', $request->per_direccion);
			$database->bind(':telefono', $request->per_telefono);
			$database->bind(':email', $request->per_email);
			$database->bind(':genero', $request->per_genero);
			$database->bind(':fecha', $request->per_fechanacimiento);
			$database->bind(':estado', $request->per_estado);
		
		}else {
			$database = new Database();
			$database->query('UPDATE personas SET 
							tpe_id = :tipPersona, 
							zon_id = :zona,
							per_tipodocumento = :tipDocumento, 
							per_documento = :documento, 
							per_apellido = :apellidos, 
							per_nombre = :nombres, 
							per_direccion = :direccion, 
							per_telefono = :telefono, 
							per_email = :email, 
							per_genero = :genero, 
							per_fechanacimiento = :fecha, 
							per_estado = :estado
							WHERE per_id = :id');
			$database->bind(':id', $request->per_id);
			$database->bind(':tipPersona', $request->tpe_id);
			$database->bind(':zona', $request->zon_id);
			$database->bind(':tipDocumento', 'C');
			$database->bind(':documento', $request->per_documento);
			$database->bind(':apellidos', $request->per_apellido);
			$database->bind(':nombres', $request->per_nombre);
			$database->bind(':direccion', $request->per_direccion);
			$database->bind(':telefono', $request->per_telefono);
			$database->bind(':email', $request->per_email);
			$database->bind(':genero', $request->per_genero);
			$database->bind(':fecha', $request->per_fechanacimiento);
			$database->bind(':estado', $request->per_estado);
		
		}

		// $database->beginTransaction();
		$Hecho = $database->execute();
		// $database->cancelTransaction();
		$database->closeConnection();
		$respuesta = "";

		if ($Hecho == "1" && !isset($request->per_id) ) {
			$respuesta = json_encode( array('id' => $id["CODIGO"]) );
		}elseif ($Hecho == "1") {
			// $respuesta = json_encode( array('err' => false, 'mensaje' => 'Registro Actualizado'));
			$respuesta = json_encode( array('id' => $request->per_id) );
		}else{
			$respuesta = json_encode( array('err' => true, 'mensaje' => $Hecho));
		}

	} catch (\Throwable $th) {
		//throw $th;
		$respuesta = json_encode( array('err' => true, 'mensaje' => $th));
	}
}
echo $respuesta;

?>