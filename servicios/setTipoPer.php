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
	if ( !isset($request->tpe_id) ) {

			$database = new Database();
			$database->query('SELECT MAX(tpe_id)+1 AS CODIGO FROM tipopersona');
			$id = $database->single();
			$database->closeConnection();

			$database = new Database();
			$database->query('INSERT INTO tipopersona (tpe_id, tpe_descripcion, tpe_estado) 
			VALUES (:id, :descripcion, :estado)');
			$database->bind(':id', $id["CODIGO"]);
			$database->bind(':descripcion', $request->tpe_descripcion);
			$database->bind(':estado', $request->tpe_estado);
	
	}else {

		$database = new Database();
		$database->query('UPDATE tipopersona SET 
						tpe_descripcion = :descripcion, 
						tpe_estado = :estado
						WHERE tpe_id = :id');
		$database->bind(':id', $request->tpe_id);
		$database->bind(':descripcion', $request->tpe_descripcion);
		$database->bind(':estado', $request->tpe_estado);
	
	}

	if ( $guardar ) {
		// $database->beginTransaction();
		$Hecho = $database->execute();
		// $database->cancelTransaction();
		$database->closeConnection();
		$respuesta = "";

		if ($Hecho == "1" && !isset($request->tpe_id) ) {
			$respuesta = json_encode( array('id' => $id["CODIGO"]) );
		}elseif ($Hecho == "1") {
			// $respuesta = json_encode( array('err' => false, 'mensaje' => 'Registro Actualizado'));
			$respuesta = json_encode( array('id' => $request->tpe_id) );
		}else{
			$respuesta = json_encode( array('err' => true, 'mensaje' => $Hecho));
		}
	}

} catch (\Throwable $th) {
	$respuesta = json_encode( array('err' => true, 'mensaje' => $th));
}

echo $respuesta;

?>