<?php
// use Spipu\Html2Pdf\Html2Pdf;
// DB configuration
include_once("../../classes/dbconfig.php");
include_once '../../classes/database.class.php';

// DEFINIR LA ZONA HORARIA
date_default_timezone_set('America/Guayaquil');

// Retorna un json
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

try {

    $requestMethod = $_SERVER["REQUEST_METHOD"];
    $arrQueryStringParams = array();
    parse_str($_SERVER['QUERY_STRING'], $arrQueryStringParams);
    if (strtoupper($requestMethod) != 'GET') {
        $respuesta = json_encode(array('err' => false, 'mensaje' => 'Metodo no soportado'), JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
        echo $respuesta;
        exit;
    }

    $usuario_id = isset($_GET['id']) ? intval($_GET['id']) : 0;
    if ($usuario_id <= 0) {
        http_response_code(400);
        echo json_encode(["error" => "Falta el parámetro usuario_id"]);
        exit;
    }


    $sqlInter = "SELECT fk_rol_id FROM admin.tb_usuario_rol ";

    $database = new Database();
    $database->query($sqlInter);
    $rows = $database->resultset();


    // Obtener módulos
    $sqlModulos = "SELECT * FROM admin.tb_modulos ORDER BY modulo_nombre";
    $database->query($sqlModulos);
    $modulos = $database->resultset();

    $rows = [];
    foreach ($modulos as $mod) {
        $modulo = [
            "modulo_id" => $mod['modulo_id'],
            "modulo_nombre" => $mod['modulo_nombre'],
            "submodulos" => []
        ];

        // Submódulos del módulo actual
        $sqlSub = "SELECT * FROM admin.tb_submodulos WHERE fk_modulo_id = :modulo_id ORDER BY submodulo_nombre";
        $database->query($sqlSub);
        $database->bind(':modulo_id', $mod['modulo_id']);
        $submodulos = $database->resultset();

        foreach ($submodulos as $sub) {
            $submodulo = [
                "submodulo_id" => $sub['submodulo_id'],
                "submodulo_nombre" => $sub['submodulo_nombre'],
                "roles" => []
            ];

            // Roles del submódulo actual
            $sqlRoles = "
                SELECT r.rol_id, r.rol_nombre, r.rol_path,
                       CASE WHEN ur.fk_usuario_id IS NOT NULL THEN true ELSE false END AS asignado
                FROM admin.tb_roles r
                LEFT JOIN admin.tb_usuario_rol ur
                  ON ur.fk_rol_id = r.rol_id AND ur.fk_usuario_id = :usuario_id
                WHERE r.fk_submodulo_id = :submodulo_id
                ORDER BY r.rol_nombre
            ";

            $database->query($sqlRoles);
            $database->bind(':usuario_id', $usuario_id);
            $database->bind(':submodulo_id', $sub['submodulo_id']);
            $roles = $database->resultset();

            $submodulo["roles"] = $roles;
            $modulo["submodulos"][] = $submodulo;
        }

        $rows[] = $modulo;
    }
    $database->closeConnection();

    // limpia el parametro
    // $id = htmlentities($_GET['id']);
    // $database = new Database();
    // $database->query("SELECT fk_rol_id FROM admin.tb_usuario_rol WHERE fk_usuario_id = :fk_usuario_id");
    // $database->bind('fk_usuario_id', $id);
    // $rowsRol = $database->resultset();
    // $database->closeConnection();
    // $rows = array_map(function ($item) {
    //     return $item['fk_rol_id'];
    // }, $rowsRol);

    echo json_encode($rows);
} catch (Throwable $th) {
    // throw $th;
    $respuesta = json_encode(array('err' => false, 'mensaje' => $th), JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
    echo $respuesta;
}
