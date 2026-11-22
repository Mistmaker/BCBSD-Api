<?php
require_once __DIR__ . '/../../classes/auth.php';
$auth = requireAuth();
require_once __DIR__ . '/../../classes/usuarios.php';
// POST { usuario_id, roles: [rol_id...] } -> privilegios ADICIONALES del usuario (además de los de su perfil).
// Los que ya vienen del perfil no se guardan aparte. Privilegio: SIS_USUARIO_PRIVILEGIOS.
// Nadie puede quitarse a sí mismo la asignación de privilegios.
apiMetodo(['POST', 'PUT']);
$r = apiCuerpoJson();
$db = null;
try {
    $actual = authUsuarioId();
    $usuarioId = (int) prop($r, 'usuario_id', 0);
    $db = new Database();
    requirePermiso($db, 'SIS_USUARIO_PRIVILEGIOS');
    $roles = usrRolesValidos($db, (array) prop($r, 'roles', []));
    $db->beginTransaction();
    $db->query('SELECT 1 FROM admin.tb_usuarios WHERE usuario_id = :u FOR UPDATE');
    $db->bind(':u', $usuarioId);
    if (!$db->single()) {
        $db->cancelTransaction();
        jsonResponse(['error' => 'Usuario no encontrado'], 404);
    }
    $db->query('DELETE FROM admin.tb_usuario_rol WHERE fk_usuario_id = :u');
    $db->bind(':u', $usuarioId);
    $db->execute();
    if ($roles) {
        $db->query('INSERT INTO admin.tb_usuario_rol (fk_usuario_id, fk_rol_id)
                    SELECT :u, x FROM unnest(CAST(:r AS int[])) AS x
                     WHERE x NOT IN (SELECT pr.fk_rol_id FROM admin.tb_usuarios u JOIN admin.tb_perfil_rol pr ON pr.fk_perfil_id = u.fk_perfil_id
                                      JOIN admin.tb_perfiles p ON p.perfil_id = u.fk_perfil_id AND COALESCE(p.perfil_estado, \'ACTIVO\') = \'ACTIVO\'
                                     WHERE u.usuario_id = :u2)');
        $db->bind(':u', $usuarioId);
        $db->bind(':u2', $usuarioId);
        $db->bind(':r', '{' . implode(',', $roles) . '}');
        $db->execute();
    }
    if ($usuarioId === $actual) {
        usrNoBloquearse($db, $actual, 'SIS_USUARIO_PRIVILEGIOS', 'No puede quitarse a sí mismo la asignación de privilegios');
    }
    $db->endTransaction();
    jsonResponse(['msg' => 'Privilegios actualizados']);
} catch (Throwable $e) {
    $db?->cancelTransaction();
    apiError($e, 'Error al guardar los privilegios');
}
