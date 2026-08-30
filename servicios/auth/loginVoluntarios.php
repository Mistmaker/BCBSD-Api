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
header("Access-Control-Allow-Methods: POST, PUT, OPTIONS");

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

// Manejar la preflight request (OPTIONS)
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    // Respondemos con éxito sin continuar ejecución
    http_response_code(200);
    exit();
}


// Parámetros de configuración
$key = JWT_SECPWD;
$alg = 'HS256';

$input = json_decode(file_get_contents("php://input"), true);
$usuario = $input['usuario'] ?? '';
$password = $input['password'] ?? '';

$db = new Database();
$db->query("SELECT voluntario_id, voluntario_pass, voluntario_doc_identidad, voluntario_nombres, voluntario_apellidos FROM subjefatura.tb_voluntarios WHERE voluntario_doc_identidad = :usuario");
$db->bind(':usuario', $usuario);
$usuarioDb = $db->single();
$db->closeConnection();

// if ($usuarioDb && password_verify($password, $usuarioDb['usuario_pass'])) {
if ($usuarioDb && $usuarioDb['voluntario_pass'] == md5($password)) {
    $payload = [
        'iss' => 'cbsd-login-api',
        'iat' => time(),
        'exp' => time() + 3600,
        'sub' => $usuarioDb['voluntario_id'],
        'nombre' => $usuarioDb['voluntario_doc_identidad'] . ' - ' . $usuarioDb['voluntario_nombres'] . ' ' . $usuarioDb['voluntario_apellidos'],
        'modulo' => 'voluntarios'
    ];

    $jwt = JWT::encode($payload, $key, $alg);

    $grouped = array();


    /* MENU A CONVERTIR EN ARRAY
    [
        {
            "name": "Subjefatura",
            "url": "/sbj",
            "icon": "fa fa-folder",
            "children": [
                {
                    "name": "Voluntarios",
                    "url": "/sbj/ubv-voluntarios",
                    "icon": "nav-icon-bullet"
                },
                {
                    "name": "UBV Actividades",
                    "url": "/sbj/ubv-actividades",
                    "icon": "nav-icon-bullet"
                }
            ]
        }
    ]
    */

    $modulo = 'Voluntarios';

    $grouped[$modulo] = [
        'name' => $modulo,
        'url' => '/sbj' , // ej: "/admin", "/sbj"
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
    
    $grouped[$modulo]['children'][] = [
        'name' => 'Eventos',
        'url'  => '/sbj/ubv-eventos',
        'icon' => 'fa fa-calendar'
    ];

    // Convertir en array numérico
    $navItems = array_values($grouped);

    echo json_encode([
        'token' => $jwt,
        'usuario' => [
            'usuario_id' => $usuarioDb['voluntario_id'],
            'voluntario_id' => $usuarioDb['voluntario_id'],
            'nombre' => $usuarioDb['voluntario_doc_identidad'] . ' - ' . $usuarioDb['voluntario_nombres'] . ' ' . $usuarioDb['voluntario_apellidos'],
            'menus' => $navItems
        ]
    ]);
} else {
    http_response_code(401);
    echo json_encode(['error' => 'Credenciales inválidas']);
}
