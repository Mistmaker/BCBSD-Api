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
	if (!isset($request->ofi_id)) {

		$database = new Database();
		$database->query('SELECT MAX(ofi_id)+1 AS CODIGO FROM oficios');
		$id = $database->single();
		$database->closeConnection();

		$database = new Database();
		$database->query('INSERT INTO oficios (ofi_id, ofi_alias, ofi_encabezado, ofi_cuerpo, ofi_despedida, ofi_firma, ofi_pie, ofi_estado) 
			VALUES (:id, :alias, :encabezado, :cuerpo, :despedida, :firma, :pie,  :estado)');
		$database->bind(':id', $id["CODIGO"]);
		$database->bind(':alias', $request->ofi_alias);
		$database->bind(':encabezado', $request->ofi_encabezado);
		$database->bind(':cuerpo', $request->ofi_cuerpo);
		$database->bind(':despedida', $request->ofi_despedida);
		$database->bind(':firma', $request->ofi_firma);
		$database->bind(':pie', $request->ofi_pie);
		$database->bind(':estado', $request->ofi_estado);

	} else {
		$database = new Database();
		$database->query('UPDATE oficios SET 
						ofi_alias = :alias, 
						ofi_encabezado = :encabezado,
						ofi_cuerpo = :cuerpo, 
						ofi_despedida = :despedida, 
						ofi_firma = :firma, 
						ofi_pie = :pie,  
						ofi_estado = :estado
						WHERE ofi_id = :id');
		$database->bind(':id', $request->ofi_id);
		$database->bind(':alias', $request->ofi_alias);
		$database->bind(':encabezado', $request->ofi_encabezado);
		$database->bind(':cuerpo', $request->ofi_cuerpo);
		$database->bind(':despedida', $request->ofi_despedida);
		$database->bind(':firma', $request->ofi_firma);
		$database->bind(':pie', $request->ofi_pie);
		$database->bind(':estado', $request->ofi_estado);
	}


	// $database->beginTransaction();
	$Hecho = $database->execute();
	// $database->cancelTransaction();
	$database->closeConnection();
	$respuesta = "";

	if ($Hecho == "1" && !isset($request->ofi_id)) {
		$respuesta = json_encode(array('id' => $id["CODIGO"]));
	} elseif ($Hecho == "1") {
		// $respuesta = json_encode( array('err' => false, 'mensaje' => 'Registro Actualizado'));
		$respuesta = json_encode(array('id' => $request->ofi_id));
	} else {
		$respuesta = json_encode(array('err' => true, 'mensaje' => $Hecho));
	}
} catch (\Throwable $th) {
	$respuesta = json_encode(array('err' => true, 'mensaje' => $th));
}

echo $respuesta;
