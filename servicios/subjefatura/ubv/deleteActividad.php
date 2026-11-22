<?php
require_once __DIR__ . '/../../../classes/auth.php';
$auth = requireAuth();
require_once __DIR__ . '/../../../classes/borrado.php';
// DELETE ?id=N -> borrado lógico (actividad_estado = ELIMINADA).
// Un voluntario solo puede eliminar las suyas; un usuario administrativo necesita SBJ_UBV_ACTIVIDADES.
apiMetodo(['DELETE']);
try {
    $id = apiParamId() ?? jsonResponse(['error' => 'Falta el id'], 400);
    $db = new Database();
    if (($auth->tipo ?? 'usuario') === 'voluntario') {
        borrarLogico($db, 'subjefatura.tb_voluntarios_actividades', 'actividad_id', $id, 'actividad_estado', 'ELIMINADA', 'AND fk_voluntario_id = :v', [':v' => (int) $auth->sub]);
    }
    requirePermiso($db, 'SBJ_UBV_ACTIVIDADES');
    borrarLogico($db, 'subjefatura.tb_voluntarios_actividades', 'actividad_id', $id, 'actividad_estado', 'ELIMINADA');
} catch (Throwable $e) {
    apiError($e, 'Error al eliminar la actividad');
}
