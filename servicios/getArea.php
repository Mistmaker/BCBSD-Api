<?php
// Retorna un json
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
// Define configuration
include_once("../config.php");

// Include database class
include '../classes/database.class.php';

if (!isset($_GET['id'])) {
	echo json_encode( array('err' => true,'mensaje'=>"Falta el Id") );
	die;
}

// limpia el parametro
$Id = htmlentities($_GET['id']);

$database = new Database();

$database->query("SELECT * FROM areas WHERE area_id = :id");
$database->bind('id', $Id);
$rows = $database->single();
$database->closeConnection();

if ( $rows ){
	echo json_encode($rows);
}else{
	echo json_encode( array('err' => true,'mensaje'=>"Id no existe") );
}