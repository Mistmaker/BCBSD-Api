<?php
require_once __DIR__ . '/../../classes/auth.php';
$auth = requireAuth();
require_once __DIR__ . '/../../classes/usuarios.php';
// POST { usuario_id, clave } -> el administrador restablece la clave de un usuario (SIS_USUARIO_GESTIONAR);
//      el usuario deberá cambiarla al entrar (usuario_cambiar_pass).
// POST { clave_actual, clave } (sin usuario_id) -> el usuario conectado cambia su propia clave.
apiMetodo(['POST']);
$c = apiCuerpoJson();
try {
    $actual = authUsuarioId();
    if ($actual === null) {
        jsonResponse(['error' => 'No autorizado'], 403);
    }
    $db = new Database();
    $propia = !prop($c, 'usuario_id') || (int) $c->usuario_id === $actual && prop($c, 'clave_actual') !== null;
    $id = $propia ? $actual : (int) $c->usuario_id;
    if (!$propia) {
        requirePermiso($db, 'SIS_USUARIO_GESTIONAR');
    }
    $db->query('SELECT usuario_login, usuario_pass FROM admin.tb_usuarios WHERE usuario_id = :id');
    $db->bind(':id', $id);
    $usuario = $db->single();
    if (!$usuario) {
        jsonResponse(['error' => 'Usuario no encontrado'], 404);
    }
    if ($propia && !usrVerificarClave((string) prop($c, 'clave_actual', ''), $usuario['usuario_pass'])[0]) {
        throw new ValidacionException('La clave actual no es correcta');
    }
    $clave = (string) prop($c, 'clave', '');
    if ($error = usrErrorClave($clave, $usuario['usuario_login'])) {
        throw new ValidacionException($error);
    }
    if ($propia && usrVerificarClave($clave, $usuario['usuario_pass'])[0]) {
        throw new ValidacionException('La clave nueva debe ser distinta de la actual');
    }
    $db->query('UPDATE admin.tb_usuarios SET usuario_pass = :h, usuario_cambiar_pass = :cp WHERE usuario_id = :id');
    $db->bind(':h', usrHashClave($clave));
    $db->bind(':cp', !$propia, PDO::PARAM_BOOL);
    $db->bind(':id', $id);
    $db->execute();
    jsonResponse(['msg' => $propia ? 'Su clave fue actualizada' : 'Clave restablecida; el usuario deberá cambiarla al entrar']);
} catch (Throwable $e) {
    apiError($e, 'Error al cambiar la clave');
}
