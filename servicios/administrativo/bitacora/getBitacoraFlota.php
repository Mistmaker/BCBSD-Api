<?php
require_once __DIR__ . '/../../../classes/auth.php';
$auth = requireAuth();
require_once __DIR__ . '/../../../classes/bitacoraDatos.php';
// GET ?desde=Y-m-d&hasta=Y-m-d (por defecto últimos 12 meses)
// -> indicadores por vehículo activo: km recorridos, rendimiento y costo de combustible, gasto y frecuencia de mantenimiento,
//    costo total por km, comparación con vehículos de la misma marca/modelo/año y número de alertas.
apiMetodo(['GET']);
try {
    [$desde, $hasta] = bitRango();
    $db = new Database();
    requirePermiso($db, 'ADM_BITACORA_VEHICULOS');
    $p = bitParametros($db);
    $db->query(BIT_SQL_VEHICULOS . " WHERE vehiculo_estado = 'ACTIVO' ORDER BY vehiculo_sigla");
    $vehiculos = $db->resultset();
    $datos = bitCargarDatos($db, null, $desde, $hasta);

    $ind = [];
    foreach ($vehiculos as $v) {
        $d = $datos[$v['vehiculo_id']] ?? ['cargas' => [], 'ordenes' => [], 'km' => ['min' => null, 'max' => null]];
        $ind[$v['vehiculo_id']] = bitIndicadores($d['cargas'], $d['ordenes'], $d['km'], $p['ventana']);
    }
    $grupos = [];
    foreach ($vehiculos as $v) {
        $grupos[bitClaveGrupo($v)][] = $v['vehiculo_id'];
    }

    $filas = [];
    foreach ($vehiculos as $v) {
        $id = $v['vehiculo_id'];
        $i = $ind[$id];
        $pares = array_values(array_filter($grupos[bitClaveGrupo($v)], fn($x) => $x !== $id));
        $compRend = bitComparacion($i['combustible']['rendimiento'], array_map(fn($x) => $ind[$x]['combustible']['rendimiento'], $pares));
        $compCosto = bitComparacion($i['costo_mant_km'], array_map(fn($x) => $ind[$x]['costo_mant_km'], $pares));
        $alertas = bitAlertas($i, $compRend, $compCosto, $p['pct_rendimiento'], $p['pct_costo']);
        $filas[] = $v + [
            'km_recorridos' => $i['km_recorridos'], 'km_actual' => $i['km_actual'],
            'cargas' => $i['combustible']['cargas'], 'galones' => $i['combustible']['galones'], 'gasto_combustible' => $i['combustible']['valor'],
            'rendimiento' => $i['combustible']['rendimiento'], 'costo_km_combustible' => $i['combustible']['costo_km'],
            'mantenimientos' => $i['mantenimiento']['ordenes'], 'gasto_mantenimiento' => $i['mantenimiento']['total'],
            'gasto_por_rubro' => $i['mantenimiento']['por_rubro'], 'km_entre_mantenimientos' => $i['mantenimiento']['km_entre'],
            'dias_entre_mantenimientos' => $i['mantenimiento']['dias_entre'], 'costo_mant_km' => $i['costo_mant_km'],
            'costo_total' => $i['costo_total'], 'costo_total_km' => $i['costo_total_km'],
            'pares' => count($pares), 'rendimiento_pares' => $compRend['promedio_pares'], 'rendimiento_dif_pct' => $compRend['diferencia_pct'],
            'costo_mant_km_pares' => $compCosto['promedio_pares'], 'costo_mant_dif_pct' => $compCosto['diferencia_pct'],
            'alertas' => $alertas,
        ];
    }
    jsonResponse(['desde' => $desde, 'hasta' => $hasta, 'parametros' => $p, 'vehiculos' => $filas]);
} catch (Throwable $e) {
    apiError($e, 'Error al calcular la bitácora de la flota');
}
