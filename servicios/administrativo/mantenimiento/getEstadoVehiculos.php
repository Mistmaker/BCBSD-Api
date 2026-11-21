<?php
require_once __DIR__ . '/../../../classes/auth.php';
$auth = requireAuth();
require_once __DIR__ . '/../../../classes/api.php';
require_once __DIR__ . '/../../../classes/mantenimiento.php';
// GET          -> estado de mantenimiento de todos los vehículos activos (alertas)
// GET ?id=N    -> estado de un vehículo (para precargar una orden nueva)
// Respuesta por vehículo: km actual, plan, último mantenimiento, último preventivo y la regla más urgente.
apiMetodo(['GET']);
try {
    $db = new Database();
    $tolerancia = (int) parametro($db, 'MANT_TOLERANCIA_KM', 1000);
    $id = apiParamId();

    $sql = "SELECT v.vehiculo_id, v.vehiculo_sigla, v.vehiculo_placa, v.vehiculo_marca, v.vehiculo_modelo, v.vehiculo_tipo, v.vehiculo_estado,
                   v.fk_plan_id, p.plan_modelo, k.vehiculo_kilometraje,
                   (SELECT o.orden_km_mantenimiento FROM logistica.tb_ordenesmantenimiento o WHERE o.fk_vehiculo_id = v.vehiculo_id AND o.orden_estado <> 'ANULADA'
                     ORDER BY o.orden_fecha_mantenimiento DESC LIMIT 1) AS ultimo_km_mantenimiento,
                   (SELECT o.orden_fecha_mantenimiento::date FROM logistica.tb_ordenesmantenimiento o WHERE o.fk_vehiculo_id = v.vehiculo_id AND o.orden_estado <> 'ANULADA'
                     ORDER BY o.orden_fecha_mantenimiento DESC LIMIT 1) AS ultimo_fecha_mantenimiento,
                   (SELECT max(o.orden_km_mantenimiento) FROM logistica.tb_ordenesmantenimiento o WHERE o.fk_vehiculo_id = v.vehiculo_id AND o.orden_estado <> 'ANULADA'
                     AND o.orden_tipomantenimiento = 'PREVENTIVO') AS ultimo_km_preventivo,
                   (SELECT count(*) FROM logistica.tb_ordenesmantenimiento o WHERE o.fk_vehiculo_id = v.vehiculo_id AND o.orden_estado = 'MANTENIMIENTO') AS ordenes_abiertas
              FROM administrativo.tb_vehiculos v
              JOIN administrativo.vw_vehiculos_kilometraje k ON k.vehiculo_id = v.vehiculo_id
              LEFT JOIN logistica.tb_planesmantenimiento p ON p.plan_id = v.fk_plan_id";
    if ($id !== null) {
        $db->query($sql . ' WHERE v.vehiculo_id = :id');
        $db->bind(':id', $id);
    } else {
        $db->query($sql . " WHERE v.vehiculo_estado = 'ACTIVO' ORDER BY v.vehiculo_sigla");
    }
    $vehiculos = $db->resultset();
    if ($id !== null && !$vehiculos) {
        jsonResponse(['error' => 'Vehículo no encontrado'], 404);
    }

    $db->query("SELECT mantenimiento_id, fk_plan_id, mantenimiento_km_inicio, mantenimiento_km_intervalo
                  FROM logistica.tb_reglasmantenimiento WHERE mantenimiento_estado = 'ACTIVO'");
    $reglasPorPlan = [];
    foreach ($db->resultset() as $r) {
        $reglasPorPlan[$r['fk_plan_id']][] = $r;
    }

    foreach ($vehiculos as &$v) {
        $km = (float) $v['vehiculo_kilometraje'];
        $ultimoPreventivo = $v['ultimo_km_preventivo'] !== null ? (float) $v['ultimo_km_preventivo'] : null;
        $v['tolerancia_km'] = $tolerancia;
        $v['proximo'] = $v['fk_plan_id'] ? mantEvaluarPlan($km, $reglasPorPlan[$v['fk_plan_id']] ?? [], $ultimoPreventivo, $tolerancia) : null;
        $v['estado_mantenimiento'] = $v['proximo']['estado'] ?? 'SIN PLAN';
    }
    jsonResponse($id !== null ? $vehiculos[0] : $vehiculos);
} catch (Throwable $e) {
    apiError($e, 'Error al calcular el estado de los vehículos');
}
