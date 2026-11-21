<?php
require_once __DIR__ . '/../../../classes/auth.php';
$auth = requireAuth();
require_once __DIR__ . '/../../../classes/api.php';
require_once __DIR__ . '/../../../classes/mantenimiento.php';
// POST -> crea un recurso; PUT (con recurso_id) -> lo actualiza
$metodo = apiMetodo(['POST', 'PUT']);
$r = apiCuerpoJson();
try {
    if (trim((string) prop($r, 'recurso_descripcion', '')) === '') {
        throw new ValidacionException('La descripción es obligatoria');
    }
    $db = new Database();
    if ($metodo === 'POST') {
        $db->query('INSERT INTO logistica.tb_recursosmantenimiento (fk_usuario_id, recurso_tipo, recurso_codigo, recurso_descripcion)
                    VALUES (:u, :tipo, :codigo, :descripcion) RETURNING recurso_id');
        $db->bind(':u', authUsuarioId());
    } else {
        if (!prop($r, 'recurso_id')) {
            throw new ValidacionException('Falta recurso_id');
        }
        $db->query('UPDATE logistica.tb_recursosmantenimiento SET recurso_tipo = :tipo, recurso_codigo = :codigo,
                    recurso_descripcion = :descripcion, recurso_estado = :estado WHERE recurso_id = :id RETURNING recurso_id');
        $db->bind(':id', (int) $r->recurso_id);
        $db->bind(':estado', prop($r, 'recurso_estado', 'ACTIVO'));
    }
    $db->bind(':tipo', prop($r, 'recurso_tipo'));
    $db->bind(':codigo', trim((string) prop($r, 'recurso_codigo', '')) ?: null);
    $db->bind(':descripcion', mb_strtoupper(trim($r->recurso_descripcion)));
    $fila = $db->single();
    if (!$fila) {
        jsonResponse(['error' => 'Recurso no encontrado'], 404);
    }
    jsonResponse(['msg' => 'Recurso guardado', 'id' => $fila['recurso_id']], $metodo === 'POST' ? 201 : 200);
} catch (Throwable $e) {
    apiError($e, 'No se pudo guardar el recurso');
}
