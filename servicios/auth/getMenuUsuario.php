<?php
require_once '../../vendor/autoload.php';
// DB configuration
include_once("../../classes/dbconfig.php");
include_once '../../classes/database.class.php';

use \Firebase\JWT\JWT;

// Retorna un json
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header("Access-Control-Allow-Headers: Origin, Content-Type, Accept");
// header("Access-Control-Allow-Methods: POST, PUT, OPTIONS");

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
    $voluntario_id = isset($_GET['id_vol']) ? intval($_GET['id_vol']) : 0;
    if ($usuario_id <= 0) {
        http_response_code(400);
        echo json_encode(["error" => "Falta el parámetro usuario_id"]);
        exit;
    }

    if ($voluntario_id <= 0) {

        $db = new Database();
        $db->query("SELECT fk_usuario_id,rol_id,modulo_nombre,submodulo_nombre,rol_nombre,rol_path FROM admin.tb_usuario_rol ur
                INNER JOIN admin.tb_roles r on r.rol_id = ur.fk_rol_id
                INNER JOIN admin.tb_submodulos s on s.submodulo_id = r.fk_submodulo_id
                INNER JOIN admin.tb_modulos m on m.modulo_id = s.fk_modulo_id WHERE rol_path IS NOT NULL AND fk_usuario_id = :fk_usuario_id");
        $db->bind(':fk_usuario_id', $usuario_id);
        $menusUsuario = $db->resultset();
        $db->closeConnection();

        $db = new Database();
        $db->query("SELECT fk_rol_id FROM admin.tb_usuario_rol WHERE fk_usuario_id = :fk_usuario_id");
        $db->bind(':fk_usuario_id', $usuario_id);
        $rolesUsuario = $db->resultset();
        $db->closeConnection();

        $grouped = array();
        // Reestructuración
        foreach ($menusUsuario as $item) {
            $modulo = $item['modulo_nombre'];

            if (!isset($grouped[$modulo])) {
                $grouped[$modulo] = [
                    'name' => $modulo,
                    'url' => '/' . explode('/', $item['rol_path'])[1], // ej: "/admin", "/sbj"
                    'icon' => 'fa fa-folder', // 👈 aquí puedes mapear íconos según el módulo
                    'children' => []
                ];
            }

            $grouped[$modulo]['children'][] = [
                'name' => $item['rol_nombre'],
                'url'  => $item['rol_path'],
                'icon' => 'nav-icon-bullet'
            ];
        }

        $roles = array_map(function ($item) {
            return $item['fk_rol_id'];
        }, $rolesUsuario);

        // Convertir en array numérico
        $navItems = array_values($grouped);
    } else {

        $grouped = array();
        $modulo = 'Voluntarios';

        $grouped[$modulo] = [
            'name' => $modulo,
            'url' => '/sbj', // ej: "/admin", "/sbj"
            'icon' => 'fa fa-folder', // 👈 aquí puedes mapear íconos según el módulo
            'children' => []
        ];

        $grouped[$modulo]['children'][] = [
            'name' => 'Actividades',
            'url'  => '/sbj/ubv-actividades',
            'icon' => 'nav-icon-bullet'
        ];

        $grouped[$modulo]['children'][] = [
            'name' => 'Asignacion',
            'url'  => '/sbj/ubv-asignacion',
            'icon' => 'nav-icon-bullet'
        ];

        // Convertir en array numérico
        $navItems = array_values($grouped);
    }

    echo json_encode($navItems, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(["error" => "Error interno del servidor: " . $e->getMessage()]);
    exit;
}


// Función utilitaria para respuestas JSON con código HTTP
function jsonResponse($data, int $httpCode = 200)
{
    http_response_code($httpCode);
    echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}
function prop($obj, $prop, $default = null)
{
    return property_exists($obj, $prop) ? $obj->$prop : $default;
}
// fin de funciones utilitarias
