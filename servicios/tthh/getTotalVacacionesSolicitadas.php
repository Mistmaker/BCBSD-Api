<?php
    // Retorna un json
    header('Content-Type: application/json');
    header('Access-Control-Allow-Origin: *');
    // Define configuration
    include_once("../../config.php");

    // Include database class
    include '../../classes/database.class.php';

    if (!isset($_GET['id'])) {
        echo json_encode( array('err' => true,'mensaje'=>"Falta el Id") );
        die;
    }

    // limpia el parametro
    $Id = htmlentities($_GET['id']);

    $database = new Database();

    $database->query("SELECT * FROM tthh.tb_vacaciones_solicitadas WHERE vacacion_estado='SOLICITUD REGISTRADA' AND fk_personal_id = :id");
    $database->bind('id', $Id);
    $rows = $database->resultset();
    $database->closeConnection();

    $acum = 0;

    foreach ($rows as $row) {
        $acum += intval($row["vacacion_dias"]);
    }

    echo json_encode( array( "dias" => $acum) );

    // echo json_encode($rows);

?>

