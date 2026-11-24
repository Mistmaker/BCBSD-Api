<?php
require_once __DIR__ . '/../../classes/auth.php';
$auth = requireAuth();
require_once __DIR__ . '/../../classes/parametros.php';
// PUT { param_id, param_value } -> cambia el valor (validado según el tipo) y guarda el cambio en el historial.
// Privilegio: SIS_PARAMETRO_EDITAR. Los parámetros del módulo ADMINISTRACION (quién es administrador) solo los cambia
// un administrador. La llave, el tipo y el módulo los define el sistema (migraciones).
apiMetodo(['PUT']);
$p = apiCuerpoJson();
$db = null;
try {
    $db = new Database();
    requirePermiso($db, 'SIS_PARAMETRO_EDITAR');
    $usuario = (int) authUsuarioId();
    $db->query('SELECT param_id, param_key, param_type, param_value, param_modulo FROM admin.tb_params WHERE param_id = :id');
    $db->bind(':id', (int) prop($p, 'param_id', 0));
    $param = $db->single();
    if (!$param) {
        jsonResponse(['error' => 'Parámetro no encontrado'], 404);
    }
    if (strtoupper((string) $param['param_modulo']) === PARAM_MODULO_PROTEGIDO) {
        $db->query('SELECT admin.fn_es_administrador(:u) AS admin');
        $db->bind(':u', $usuario);
        if (!($db->single()['admin'] ?? false)) {
            jsonResponse(['error' => 'Sin privilegio', 'msg' => 'Solo un administrador del sistema puede cambiar este parámetro'], 403);
        }
    }
    $valor = paramValidar((string) $param['param_type'], prop($p, 'param_value'));
    if ($valor === $param['param_value']) {
        jsonResponse(['msg' => 'Sin cambios', 'param_value' => $valor]);
    }
    $db->beginTransaction();
    $db->query('UPDATE admin.tb_params SET param_value = :v, param_actualizado = now(), fk_usuario_actualiza = :u WHERE param_id = :id');
    $db->bind(':v', $valor);
    $db->bind(':u', $usuario);
    $db->bind(':id', (int) $param['param_id']);
    $db->execute();
    $db->query('INSERT INTO admin.tb_params_historial (fk_param_id, historial_valor_anterior, historial_valor_nuevo, fk_usuario_id) VALUES (:id, :a, :n, :u)');
    $db->bind(':id', (int) $param['param_id']);
    $db->bind(':a', $param['param_value']);
    $db->bind(':n', $valor);
    $db->bind(':u', $usuario);
    $db->execute();
    $db->endTransaction();
    jsonResponse(['msg' => 'Parámetro ' . $param['param_key'] . ' actualizado', 'param_value' => $valor]);
} catch (Throwable $e) {
    $db?->cancelTransaction();
    apiError($e, 'Error al guardar el parámetro');
}
