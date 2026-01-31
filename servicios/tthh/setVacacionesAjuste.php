<?php
// Define configuration
include_once("../../config.php");

// Include database class
include '../../classes/database.class.php';

// Retiorna un json
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header("Access-Control-Allow-Headers: Origin, X-Requested-With, Content-Type, Accept");
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE');

$postdata = file_get_contents("php://input");
$request = json_decode($postdata);

date_default_timezone_set('America/Bogota');

// echo json_encode($request);

try {

    // echo json_encode($request);

    $hoy = date("Y-m-d H:i:s");
    $hoy2 = date("Y-m-d");

    $database = new Database();
		
    $database->query("UPDATE tthh.tb_vacaciones_generadas SET 
            vacacion_detalle = CONCAT(vacacion_detalle,' ', ' | Ajuste de Vacaciones [dias=', vacacion_dias_generados, ' meses=', vacacion_meses_generados, ' realizado por: ', '".$request->usuario->funcionario."',']')
						WHERE vacacion_estado = 'ACTIVO' AND fk_personal_id = :id");
		$database->bind(':id', $request->idFuncionario);
    $Hecho = $database->execute();

    $database->query("UPDATE tthh.tb_vacaciones_generadas SET 
            vacacion_dias_generados = 0, 
            vacacion_meses_generados = 0,
            vacacion_estado = 'INACTIVO'
						WHERE vacacion_estado = 'ACTIVO' AND fk_personal_id = :id");
		$database->bind(':id', $request->idFuncionario);
    $Hecho = $database->execute();


    $database->query("SELECT * FROM tthh.tb_personal p INNER JOIN tthh.tb_personal_puestos pu ON pu.fk_personal_id = p.personal_id INNER JOIN resources.tb_personas pe ON pe.persona_id = p.fk_persona_id INNER JOIN tthh.tb_puestos pue ON pu.fk_puesto_id = pue.puesto_id WHERE pu.ppersonal_estado= 'EN FUNCIONES' AND personal_id = :id");
    $database->bind('id', $request->idFuncionario);
    $datosFuncionario = $database->single();

    // personal_fecha_ingreso -> fecha de contrato
    //echo json_encode($datosFuncionario);

    $diasAjuste = $request->diasAjuste + $request->diasVacaciones + $request->diasPermisos;
    $detalleVacaciones = "Ajuste de Vacaciones para que el funcionario tenga ".$request->diasAjuste." dias de vacaciones | realizado por ".$request->usuario->funcionario. " el: ". $hoy2;

    $database->query("INSERT INTO tthh.tb_vacaciones_generadas(
        vacacion_registro,
        vacacion_estado,
        fk_usuario_id,
        fk_personal_id,
        vacacion_periodo_inicio,
        vacacion_periodo_cierre,
        vacacion_dias,
        vacacion_meses,
        vacacion_dias_generados,
        vacacion_meses_generados,
        vacacion_detalle,
        vacacion_remuneracion)
      VALUES (
        :hoy,
        'ACTIVO',
        :idUsuario,
        :idFuncionario,
        :vacacion_periodo_inicio,
        :vacacion_periodo_cierre,
        :vacacion_dias,
        :vacacion_meses,
        :vacacion_dias_generados,
        :vacacion_meses_generados,
        :vacacion_detalle,
        :vacacion_remuneracion
      )");
      $database->bind('hoy', $hoy);
      $database->bind('idUsuario', $request->usuario->idUsuario);
      $database->bind('idFuncionario', $request->idFuncionario);
      $database->bind('vacacion_periodo_inicio', $datosFuncionario["personal_fecha_ingreso"]);
      $database->bind('vacacion_periodo_cierre', $hoy2);
      $database->bind('vacacion_dias', $request->diasAjuste);
      $database->bind('vacacion_meses', 0);
      $database->bind('vacacion_dias_generados', 0);
      $database->bind('vacacion_meses_generados', $diasAjuste);
      $database->bind('vacacion_detalle', $detalleVacaciones);
      $database->bind('vacacion_remuneracion', 0);
      $Hecho = $database->execute();

    $database->closeConnection();

    if ($Hecho == "1") {
			$respuesta = json_encode( array('err' => false, 'mensaje' => 'Registro Actualizado'));
			// $respuesta = json_encode(array('id' => $request->area_id));
		} else {
			$respuesta = json_encode(array('err' => true, 'mensaje' => $Hecho));
		}

		// $database = new Database();
    // $database->query("SELECT usu_id,'' as ExpToken FROM usuarios WHERE usu_login= :usuario AND usu_clave= :clave AND usu_estado='1'");
    // $database->bind('usuario', $request->usu_login);
    // $database->bind('clave', $request->usu_clave);
    // $rows = $database->single();
    // $database->closeConnection();
    
    // if ( $rows ){
    //     $rows['token'] = $rows['usu_id'].date("YmdHis");
    //     $rows['ExpToken'] = date("YmdHis", strtotime('1 hour'));
    //     $respuesta =  json_encode($rows);
    // }else{
    //     $respuesta =  json_encode( array('err' => true,'mensaje'=>"Usuario no existe") );
    // }

} catch (\Throwable $th) {
	//throw $th;
	$respuesta = json_encode( array('err' => true, 'mensaje' => $th));
}

 echo $respuesta;

?>