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
	if ( !isset($request->zon_id) ) {

			$database = new Database();
			$database->query('SELECT MAX(zon_id)+1 AS CODIGO FROM zonas');
			$id = $database->single();
			$database->closeConnection();

			$database = new Database();
			$database->query('INSERT INTO zonas (zon_id, par_id, zon_descripcion, zon_area, zon_estado) 
			VALUES (:id, :idPar, :descripcion, :area, :estado)');
			$database->bind(':id', $id["CODIGO"]);
			$database->bind(':idPar', $request->par_id);
			$database->bind(':descripcion', $request->zon_descripcion);
			$database->bind(':area', $request->zon_area);
			$database->bind(':estado', $request->zon_estado);
	
	}else {

		$database = new Database();
		$database->query('UPDATE zonas SET 
						par_id = :idPar,
						zon_descripcion = :descripcion, 
						zon_area = :area,
						zon_estado = :estado
						WHERE zon_id = :id');
		$database->bind(':id', $request->zon_id);
		$database->bind(':idPar', $request->par_id);
		$database->bind(':descripcion', $request->zon_descripcion);
		$database->bind(':area', $request->zon_area);
		$database->bind(':estado', $request->zon_estado);
	
	}

	if ( $guardar ) {
		// $database->beginTransaction();
		$Hecho = $database->execute();
		// $database->cancelTransaction();
		$database->closeConnection();
		$respuesta = "";

		if ($Hecho == "1" && !isset($request->zon_id) ) {
			$respuesta = json_encode( array('id' => $id["CODIGO"]) );
		}elseif ($Hecho == "1") {
			// $respuesta = json_encode( array('err' => false, 'mensaje' => 'Registro Actualizado'));
			$respuesta = json_encode( array('id' => $request->zon_id) );
		}else{
			$respuesta = json_encode( array('err' => true, 'mensaje' => $Hecho));
		}
	}

} catch (\Throwable $th) {
	$respuesta = json_encode( array('err' => true, 'mensaje' => $th));
}

echo $respuesta;
