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

    $database->query("SELECT * FROM tthh.tb_permisos_solicitados WHERE permiso_estado='SOLICITUD REGISTRADA' AND fk_personal_id = :id");
    $database->bind('id', $Id);
    $rows = $database->resultset();
    $database->closeConnection();

    $acumDias = 0;
    $acumHoras = 0;

    foreach ($rows as $row) {
        $acumDias += (double)($row["permiso_dias"]);
        $acumHoras += (double)($row["permiso_horas"]);
        $horas = (double)($row["permiso_horas"]);

        if (intval($row["permiso_horas"]) > 0) {
            $acumDias += ($horas / (double)($row["permiso_multiplicador"]) );
        }
    }

    echo json_encode( array( "dias" => $acumDias, "horas" => $acumHoras) );

    // echo json_encode($rows);

?>

