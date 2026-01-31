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
	if ( !isset($request->tin_id) ) {

			$database = new Database();
			$database->query('SELECT MAX(tin_id)+1 AS CODIGO FROM tipoinstitucion');
			$id = $database->single();
			$database->closeConnection();

			$database = new Database();
			$database->query('INSERT INTO tipoinstitucion (tin_id, tin_descripcion, tin_color, tin_estado) 
			VALUES (:id, :descripcion, :color, :estado)');
			$database->bind(':id', $id["CODIGO"]);
			$database->bind(':descripcion', $request->tin_descripcion);
			$database->bind(':color', $request->tin_color);
			$database->bind(':estado', $request->tin_estado);
	
	}else {

		$database = new Database();
		$database->query('UPDATE tipoinstitucion SET 
						tin_descripcion = :descripcion, 
						tin_color = :color, 
						tin_estado = :estado
						WHERE tin_id = :id');
		$database->bind(':id', $request->tin_id);
		$database->bind(':descripcion', $request->tin_descripcion);
		$database->bind(':color', $request->tin_color);
		$database->bind(':estado', $request->tin_estado);
	
	}

	if ( $guardar ) {
		// $database->beginTransaction();
		$Hecho = $database->execute();
		// $database->cancelTransaction();
		$database->closeConnection();
		$respuesta = "";

		if ($Hecho == "1" && !isset($request->tin_id) ) {
			$respuesta = json_encode( array('id' => $id["CODIGO"]) );
		}elseif ($Hecho == "1") {
			// $respuesta = json_encode( array('err' => false, 'mensaje' => 'Registro Actualizado'));
			$respuesta = json_encode( array('id' => $request->tin_id) );
		}else{
			$respuesta = json_encode( array('err' => true, 'mensaje' => $Hecho));
		}
	}

} catch (\Throwable $th) {
	$respuesta = json_encode( array('err' => true, 'mensaje' => $th));
}

echo $respuesta;

?>