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
	if ( !isset($request->usu_id) ) {

		$database = new Database();
		$database->query('SELECT usu_id FROM usuarios WHERE emp_id = :idEmpleado');
		$database->bind(':idEmpleado', $request->emp_id);
		$idEmpleado = $database->single();
		$database->closeConnection();

		if ( $idEmpleado != false ){
			$respuesta = json_encode( array('err' => true, 'mensaje' => 'Empleado ya tiene un usuario creado, no se puede crear otro'));
			$guardar = false;
		} else {

			$database = new Database();
			$database->query('SELECT MAX(usu_id)+1 AS CODIGO FROM usuarios');
			$id = $database->single();
			$database->closeConnection();

			$database = new Database();
			$database->query('INSERT INTO usuarios (usu_id, emp_id, usu_login, usu_clave, usu_estado) 
			VALUES (:id, :idEmpleado, :usuario, :clave, :estado)');
			$database->bind(':id', $id["CODIGO"]);
			$database->bind(':idEmpleado', $request->emp_id);
			$database->bind(':usuario',$request->usu_login);
			$database->bind(':clave', $request->usu_clave);
			$database->bind(':estado', $request->usu_estado);
		}
	
	}else {
		$database = new Database();
		$database->query('UPDATE usuarios SET 
						emp_id = :idEmpleado, 
						usu_login = :usuario, 
						usu_clave = :clave, 
						usu_estado = :estado
						WHERE usu_id = :id');
		$database->bind(':id', $request->usu_id);
		$database->bind(':idEmpleado', $request->emp_id);
		$database->bind(':usuario',$request->usu_login);
		$database->bind(':clave', $request->usu_clave);
		$database->bind(':estado', $request->usu_estado);
	
	}

	if ( $guardar ) {
		// $database->beginTransaction();
		$Hecho = $database->execute();
		// $database->cancelTransaction();
		$database->closeConnection();
		$respuesta = "";

		if ($Hecho == "1" && !isset($request->usu_id) ) {
			$respuesta = json_encode( array('id' => $id["CODIGO"]) );
		}elseif ($Hecho == "1") {
			// $respuesta = json_encode( array('err' => false, 'mensaje' => 'Registro Actualizado'));
			$respuesta = json_encode( array('id' => $request->usu_id) );
		}else{
			$respuesta = json_encode( array('err' => true, 'mensaje' => $Hecho));
		}
	}

} catch (\Throwable $th) {
	$respuesta = json_encode( array('err' => true, 'mensaje' => $th));
}

echo $respuesta;

?>