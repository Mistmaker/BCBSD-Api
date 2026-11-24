<?php
/*
 * Resumen gerencial de la Dirección Administrativa (servicios generales) del mes AAAA-MM: lo usan el tablero
 * (servicios/administrativo/getResumenGerencial.php) y su informe imprimible (reportes/administrativo/resumenGerencial.php).
 */
require_once __DIR__ . '/bitacoraDatos.php';
require_once __DIR__ . '/operadores.php';

/** $limite: cuántos vehículos listar en atención y alertas (null = todos, para el informe impreso) */
function resumenGerencial(Database $db, string $mes, ?int $limite = 8): array
{
    $inicioMes = "$mes-01";
    $finMes = date('Y-m-t', strtotime($inicioMes));
    $inicioAnio = substr($mes, 0, 4) . '-01-01';
    $inicio12 = date('Y-m-01', strtotime("$inicioMes -11 months"));

    $tolerancia = (int) parametro($db, 'MANT_TOLERANCIA_KM', 1000);
    $diasAviso = (int) parametro($db, 'OPER_DIAS_AVISO_LICENCIA', 30);
    $p = bitParametros($db);

    // Flota
    $flota = mantEstadoVehiculos($db, $tolerancia);
    $porEstado = array_count_values(array_column($flota, 'estado_mantenimiento'));
    $db->query("SELECT count(DISTINCT fk_unidad_id) AS n FROM logistica.tb_ordenesmovilizacion WHERE orden_estado = 'SALIDA'");
    $enSalida = (int) $db->single()['n'];
    $atencionMantenimiento = array_values(array_map(fn($v) => [
        'vehiculo_id' => (int) $v['vehiculo_id'], 'vehiculo_sigla' => $v['vehiculo_sigla'], 'vehiculo_placa' => $v['vehiculo_placa'],
        'estado' => $v['estado_mantenimiento'], 'km_actual' => (float) $v['vehiculo_kilometraje'],
        'km_proximo' => $v['proximo']['km_proximo'] ?? null,
    ], array_filter($flota, fn($v) => in_array($v['estado_mantenimiento'], ['VENCIDO', 'PROXIMO'], true))));
    usort($atencionMantenimiento, fn($a, $b) => [$a['estado'] !== 'VENCIDO', $a['vehiculo_sigla']] <=> [$b['estado'] !== 'VENCIDO', $b['vehiculo_sigla']]);

    // Gasto por mes (12 meses): combustible validado y mantenimiento por rubro (facturas activas de órdenes no anuladas)
    $db->query("SELECT to_char(m, 'YYYY-MM') AS mes,
                       COALESCE((SELECT sum(a.orden_precio_total) FROM logistica.tb_ordenesabastecimiento a
                                  WHERE a.orden_estado = 'VALIDADA' AND date_trunc('month', COALESCE(a.orden_fecha, a.orden_registro::date)) = m), 0)::float AS combustible,
                       COALESCE((SELECT sum(a.orden_cantidad_galones) FROM logistica.tb_ordenesabastecimiento a
                                  WHERE a.orden_estado = 'VALIDADA' AND date_trunc('month', COALESCE(a.orden_fecha, a.orden_registro::date)) = m), 0)::float AS galones,
                       COALESCE((SELECT sum(f.factura_valor) FROM logistica.tb_mantenimiento_facturas f
                                  JOIN logistica.tb_ordenesmantenimiento o ON o.orden_id = f.fk_orden_id
                                 WHERE f.factura_estado = 'ACTIVO' AND o.orden_estado <> 'ANULADA'
                                   AND date_trunc('month', o.orden_fecha_mantenimiento) = m), 0)::float AS mantenimiento,
                       (SELECT count(*) FROM logistica.tb_ordenesmantenimiento o WHERE o.orden_estado <> 'ANULADA'
                         AND date_trunc('month', o.orden_fecha_mantenimiento) = m)::int AS ordenes_mantenimiento,
                       (SELECT count(*) FROM logistica.tb_ordenesmovilizacion v WHERE v.orden_estado <> 'ORDEN ANULADA'
                         AND date_trunc('month', v.orden_hora_salida) = m)::int AS movilizaciones
                  FROM generate_series(CAST(:i AS date), CAST(:f AS date), interval '1 month') AS m ORDER BY m");
    $db->bind(':i', $inicio12);
    $db->bind(':f', $inicioMes);
    $meses = $db->resultset();
    $delMes = end($meses) ?: ['combustible' => 0, 'galones' => 0, 'mantenimiento' => 0, 'ordenes_mantenimiento' => 0, 'movilizaciones' => 0];
    $delAnio = ['combustible' => 0, 'mantenimiento' => 0];
    foreach ($meses as $m) {
        if ($m['mes'] >= substr($inicioAnio, 0, 7)) {
            $delAnio['combustible'] += $m['combustible'];
            $delAnio['mantenimiento'] += $m['mantenimiento'];
        }
    }
    // Mantenimiento del año por rubro (cubre también meses fuera de la ventana de 12 si el mes elegido es de enero)
    $db->query("SELECT f.factura_tipo AS rubro, sum(f.factura_valor)::float AS total FROM logistica.tb_mantenimiento_facturas f
                  JOIN logistica.tb_ordenesmantenimiento o ON o.orden_id = f.fk_orden_id
                 WHERE f.factura_estado = 'ACTIVO' AND o.orden_estado <> 'ANULADA' AND o.orden_fecha_mantenimiento::date BETWEEN :i AND :f
                 GROUP BY f.factura_tipo ORDER BY 2 DESC");
    $db->bind(':i', $inicioAnio);
    $db->bind(':f', $finMes);
    $rubrosAnio = $db->resultset();

    // Contratos vigentes: consumido frente al monto
    $db->query("SELECT c.contrato_id, c.contrato_codigo, c.contrato_taller, c.contrato_fecha_fin::text AS contrato_fecha_fin,
                       COALESCE(sum(s.asignado), 0)::float AS asignado, COALESCE(sum(s.consumido), 0)::float AS consumido, COALESCE(sum(s.saldo), 0)::float AS saldo
                  FROM logistica.tb_contratosmantenimiento c LEFT JOIN logistica.vw_contratosmantenimiento_saldo s ON s.contrato_id = c.contrato_id
                 WHERE c.contrato_estado = 'VIGENTE' GROUP BY c.contrato_id ORDER BY c.contrato_fecha_fin NULLS LAST");
    $contratos = $db->resultset();

    // Vehículos con alertas de la bitácora (últimos 12 meses)
    $datos = bitCargarDatos($db, null, $inicio12, $finMes);
    $vacio = ['cargas' => [], 'ordenes' => [], 'km' => ['min' => null, 'max' => null]];
    $ind = [];
    foreach ($flota as $v) {
        $d = $datos[$v['vehiculo_id']] ?? $vacio;
        $ind[$v['vehiculo_id']] = bitIndicadores($d['cargas'], $d['ordenes'], $d['km'], $p['ventana']);
    }
    $grupos = [];
    foreach ($flota as $v) {
        $grupos[bitClaveGrupo($v)][] = $v['vehiculo_id'];
    }
    $conAlertas = [];
    foreach ($flota as $v) {
        $id = $v['vehiculo_id'];
        $pares = array_filter($grupos[bitClaveGrupo($v)], fn($x) => $x !== $id);
        $alertas = bitAlertas($ind[$id], bitComparacion($ind[$id]['combustible']['rendimiento'], array_map(fn($x) => $ind[$x]['combustible']['rendimiento'], $pares)),
            bitComparacion($ind[$id]['costo_mant_km'], array_map(fn($x) => $ind[$x]['costo_mant_km'], $pares)), $p['pct_rendimiento'], $p['pct_costo']);
        $graves = array_values(array_filter($alertas, fn($a) => $a['nivel'] === 'serious'));
        if ($graves) {
            $conAlertas[] = ['vehiculo_id' => (int) $id, 'vehiculo_sigla' => $v['vehiculo_sigla'], 'vehiculo_placa' => $v['vehiculo_placa'],
                'alertas' => array_values(array_unique(array_column($graves, 'tipo'))), 'costo_total' => $ind[$id]['costo_total']];
        }
    }
    usort($conAlertas, fn($a, $b) => [count($b['alertas']), $b['costo_total']] <=> [count($a['alertas']), $a['costo_total']]);

    // Operadores: licencias
    $licencias = ['VIGENTE' => 0, 'POR VENCER' => 0, 'VENCIDA' => 0];
    foreach (operListar($db, "AND c.conductor_estado = 'ACTIVO' AND pp.ppersonal_estado = 'EN FUNCIONES'") as $o) {
        $licencias[operVigencia($o['conductor_licencia_validez'], $diasAviso)]++;
    }

    // Peticiones de materiales
    try {
        $db->query("SELECT count(*) FILTER (WHERE peticion_fecha BETWEEN :im AND :fm)::int AS mes, count(*)::int AS anio
                      FROM logistica.tb_peticionesmateriales WHERE peticion_estado = 'EMITIDA' AND peticion_fecha BETWEEN :ia AND :fm2");
        $db->bind(':im', $inicioMes);
        $db->bind(':fm', $finMes);
        $db->bind(':ia', $inicioAnio);
        $db->bind(':fm2', $finMes);
        $peticiones = $db->single();
    } catch (PDOException $e) {
        $peticiones = ['mes' => 0, 'anio' => 0]; // base sin la migración de peticiones
    }

    return [
        'mes' => $mes,
        'flota' => [
            'activos' => count($flota), 'en_taller' => count(array_filter($flota, fn($v) => (int) $v['ordenes_abiertas'] > 0)), 'en_salida' => $enSalida,
            'mantenimiento_vencido' => $porEstado['VENCIDO'] ?? 0, 'mantenimiento_proximo' => $porEstado['PROXIMO'] ?? 0, 'sin_plan' => $porEstado['SIN PLAN'] ?? 0,
            'atencion' => array_slice($atencionMantenimiento, 0, $limite),
        ],
        'gasto' => [
            'mes' => ['combustible' => round($delMes['combustible'], 2), 'galones' => round($delMes['galones'], 2), 'mantenimiento' => round($delMes['mantenimiento'], 2),
                      'ordenes_mantenimiento' => $delMes['ordenes_mantenimiento'], 'movilizaciones' => $delMes['movilizaciones']],
            'anio' => ['combustible' => round($delAnio['combustible'], 2), 'mantenimiento' => round($delAnio['mantenimiento'], 2),
                       'por_rubro' => $rubrosAnio],
            'meses' => $meses,
        ],
        'contratos' => $contratos,
        'alertas' => ['vehiculos' => count($conAlertas), 'detalle' => array_slice($conAlertas, 0, $limite)],
        'licencias' => $licencias,
        'peticiones' => $peticiones,
    ];
}
