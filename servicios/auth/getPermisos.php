<?php
require_once __DIR__ . '/../../classes/auth.php';
$auth = requireAuth();
require_once __DIR__ . '/../../classes/api.php';
// GET -> privilegios ACTUALES (perfil + adicionales) del usuario autenticado (no dependen del momento del login):
//   { permisos: [rol_codigo, ...], rutas: [rol_path, ...] }
// El front los usa para mostrar botones y abrir pantallas; así un privilegio asignado se aplica sin volver a iniciar sesión.
apiMetodo(['GET']);
try {
    $usuario = authUsuarioId();
    if ($usuario === null) {
        jsonResponse(['permisos' => [], 'rutas' => []]);
    }
    $db = new Database();
    $filas = privilegiosUsuario($db, $usuario); // perfil + adicionales
    jsonResponse([
        'permisos' => array_values(array_unique(array_filter(array_column($filas, 'rol_codigo')))),
        'rutas' => array_values(array_unique(array_filter(array_column($filas, 'rol_path')))),
    ]);
} catch (Throwable $e) {
    apiError($e, 'Error al obtener los privilegios');
}
