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
	if (!isset($request->area_id)) {

		$database = new Database();
		$database->query('SELECT MAX(area_id)+1 AS CODIGO FROM areas');
		$id = $database->single();
		$database->closeConnection();

		$database = new Database();
		$database->query('INSERT INTO areas (area_id, area_nombre, area_estado) 
			VALUES (:id, :nombre, :estado)');
		$database->bind(':id', $id["CODIGO"]);
		$database->bind(':nombre', $request->area_nombre);
		$database->bind(':estado', $request->area_estado);
	} else {

		$database = new Database();
		$database->query('UPDATE areas SET 
						area_nombre = :nombre, 
						area_estado = :estado
						WHERE area_id = :id');
		$database->bind(':id', $request->area_id);
		$database->bind(':nombre', $request->area_nombre);
		$database->bind(':estado', $request->area_estado);
	}

	if ($guardar) {
		// $database->beginTransaction();
		$Hecho = $database->execute();
		// $database->cancelTransaction();
		$database->closeConnection();
		$respuesta = "";

		if ($Hecho == "1" && !isset($request->area_id)) {
			$respuesta = json_encode(array('id' => $id["CODIGO"]));
		} elseif ($Hecho == "1") {
			// $respuesta = json_encode( array('err' => false, 'mensaje' => 'Registro Actualizado'));
			$respuesta = json_encode(array('id' => $request->area_id));
		} else {
			$respuesta = json_encode(array('err' => true, 'mensaje' => $Hecho));
		}
	}
} catch (\Throwable $th) {
	$respuesta = json_encode(array('err' => true, 'mensaje' => $th));
}

echo $respuesta;
