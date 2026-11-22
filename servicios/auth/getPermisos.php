<?php
require_once __DIR__ . '/../../classes/auth.php';
$auth = requireAuth();
require_once __DIR__ . '/../../classes/api.php';
// GET -> privilegios ACTUALES del usuario autenticado (no dependen del momento del login):
//   { permisos: [rol_codigo, ...], rutas: [rol_path, ...] }
// El front los usa para mostrar botones y abrir pantallas; así un privilegio asignado se aplica sin volver a iniciar sesión.
apiMetodo(['GET']);
try {
    $usuario = authUsuarioId();
    if ($usuario === null) {
        jsonResponse(['permisos' => [], 'rutas' => []]);
    }
    $db = new Database();
    $db->query('SELECT DISTINCT r.rol_codigo, r.rol_path FROM admin.tb_usuario_rol ur JOIN admin.tb_roles r ON r.rol_id = ur.fk_rol_id
                 WHERE ur.fk_usuario_id = :u');
    $db->bind(':u', $usuario);
    $filas = $db->resultset();
    jsonResponse([
        'permisos' => array_values(array_unique(array_filter(array_column($filas, 'rol_codigo')))),
        'rutas' => array_values(array_unique(array_filter(array_column($filas, 'rol_path')))),
    ]);
} catch (Throwable $e) {
    apiError($e, 'Error al obtener los privilegios');
}
