<?php
require_once __DIR__ . '/../../../classes/auth.php';
$auth = requireAuth();
require_once __DIR__ . '/../../../classes/api.php';
require_once __DIR__ . '/../../../classes/mantenimiento.php';
// GET          -> planes con número de reglas y vehículos asignados
// GET ?id=N    -> plan con sus reglas y los recursos de cada regla
apiMetodo(['GET']);
try {
    $db = new Database();
    $id = apiParamId();
    if ($id === null) {
        $db->query("SELECT p.*,
                (SELECT count(*) FROM logistica.tb_reglasmantenimiento r WHERE r.fk_plan_id = p.plan_id) AS reglas,
                (SELECT count(*) FROM administrativo.tb_vehiculos v WHERE v.fk_plan_id = p.plan_id) AS vehiculos
            FROM logistica.tb_planesmantenimiento p ORDER BY p.plan_modelo");
        jsonResponse($db->resultset());
    }
    $db->query('SELECT * FROM logistica.tb_planesmantenimiento WHERE plan_id = :id');
    $db->bind(':id', $id);
    $plan = $db->single();
    if (!$plan) {
        jsonResponse(['error' => 'Plan no encontrado'], 404);
    }
    $db->query('SELECT * FROM logistica.tb_reglasmantenimiento WHERE fk_plan_id = :id ORDER BY mantenimiento_km_intervalo, mantenimiento_km_inicio');
    $db->bind(':id', $id);
    $reglas = $db->resultset();
    $db->query('SELECT mr.fk_mantenimiento_id, r.recurso_id, r.recurso_codigo, r.recurso_descripcion
                  FROM logistica.tb_mantenimiento_recursos mr
                  JOIN logistica.tb_recursosmantenimiento r ON r.recurso_id = mr.fk_recurso_id
                  JOIN logistica.tb_reglasmantenimiento rg ON rg.mantenimiento_id = mr.fk_mantenimiento_id
                 WHERE rg.fk_plan_id = :id ORDER BY r.recurso_descripcion');
    $db->bind(':id', $id);
    $recursos = $db->resultset();
    foreach ($reglas as &$regla) {
        $regla['recursos'] = array_values(array_filter($recursos, fn($x) => $x['fk_mantenimiento_id'] == $regla['mantenimiento_id']));
    }
    $plan['reglas'] = $reglas;
    $db->query('SELECT vehiculo_id, vehiculo_sigla, vehiculo_placa FROM administrativo.tb_vehiculos WHERE fk_plan_id = :id ORDER BY vehiculo_sigla');
    $db->bind(':id', $id);
    $plan['vehiculos'] = $db->resultset();
    jsonResponse($plan);
} catch (Throwable $e) {
    apiError($e, 'Error al obtener planes');
}
