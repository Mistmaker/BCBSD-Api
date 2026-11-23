<?php
require_once __DIR__ . '/../../../classes/auth.php';
$auth = requireAuth();
require_once __DIR__ . '/../../../classes/borrado.php';
// DELETE ?id=N -> borrado lógico del voluntario (voluntario_estado = ELIMINADO). Privilegio: SBJ_VOLUNTARIOS.
apiMetodo(['DELETE']);
try {
    $id = apiParamId() ?? jsonResponse(['error' => 'Falta el id'], 400);
    $db = new Database();
    requirePermiso($db, 'SBJ_VOLUNTARIOS');
    borrarLogico($db, 'subjefatura.tb_voluntarios', 'voluntario_id', $id, 'voluntario_estado', 'ELIMINADO');
} catch (Throwable $e) {
    apiError($e, 'Error al eliminar el voluntario');
}
