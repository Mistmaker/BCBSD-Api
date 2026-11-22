<?php
require_once __DIR__ . '/../../classes/auth.php';
$auth = requireAuth();
require_once __DIR__ . '/../../classes/usuarios.php';
// GET ?id=USUARIO -> árbol de privilegios del usuario: asignado = privilegio adicional del usuario,
//                    del_perfil = viene de su perfil (se administra en Perfiles). Además: perfil del usuario.
apiMetodo(['GET']);
try {
    $usuarioId = apiParamId();
    if ($usuarioId === null) {
        jsonResponse(['error' => 'Falta el usuario (?id=)'], 400);
    }
    $db = new Database();
    requirePermiso($db, 'SIS_USUARIO_PRIVILEGIOS', 'SIS_USUARIO_GESTIONAR', 'SIS_USUARIOS');
    $db->query('SELECT fk_rol_id FROM admin.tb_usuario_rol WHERE fk_usuario_id = :u');
    $db->bind(':u', $usuarioId);
    $adicionales = array_column($db->resultset(), 'fk_rol_id');
    $db->query('SELECT pr.fk_rol_id FROM admin.tb_usuarios u JOIN admin.tb_perfil_rol pr ON pr.fk_perfil_id = u.fk_perfil_id
                  JOIN admin.tb_perfiles p ON p.perfil_id = u.fk_perfil_id AND COALESCE(p.perfil_estado, \'ACTIVO\') = \'ACTIVO\'
                 WHERE u.usuario_id = :u');
    $db->bind(':u', $usuarioId);
    $delPerfil = array_column($db->resultset(), 'fk_rol_id');
    jsonResponse(usrArbolPrivilegios($db, $adicionales, $delPerfil));
} catch (Throwable $e) {
    apiError($e, 'Error al obtener los privilegios');
}
