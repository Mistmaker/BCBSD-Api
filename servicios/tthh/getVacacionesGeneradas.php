<?php
    // Retorna un json
    header('Content-Type: application/json');
    header('Access-Control-Allow-Origin: *');
    // Define configuration
    include_once("../../config.php");

    // Include database class
    include '../../classes/database.class.php';

    $database = new Database();

    $database->query("SELECT v.vacacion_id, v.vacacion_registro, v.vacacion_estado, v.fk_usuario_id, v.fk_personal_id, v.vacacion_periodo_inicio, v.vacacion_periodo_cierre, v.vacacion_dias, v.vacacion_meses, v.vacacion_dias_generados, v.vacacion_meses_generados, (v.vacacion_dias_generados + v.vacacion_meses_generados) as vacaciones_total_dias, v.vacacion_detalle, v.vacacion_remuneracion, c.cargo_direccion, c.cargo_puesto, c.cargo_remuneracion, CONCAT(pe.persona_nombres, ' ' ,pe.persona_apellidos) AS funcionario FROM tthh.tb_vacaciones_generadas v INNER JOIN tthh.tb_personal p ON p.personal_id = v.fk_personal_id INNER JOIN tthh.tb_personal_cargos c ON c.fk_personal_id = p.personal_id INNER JOIN resources.tb_personas pe ON pe.persona_id = p.fk_persona_id WHERE v.vacacion_estado = 'ACTIVO'");
    $rows = $database->resultset();
    $database->closeConnection();

    echo json_encode($rows);

?>

