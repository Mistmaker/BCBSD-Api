<?php
require_once __DIR__ . '/../../classes/auth.php';
$auth = requireAuth();
require_once __DIR__ . '/../../classes/usuarios.php';
// POST -> crea; PUT (con perfil_id) -> edita: { perfil_nombre, perfil_descripcion, perfil_estado, roles: [rol_id...] }
// Los usuarios del perfil reciben (o pierden) estos privilegios de inmediato, sin tocar sus privilegios adicionales.
// Privilegio: SIS_PERFIL_GESTIONAR. No se puede dejar sin administración de perfiles el propio perfil del usuario conectado.
$metodo = apiMetodo(['POST', 'PUT']);
$p = apiCuerpoJson();
$db = null;
try {
    $actual = authUsuarioId();
    if ($actual === null) {
        jsonResponse(['error' => 'No autorizado'], 403);
    }
    $nombre = mb_strtoupper(trim(preg_replace('/\s+/', ' ', (string) prop($p, 'perfil_nombre', ''))));
    if (mb_strlen($nombre) < 3) {
        throw new ValidacionException('Ingrese el nombre del perfil');
    }
    $estado = strtoupper((string) prop($p, 'perfil_estado', 'ACTIVO'));
    if (!in_array($estado, USR_ESTADOS, true)) {
        throw new ValidacionException('Estado inválido');
    }
    $db = new Database();
    requirePermiso($db, 'SIS_PERFIL_GESTIONAR');
    $roles = usrRolesValidos($db, (array) prop($p, 'roles', []));
    $db->beginTransaction();
    $id = (int) prop($p, 'perfil_id', 0);
    $db->query('SELECT perfil_id FROM admin.tb_perfiles WHERE upper(trim(perfil_nombre)) = :n AND perfil_id <> :id LIMIT 1');
    $db->bind(':n', $nombre);
    $db->bind(':id', $id);
    if ($db->single()) {
        throw new ValidacionException("Ya existe un perfil llamado \"$nombre\"");
    }
    if ($metodo === 'PUT') {
        $db->query('UPDATE admin.tb_perfiles SET perfil_nombre = :n, perfil_descripcion = :d, perfil_estado = :e WHERE perfil_id = :id RETURNING perfil_id');
    } else {
        $db->query('INSERT INTO admin.tb_perfiles (perfil_nombre, perfil_descripcion, perfil_estado, fk_usuario_id) VALUES (:n, :d, :e, :u) RETURNING perfil_id');
        $db->bind(':u', $actual);
    }
    $db->bind(':n', $nombre);
    $db->bind(':d', trim((string) prop($p, 'perfil_descripcion', '')) ?: null);
    $db->bind(':e', $estado);
    if ($metodo === 'PUT') {
        $db->bind(':id', $id);
    }
    $fila = $db->single();
    if (!$fila) {
        $db->cancelTransaction();
        jsonResponse(['error' => 'Perfil no encontrado'], 404);
    }
    $id = (int) $fila['perfil_id'];
    $db->query('DELETE FROM admin.tb_perfil_rol WHERE fk_perfil_id = :id');
    $db->bind(':id', $id);
    $db->execute();
    if ($roles) {
        $db->query('INSERT INTO admin.tb_perfil_rol (fk_perfil_id, fk_rol_id) SELECT :id, unnest(CAST(:r AS int[]))');
        $db->bind(':id', $id);
        $db->bind(':r', '{' . implode(',', $roles) . '}');
        $db->execute();
    }
    usrNoBloquearse($db, $actual, 'SIS_PERFIL_GESTIONAR', 'Ese cambio le quitaría a usted la administración de perfiles; asígnese antes el privilegio como adicional o pida a otro administrador que lo haga');
    $db->endTransaction();
    jsonResponse(['msg' => $metodo === 'PUT' ? 'Perfil actualizado' : 'Perfil creado', 'id' => $id], $metodo === 'PUT' ? 200 : 201);
} catch (Throwable $e) {
    $db?->cancelTransaction();
    apiError($e, 'Error al guardar el perfil');
}
