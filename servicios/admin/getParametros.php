<?php
require_once __DIR__ . '/../../classes/auth.php';
$auth = requireAuth();
require_once __DIR__ . '/../../classes/parametros.php';
// GET -> { parametros: [...], tipos: {TIPO: etiqueta}, puede_editar, puede_editar_protegidos }
// GET ?historial=param_id -> últimos 20 cambios del parámetro. Privilegio: SIS_PARAMETROS.
apiMetodo(['GET']);
try {
    $db = new Database();
    requirePermiso($db, 'SIS_PARAMETROS');
    if (isset($_GET['historial'])) {
        $db->query('SELECT h.historial_id, h.historial_valor_anterior, h.historial_valor_nuevo, h.historial_fecha::text AS historial_fecha,
                           u.usuario_login FROM admin.tb_params_historial h LEFT JOIN admin.tb_usuarios u ON u.usuario_id = h.fk_usuario_id
                     WHERE h.fk_param_id = :id ORDER BY h.historial_fecha DESC, h.historial_id DESC LIMIT 20');
        $db->bind(':id', (int) $_GET['historial']);
        jsonResponse($db->resultset());
    }
    $permisos = permisosUsuario($db);
    $db->query('SELECT admin.fn_es_administrador(:u) AS admin');
    $db->bind(':u', authUsuarioId());
    $esAdmin = (bool) ($db->single()['admin'] ?? false);
    jsonResponse([
        'parametros' => paramListar($db),
        'tipos' => PARAM_TIPOS,
        'modulo_protegido' => PARAM_MODULO_PROTEGIDO,
        'puede_editar' => in_array('SIS_PARAMETRO_EDITAR', $permisos, true),
        'puede_editar_protegidos' => $esAdmin && in_array('SIS_PARAMETRO_EDITAR', $permisos, true),
    ]);
} catch (Throwable $e) {
    apiError($e, 'Error al obtener los parámetros');
}
