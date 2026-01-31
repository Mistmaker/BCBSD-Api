<?php
//incluir la clase de la Bdd
include_once("../config.php");
include_once("../classes/database.class.php");

// Retiorna un json
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header("Access-Control-Allow-Headers: Origin, X-Requested-With, Content-Type, Accept");
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE');

$postdata = file_get_contents("php://input");
$request = json_decode($postdata);
$guardar = true;

// echo json_encode($request);

try {
	if (!isset($request->car_id)) {

		$database = new Database();
		$database->query('SELECT MAX(car_id)+1 AS CODIGO FROM cargos');
		$id = $database->single();
		$database->closeConnection();

		$database = new Database();
		$database->query('INSERT INTO cargos (car_id, car_nombre, car_estado) 
			VALUES (:id, :nombre, :estado)');
		$database->bind(':id', $id["CODIGO"]);
		$database->bind(':nombre', $request->car_nombre);
		$database->bind(':estado', $request->car_estado);
	} else {

		$database = new Database();
		$database->query('UPDATE cargos SET 
						car_nombre = :nombre, 
						car_estado = :estado
						WHERE car_id = :id');
		$database->bind(':id', $request->car_id);
		$database->bind(':nombre', $request->car_nombre);
		$database->bind(':estado', $request->car_estado);
	}

	if ($guardar) {
		// $database->beginTransaction();
		$Hecho = $database->execute();
		// $database->cancelTransaction();
		$database->closeConnection();
		$respuesta = "";

		if ($Hecho == "1" && !isset($request->car_id)) {
			$respuesta = json_encode(array('id' => $id["CODIGO"]));
		} elseif ($Hecho == "1") {
			// $respuesta = json_encode( array('err' => false, 'mensaje' => 'Registro Actualizado'));
			$respuesta = json_encode(array('id' => $request->car_id));
		} else {
			$respuesta = json_encode(array('err' => true, 'mensaje' => $Hecho));
		}
	}
} catch (\Throwable $th) {
	$respuesta = json_encode(array('err' => true, 'mensaje' => $th));
}

echo $respuesta;
