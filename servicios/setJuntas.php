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

// echo json_encode($request);

// echo count($request);

try {

	$database = new Database();
	$database->query('DELETE FROM juntas WHERE ins_id = :ins_id');
	$database->bind(':ins_id', $request[0]->ins_id);
	$database->execute();
	$database->closeConnection();

	foreach ($request as $junta) {

		// $database = new Database();
		// $database->query('DELETE FROM juntas WHERE ins_id = :ins_id');
		// $database->bind(':ins_id', $junta->ins_id);
		// $database->execute();
		// $database->closeConnection();

		$database = new Database();
		$database->query('SELECT MAX(jun_id)+1 AS CODIGO FROM juntas');
		$id = $database->single();
		$database->closeConnection();

		if ($id["CODIGO"] === null) {
			$id["CODIGO"] = 1;
		}

		$database = new Database();
		$database->query('INSERT INTO juntas (jun_id, ins_id, jun_numero, jun_genero, jun_estado) 
			VALUES (:id, :ins_id, :jun_numero, :jun_genero, :jun_estado)');
		$database->bind(':id', $id["CODIGO"]);
		$database->bind(':ins_id', $junta->ins_id);
		$database->bind(':jun_numero', $junta->jun_numero);
		$database->bind(':jun_genero', $junta->jun_genero);
		$database->bind(':jun_estado', $junta->jun_estado);

		// $database->beginTransaction();
		$Hecho = $database->execute();
		// $database->cancelTransaction();
		$database->closeConnection();


		$junta->jun_id = (int)$id["CODIGO"];

		// $respuesta = "";
		// $junta->jun_genero = "modificado";
		// echo $junta->jun_genero;
	}

	$respuesta = json_encode($request);
} catch (\Throwable $th) {
	$respuesta = json_encode(array('err' => true, 'mensaje' => $th));
}

echo $respuesta;
