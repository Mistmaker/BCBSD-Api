<?php
require_once __DIR__ . '/../../classes/auth.php';
$auth = requireAuth();
require_once '../../vendor/autoload.php';
// DB configuration
include_once("../../classes/dbconfig.php");
include_once '../../classes/database.class.php';
require_once __DIR__ . '/../../classes/api.php';

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

    // El menú se arma con el usuario del TOKEN (no con ?id), para que nadie pueda pedir el menú de otro usuario.
    // Los parámetros ?id e ?id_vol se mantienen solo por compatibilidad con el front actual.
    $tipoToken = $auth->tipo ?? 'usuario';
    $usuario_id = $tipoToken === 'usuario' ? (int) $auth->sub : (isset($_GET['id']) ? intval($_GET['id']) : 0);
    $voluntario_id = $tipoToken === 'voluntario' ? (int) $auth->sub : 0;
    if ($usuario_id <= 0) {
        http_response_code(400);
        echo json_encode(["error" => "Falta el parámetro usuario_id"]);
        exit;
    }

    if ($voluntario_id <= 0) {
        // Menú = pantallas (privilegios con ruta) del perfil del usuario + sus privilegios adicionales
        $db = new Database();
        $navItems = menuUsuario(privilegiosUsuario($db, $usuario_id));
        $db->closeConnection();
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
