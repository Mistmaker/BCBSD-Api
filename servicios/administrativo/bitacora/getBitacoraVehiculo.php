<?php
require_once __DIR__ . '/../../../classes/auth.php';
$auth = requireAuth();
require_once __DIR__ . '/../../../classes/bitacoraDatos.php';
// GET ?id=N&desde=Y-m-d&hasta=Y-m-d (por defecto últimos 12 meses)
// -> vehículo, historial (combustible, mantenimiento, movilización, partes) ordenado por fecha y km, indicadores,
//    tramos de rendimiento, gasto mensual, trabajos repetidos, comparación con vehículos iguales y alertas.
apiMetodo(['GET']);
try {
    [$desde, $hasta] = bitRango();
    $id = apiParamId();
    if ($id === null) {
        jsonResponse(['error' => 'Falta el vehículo (?id=)'], 400);
    }
    $db = new Database();
    requirePermiso($db, 'ADM_BITACORA_VEHICULOS');
    $p = bitParametros($db);
    $rubros = mantLista(parametro($db, 'MANT_RUBROS', 'MANO DE OBRA|REPUESTOS|ACEITES Y LUBRICANTES'));
    $db->query(BIT_SQL_VEHICULOS . ' WHERE vehiculo_id = :id');
    $db->bind(':id', $id);
    $vehiculo = $db->single();
    if (!$vehiculo) {
        jsonResponse(['error' => 'Vehículo no encontrado'], 404);
    }

    // Vehículos iguales (misma marca, modelo y año)
    $db->query(BIT_SQL_VEHICULOS . " WHERE vehiculo_id <> :id AND upper(trim(vehiculo_marca)) = upper(trim(:marca))
                 AND upper(trim(vehiculo_modelo)) = upper(trim(:modelo)) AND vehiculo_anio IS NOT DISTINCT FROM CAST(:anio AS integer)
                 ORDER BY vehiculo_sigla");
    $db->bind(':id', $id);
    $db->bind(':marca', (string) $vehiculo['vehiculo_marca']);
    $db->bind(':modelo', (string) $vehiculo['vehiculo_modelo']);
    $db->bind(':anio', $vehiculo['vehiculo_anio'] !== null ? (int) $vehiculo['vehiculo_anio'] : null);
    $pares = $db->resultset();

    $ids = array_merge([$id], array_map(fn($x) => (int) $x['vehiculo_id'], $pares));
    $datos = bitCargarDatos($db, $ids, $desde, $hasta);
    $vacio = ['cargas' => [], 'ordenes' => [], 'km' => ['min' => null, 'max' => null]];
    $d = $datos[$id] ?? $vacio;
    $ind = bitIndicadores($d['cargas'], $d['ordenes'], $d['km'], $p['ventana']);
    foreach ($pares as &$par) {
        $dp = $datos[$par['vehiculo_id']] ?? $vacio;
        $ip = bitIndicadores($dp['cargas'], $dp['ordenes'], $dp['km'], $p['ventana']);
        $par += ['km_recorridos' => $ip['km_recorridos'], 'rendimiento' => $ip['combustible']['rendimiento'],
                 'costo_km_combustible' => $ip['combustible']['costo_km'], 'gasto_mantenimiento' => $ip['mantenimiento']['total'],
                 'costo_mant_km' => $ip['costo_mant_km'], 'costo_total_km' => $ip['costo_total_km']];
    }
    unset($par);
    $compRend = bitComparacion($ind['combustible']['rendimiento'], array_column($pares, 'rendimiento'));
    $compCosto = bitComparacion($ind['costo_mant_km'], array_column($pares, 'costo_mant_km'));
    $compTotal = bitComparacion($ind['costo_total_km'], array_column($pares, 'costo_total_km'));

    // Historial: movilizaciones y partes del período
    $db->query("SELECT orden_id AS id, orden_codigo AS codigo, orden_hora_salida::date::text AS fecha, orden_hora_salida::text AS fecha_hora,
                       orden_kilometraje_salida AS km, orden_kilometraje_entrada AS km_fin, orden_destino AS destino, orden_motivo_salida AS motivo, orden_estado AS estado
                  FROM logistica.tb_ordenesmovilizacion
                 WHERE fk_unidad_id = :id AND orden_estado <> 'ORDEN ANULADA' AND orden_hora_salida::date BETWEEN :d AND :h");
    $db->bind(':id', $id);
    $db->bind(':d', $desde);
    $db->bind(':h', $hasta);
    $movilizaciones = $db->resultset();
    $db->query("SELECT p.parte_id AS id, p.parte_numero AS codigo, COALESCE(pv.parte_vehiculo_hora_salida::date, p.parte_fecha)::text AS fecha,
                       COALESCE(pv.parte_vehiculo_hora_salida, p.parte_fecha + p.parte_hora_aviso)::text AS fecha_hora,
                       pv.parte_vehiculo_km_salida AS km, pv.parte_vehiculo_km_retorno AS km_fin, p.parte_tipo AS tipo,
                       (SELECT string_agg(DISTINCT concat_ws(' / ', ta.parte_auxilio_clasificacion, ta.parte_auxilio_subclasificacion), ', ')
                          FROM operaciones.tb_partes_tipos_auxilio ta WHERE ta.fk_parte_id = p.parte_id) AS funcion
                  FROM operaciones.tb_partes_vehiculos pv JOIN operaciones.tb_partes p ON p.parte_id = pv.fk_parte_id
                 WHERE pv.fk_vehiculo_id = :id AND p.parte_estado <> 'ANULADO'
                   AND COALESCE(pv.parte_vehiculo_hora_salida::date, p.parte_fecha) BETWEEN :d AND :h");
    $db->bind(':id', $id);
    $db->bind(':d', $desde);
    $db->bind(':h', $hasta);
    $partes = $db->resultset();

    $tramosPorCarga = array_column($ind['combustible']['tramos'], null, 'carga_id');
    $eventos = [];
    foreach ($d['cargas'] as $c) {
        if ($c['referencia']) {
            continue;
        }
        $t = $tramosPorCarga[$c['id']] ?? null;
        $eventos[] = ['tipo' => 'COMBUSTIBLE', 'id' => $c['id'], 'codigo' => $c['codigo'], 'fecha' => $c['fecha'], 'km' => $c['km'],
            'detalle' => trim(($c['tipo_combustible'] ?? '') . ' · ' . ($c['estacion'] ?? ''), ' ·'), 'galones' => $c['galones'], 'valor' => (float) $c['valor'],
            'km_desde_anterior' => $t['km_recorridos'] ?? null, 'rendimiento' => $t['rendimiento'] ?? null, 'observacion' => $t['motivo'] ?? null];
    }
    foreach ($d['ordenes'] as $o) {
        $eventos[] = ['tipo' => 'MANTENIMIENTO', 'id' => $o['id'], 'codigo' => $o['codigo'], 'fecha' => $o['fecha'], 'km' => $o['km'],
            'detalle' => $o['tipo'] . ' · ' . $o['estado'], 'valor' => $o['total'], 'rubros' => $o['rubros'], 'trabajos' => $o['trabajos'], 'sugeridos' => $o['sugeridos']];
    }
    foreach ($movilizaciones as $m) {
        $eventos[] = ['tipo' => 'MOVILIZACION', 'id' => $m['id'], 'codigo' => $m['codigo'], 'fecha' => $m['fecha'], 'km' => $m['km'], 'km_fin' => $m['km_fin'],
            'detalle' => trim(($m['destino'] ?? '') . ' · ' . ($m['motivo'] ?? ''), ' ·')];
    }
    foreach ($partes as $pt) {
        $eventos[] = ['tipo' => 'EMERGENCIA', 'id' => $pt['id'], 'codigo' => $pt['codigo'], 'fecha' => $pt['fecha'], 'km' => $pt['km'], 'km_fin' => $pt['km_fin'],
            'detalle' => trim(($pt['tipo'] ?? '') . ' · ' . ($pt['funcion'] ?? ''), ' ·')];
    }
    usort($eventos, fn($a, $b) => [$b['fecha'], (float) ($b['km'] ?? 0)] <=> [$a['fecha'], (float) ($a['km'] ?? 0)]);

    $tramos = $ind['combustible']['tramos'];
    unset($ind['combustible']['tramos']);
    jsonResponse([
        'desde' => $desde, 'hasta' => $hasta, 'parametros' => $p, 'rubros' => $rubros,
        'vehiculo' => $vehiculo,
        'indicadores' => $ind,
        'tramos' => $tramos,
        'gasto_mensual' => bitGastoMensual($d['cargas'], $d['ordenes'], $rubros, $desde, $hasta),
        'comparacion' => ['rendimiento' => $compRend, 'costo_mant_km' => $compCosto, 'costo_total_km' => $compTotal],
        'pares' => $pares,
        'alertas' => bitAlertas($ind, $compRend, $compCosto, $p['pct_rendimiento'], $p['pct_costo']),
        'eventos' => $eventos,
    ]);
} catch (Throwable $e) {
    apiError($e, 'Error al calcular la bitácora del vehículo');
}
