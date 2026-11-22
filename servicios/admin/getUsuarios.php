<?php
require_once __DIR__ . '/../../classes/auth.php';
$auth = requireAuth();
require_once __DIR__ . '/../../classes/usuarios.php';
// GET -> usuarios con su persona, perfil y si son funcionarios (nunca la clave); ?id=N -> uno
apiMetodo(['GET']);
try {
    $db = new Database();
    requirePermiso($db, 'SIS_USUARIOS', 'SIS_USUARIO_GESTIONAR', 'SIS_USUARIO_PRIVILEGIOS');
    $id = apiParamId();
    $filas = $id === null ? usrListar($db) : usrListar($db, 'AND u.usuario_id = :id', [':id' => $id]);
    if ($id !== null) {
        $filas ? jsonResponse($filas[0]) : jsonResponse(['error' => 'Usuario no encontrado'], 404);
    }
    jsonResponse($filas);
} catch (Throwable $e) {
    apiError($e, 'Error al obtener los usuarios');
}
