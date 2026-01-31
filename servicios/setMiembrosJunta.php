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

$base7 = false;

// echo json_encode($request);
// echo count($request);

try {

	$database = new Database();
	$database->query('DELETE FROM juntamiembro');
	$database->execute();
	$database->closeConnection();

	$database = new Database();
	$database->query("SELECT *, ( SELECT COUNT(jun_id) FROM juntas WHERE juntas.ins_id = instituciones.ins_id ) as 'juntas' FROM instituciones WHERE ins_recinto='S' AND ( SELECT COUNT(jun_id) FROM juntas WHERE juntas.ins_id = instituciones.ins_id ) > 0");
	$recintos = $database->resultset();
	$database->closeConnection();

	foreach ($recintos as $recinto) {
		$database = new Database();
		$database->query("SELECT 
							p.per_id,p.tpe_id,p.zon_id,pa.par_id,c.can_id,p.per_apellido,p.per_nombre,p.per_genero, z.zon_descripcion,pa.par_nombre,c.can_nombre FROM personas p INNER JOIN zonas z ON z.zon_id = p.zon_id INNER JOIN parroquias pa ON pa.par_id = z.par_id INNER JOIN cantones c ON c.can_id = pa.can_id 
						  WHERE p.per_id NOT IN (SELECT per_id FROM empleados) 
						  AND p.per_id NOT IN (SELECT per_id FROM juntamiembro) 
						  AND (TIMESTAMPDIFF(year,`per_fechanacimiento`, now() )) > 18
						  AND per_genero = 'M'
						  AND p.zon_id = :idZona");
		$database->bind('idZona', $recinto["zon_id"]);
		$miembrosM = $database->resultset();
		$database->closeConnection();

		$database = new Database();
		$database->query("SELECT 
							p.per_id,p.tpe_id,p.zon_id,pa.par_id,c.can_id,p.per_apellido,p.per_nombre,p.per_genero, z.zon_descripcion,pa.par_nombre,c.can_nombre FROM personas p INNER JOIN zonas z ON z.zon_id = p.zon_id INNER JOIN parroquias pa ON pa.par_id = z.par_id INNER JOIN cantones c ON c.can_id = pa.can_id 
						  WHERE p.per_id NOT IN (SELECT per_id FROM empleados) 
						  AND p.per_id NOT IN (SELECT per_id FROM juntamiembro) 
						  AND (TIMESTAMPDIFF(year,`per_fechanacimiento`, now() )) > 18
						  AND per_genero = 'F'
						  AND p.zon_id = :idZona");
		$database->bind('idZona', $recinto["zon_id"]);
		$miembrosF = $database->resultset();
		$database->closeConnection();

		$database = new Database();
		$database->query("SELECT * FROM juntas WHERE jun_genero='M' AND ins_id = :id");
		$database->bind('id', $recinto["ins_id"]);
		$juntasM = $database->resultset();
		$database->closeConnection();

		$database = new Database();
		$database->query("SELECT * FROM juntas WHERE jun_genero='F' AND ins_id = :id");
		$database->bind('id', $recinto["ins_id"]);
		$juntasF = $database->resultset();
		$database->closeConnection();

		$miembrosRequeridos = $recinto["juntas"] * 7;

		if (count($miembrosM) >= $miembrosRequeridos && count($miembrosF) >= $miembrosRequeridos) {
			$base7 = true;
		}

		// 1 Primer Vocal / Presidente
		// 2 Segundo Vocal  
		// 3 Tercer Vocal  
		// 4 Secretario  
		// 5 Primer Vocal Suplente  
		// 6 Segundo Vocal Suplente  
		// 7 Tercer Vocal Suplente 
		if ($base7) {

			// echo json_encode($miembrosM);
			// Asignación de cargo a la junta
			foreach ($juntasM as $mesa) {
				if (isset($mesa)) {
					for ($i = 1; $i <= 7; $i++) {
						$persona = array_pop($miembrosM);
						// echo json_encode($persona);

						$database = new Database();
						$database->query('SELECT MAX(jmi_id)+1 AS CODIGO FROM juntamiembro');
						$id = $database->single();
						$database->closeConnection();

						if ($id["CODIGO"] === null) {
							$id["CODIGO"] = 1;
						}

						$database = new Database();
						$database->query('INSERT INTO juntamiembro (jmi_id, cju_id, jun_id, per_id) 
										  VALUES (:id, :idCargo, :idJunta, :idPersona)');
						$database->bind(':id', $id["CODIGO"]);
						$database->bind(':idCargo', $i);
						$database->bind(':idJunta', $mesa["jun_id"]);
						$database->bind(':idPersona', $persona["per_id"]);

						$database->execute();
						$database->closeConnection();
					}
				}
			}

			foreach ($juntasF as $mesa) {
				if (isset($mesa)) {
					for ($i = 1; $i <= 7; $i++) {
						$persona = array_pop($miembrosM);
						// echo json_encode($persona);

						$database = new Database();
						$database->query('SELECT MAX(jmi_id)+1 AS CODIGO FROM juntamiembro');
						$id = $database->single();
						$database->closeConnection();

						if ($id["CODIGO"] === null) {
							$id["CODIGO"] = 1;
						}

						$database = new Database();
						$database->query('INSERT INTO juntamiembro (jmi_id, cju_id, jun_id, per_id) 
										  VALUES (:id, :idCargo, :idJunta, :idPersona)');
						$database->bind(':id', $id["CODIGO"]);
						$database->bind(':idCargo', $i);
						$database->bind(':idJunta', $mesa["jun_id"]);
						$database->bind(':idPersona', $persona["per_id"]);

						$database->execute();
						$database->closeConnection();
					}
				}
			}

			$respuesta = json_encode(array('err' => false, 'mensaje' => 'Asignados los miembros de junta receptora del voto a ' . count($recintos) . ' recientos'));
		} else {
			$database = new Database();
			$database->query('DELETE FROM juntamiembro');
			$database->execute();
			$database->closeConnection();
			$respuesta = json_encode(array('err' => true, 'mensaje' => 'No hay suficientes personas para asignarlas como miebros de junta receptora del voto'));
		}
	}
} catch (\Throwable $th) {
	if (!$base7) {
		$respuesta = json_encode(array('err' => true, 'mensaje' => $th));
	}
}

echo $respuesta;
