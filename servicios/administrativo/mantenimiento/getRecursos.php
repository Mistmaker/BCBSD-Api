<?php
require_once __DIR__ . '/../../../classes/auth.php';
$auth = requireAuth();
require_once __DIR__ . '/../../../classes/api.php';
require_once __DIR__ . '/../../../classes/mantenimiento.php';
// GET            -> catálogo de recursos de mantenimiento
// GET ?id=N      -> un recurso
apiMetodo(['GET']);
try {
    $db = new Database();
    $id = apiParamId();
    if ($id !== null) {
        $db->query('SELECT * FROM logistica.tb_recursosmantenimiento WHERE recurso_id = :id');
        $db->bind(':id', $id);
        $fila = $db->single();
        $fila ? jsonResponse($fila) : jsonResponse(['error' => 'Recurso no encontrado'], 404);
    }
    $db->query('SELECT * FROM logistica.tb_recursosmantenimiento ORDER BY recurso_descripcion');
    jsonResponse($db->resultset());
} catch (Throwable $e) {
    apiError($e, 'Error al obtener recursos');
}
