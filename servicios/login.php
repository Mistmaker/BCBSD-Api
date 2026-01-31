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

date_default_timezone_set('America/Bogota');

// echo json_encode($request);

try {
    $database = new Database();
    $database->query("SELECT u.usuario_id, u.usuario_login, p.persona_nombres, p.persona_apellidos FROM admin.tb_usuarios u INNER JOIN resources.tb_personas p ON u.fk_persona_id = p.persona_id WHERE u.usuario_login= :usuario AND u.usuario_pass= :clave AND u.usuario_estado='ACTIVO'");
    $database->bind('usuario', $request->usu_login);
    $database->bind('clave', md5($request->usu_clave));
    $rows = $database->single();
    $database->closeConnection();

    if ($rows) {
        $rows['token'] = $rows['usuario_id'] . date("YmdHis");
        $rows['idUsuario'] = $rows['usuario_id'];
        $rows['funcionario'] = $rows['persona_nombres'] . ' ' . $rows['persona_apellidos'];
        $rows['ExpToken'] = date("YmdHis", strtotime('1 hour'));
        $respuesta =  json_encode($rows);
    } else {
        $respuesta =  json_encode(array('err' => true, 'mensaje' => "Usuario o contraseña no válidos"));
    }
} catch (\Throwable $th) {
    //throw $th;
    $respuesta = json_encode(array('err' => true, 'mensaje' => $th));
}

echo $respuesta;
