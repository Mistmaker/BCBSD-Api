<?php
require_once __DIR__ . '/../../classes/auth.php';
$auth = requireAuth();
require_once __DIR__ . '/../../classes/usuarios.php';
// GET -> perfiles con número de usuarios y de privilegios
// GET ?id=N -> perfil y árbol de privilegios con los del perfil marcados (asignado = true)
// GET ?arbol=1 -> árbol de privilegios sin marcar (para un perfil nuevo)
apiMetodo(['GET']);
try {
    $db = new Database();
    requirePermiso($db, 'SIS_PERFILES', 'SIS_PERFIL_GESTIONAR', 'SIS_USUARIOS', 'SIS_USUARIO_GESTIONAR');
    if (!empty($_GET['arbol'])) {
        jsonResponse(usrArbolPrivilegios($db));
    }
    $id = apiParamId();
    $db->query("SELECT p.perfil_id, p.perfil_nombre, p.perfil_descripcion, COALESCE(p.perfil_estado, 'ACTIVO') AS perfil_estado,
                       (SELECT count(*) FROM admin.tb_usuarios u WHERE u.fk_perfil_id = p.perfil_id)::int AS usuarios,
                       (SELECT count(*) FROM admin.tb_usuarios u WHERE u.fk_perfil_id = p.perfil_id AND COALESCE(u.usuario_estado, 'ACTIVO') = 'ACTIVO')::int AS usuarios_activos,
                       (SELECT count(*) FROM admin.tb_perfil_rol pr WHERE pr.fk_perfil_id = p.perfil_id)::int AS privilegios,
                       (SELECT count(*) FROM admin.tb_perfil_rol pr JOIN admin.tb_roles r ON r.rol_id = pr.fk_rol_id
                         WHERE pr.fk_perfil_id = p.perfil_id AND r.rol_path IS NOT NULL)::int AS pantallas
                  FROM admin.tb_perfiles p" . ($id !== null ? ' WHERE p.perfil_id = :id' : '') . ' ORDER BY p.perfil_nombre');
    if ($id !== null) {
        $db->bind(':id', $id);
    }
    $perfiles = $db->resultset();
    if ($id === null) {
        jsonResponse($perfiles);
    }
    if (!$perfiles) {
        jsonResponse(['error' => 'Perfil no encontrado'], 404);
    }
    $db->query('SELECT fk_rol_id FROM admin.tb_perfil_rol WHERE fk_perfil_id = :id');
    $db->bind(':id', $id);
    $roles = array_column($db->resultset(), 'fk_rol_id');
    jsonResponse($perfiles[0] + ['roles' => array_map('intval', $roles), 'privilegios_arbol' => usrArbolPrivilegios($db, $roles)]);
} catch (Throwable $e) {
    apiError($e, 'Error al obtener los perfiles');
}
