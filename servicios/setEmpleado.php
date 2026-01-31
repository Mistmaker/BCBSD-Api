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

$database = new Database();
$database->query("SELECT emp_id FROM empleados where per_id = :id");
$database->bind(':id', $request->per_id);
$rows = $database->resultset();
$database->closeConnection();
if (count($rows) > 0) {
	// if (isset($request->emp_id)) {
	if ($request->emp_id !== $rows[0]["emp_id"]) {
		$respuesta = json_encode(array('err' => true, 'mensaje' => 'La persona ya se encuentra registrada como empleado'));
		$guardar = false;
	}
	// }
}

try {
	if (!isset($request->emp_id)) {

		$database = new Database();
		$database->query('SELECT MAX(emp_id)+1 AS CODIGO FROM empleados');
		$id = $database->single();
		$database->closeConnection();

		if ($id["CODIGO"] === null) {
			$id["CODIGO"] = 1;
		}

		$database = new Database();
		$database->query('INSERT INTO empleados (emp_id, per_id, area_id, car_id, emp_estado) 
			VALUES (:id, :idPer, :idCar, :idAre, :estado)');
		$database->bind(':id', $id["CODIGO"]);
		$database->bind(':idPer', $request->per_id);
		$database->bind(':idCar', $request->area_id);
		$database->bind(':idAre', $request->car_id);
		$database->bind(':estado', $request->emp_estado);
	} else {

		$database = new Database();
		$database->query('UPDATE empleados SET 
						per_id = :idPer, 
						area_id = :idCar, 
						car_id = :idAre, 
						emp_estado = :estado
						WHERE emp_id = :id');
		$database->bind(':id', $request->emp_id);
		$database->bind(':idPer', $request->per_id);
		$database->bind(':idCar', $request->area_id);
		$database->bind(':idAre', $request->car_id);
		$database->bind(':estado', $request->emp_estado);
	}

	if ($guardar) {
		// $database->beginTransaction();
		$Hecho = $database->execute();
		// $database->cancelTransaction();
		$database->closeConnection();
		$respuesta = "";

		if ($Hecho == "1" && !isset($request->emp_id)) {
			$respuesta = json_encode(array('id' => $id["CODIGO"]));
		} elseif ($Hecho == "1") {
			// $respuesta = json_encode( array('err' => false, 'mensaje' => 'Registro Actualizado'));
			$respuesta = json_encode(array('id' => $request->emp_id));
		} else {
			$respuesta = json_encode(array('err' => true, 'mensaje' => $Hecho));
		}
	}
} catch (\Throwable $th) {
	$respuesta = json_encode(array('err' => true, 'mensaje' => $th));
}

echo $respuesta;
