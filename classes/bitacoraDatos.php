<?php
/*
 * Bitácora del vehículo: consultas. Los cálculos están en classes/bitacora.php.
 * Fuentes: combustible (órdenes VALIDADAS por vehículo; las de canecas no tienen vehículo), mantenimiento (no anuladas),
 * movilización (no anuladas) y partes de emergencia.
 */
require_once __DIR__ . '/api.php';
require_once __DIR__ . '/bitacora.php';
require_once __DIR__ . '/mantenimiento.php';

/** Rango de fechas de la URL (?desde=&hasta=, Y-m-d). Por defecto los últimos 12 meses. */
function bitRango(): array
{
    $valida = fn($f) => is_string($f) && preg_match('/^\d{4}-\d{2}-\d{2}$/', $f) && strtotime($f) !== false;
    $hasta = $valida($_GET['hasta'] ?? null) ? $_GET['hasta'] : date('Y-m-d');
    $desde = $valida($_GET['desde'] ?? null) ? $_GET['desde'] : date('Y-m-d', strtotime($hasta . ' -12 months +1 day'));
    if ($desde > $hasta) {
        jsonResponse(['error' => 'Rango inválido', 'msg' => 'La fecha inicial no puede ser posterior a la final'], 400);
    }
    return [$desde, $hasta];
}

/** '{1,2,3}' para usar con = ANY(CAST(:ids AS int[])) */
function bitArregloSql(array $ids): string
{
    return '{' . implode(',', array_map('intval', $ids)) . '}';
}

const BIT_SQL_FECHA_CARGA = "COALESCE(a.orden_fecha, a.orden_registro::date)";

/**
 * Datos por vehículo para el período: [vehiculo_id => ['cargas' => [...], 'ordenes' => [...], 'km' => ['min','max']]].
 * Incluye, como 'referencia', la última carga anterior al período (para calcular el primer tramo).
 * $ids null = todos los vehículos.
 */
function bitCargarDatos(Database $db, ?array $ids, string $desde, string $hasta): array
{
    $datos = [];
    $nuevo = fn() => ['cargas' => [], 'ordenes' => [], 'km' => ['min' => null, 'max' => null]];
    $filtro = fn(string $col) => $ids !== null ? " AND $col = ANY(CAST(:ids AS int[]))" : '';
    $bindIds = function () use ($db, $ids) {
        if ($ids !== null) {
            $db->bind(':ids', bitArregloSql($ids));
        }
    };
    $f = BIT_SQL_FECHA_CARGA;
    $columnasCarga = "a.fk_unidad_id AS v, a.orden_id AS id, a.orden_codigo AS codigo, $f::text AS fecha, a.orden_kilometraje AS km,
                      a.orden_cantidad_galones AS galones, COALESCE(a.orden_precio_total, 0) AS valor,
                      a.orden_tipo_combustible AS tipo_combustible, a.orden_estacion_servicio AS estacion";

    // Combustible del período
    $db->query("SELECT $columnasCarga FROM logistica.tb_ordenesabastecimiento a
                 WHERE a.orden_estado = 'VALIDADA' AND a.fk_unidad_id IS NOT NULL AND $f BETWEEN :d AND :h" . $filtro('a.fk_unidad_id'));
    $db->bind(':d', $desde);
    $db->bind(':h', $hasta);
    $bindIds();
    foreach ($db->resultset() as $c) {
        $datos[$c['v']] ??= $nuevo();
        $datos[$c['v']]['cargas'][] = $c + ['referencia' => false];
    }
    // Última carga anterior al período (referencia del primer tramo)
    $db->query("SELECT DISTINCT ON (a.fk_unidad_id) $columnasCarga FROM logistica.tb_ordenesabastecimiento a
                 WHERE a.orden_estado = 'VALIDADA' AND a.fk_unidad_id IS NOT NULL AND $f < :d" . $filtro('a.fk_unidad_id') . "
                 ORDER BY a.fk_unidad_id, $f DESC, a.orden_kilometraje DESC NULLS LAST");
    $db->bind(':d', $desde);
    $bindIds();
    foreach ($db->resultset() as $c) {
        if (isset($datos[$c['v']])) { // sin cargas en el período no hay tramos que calcular
            $datos[$c['v']]['cargas'][] = $c + ['referencia' => true];
        }
    }

    // Mantenimiento del período, con valores por rubro, trabajos a realizar (los que se comparan para detectar repeticiones)
    // y los sugeridos por el contratista (solo informativos)
    $db->query("SELECT o.fk_vehiculo_id AS v, o.orden_id AS id, o.orden_codigo AS codigo, o.orden_fecha_mantenimiento::date::text AS fecha,
                       o.orden_km_mantenimiento AS km, o.orden_tipomantenimiento AS tipo, o.orden_estado AS estado,
                       COALESCE((SELECT json_object_agg(r.factura_tipo, r.total) FROM (
                            SELECT f.factura_tipo, sum(COALESCE(f.factura_valor, 0)) AS total FROM logistica.tb_mantenimiento_facturas f
                             WHERE f.fk_orden_id = o.orden_id AND f.factura_estado = 'ACTIVO' GROUP BY f.factura_tipo) r), '{}'::json)::text AS rubros,
                       (SELECT json_agg(t.trabajo_descripcion ORDER BY t.trabajo_id) FROM logistica.tb_mantenimiento_trabajos t WHERE t.fk_orden_id = o.orden_id)::text AS trabajos,
                       (SELECT json_agg(t.trabajo_descripcion ORDER BY t.trabajo_id) FROM logistica.tb_mantenimiento_sugeridos t WHERE t.fk_orden_id = o.orden_id)::text AS sugeridos
                  FROM logistica.tb_ordenesmantenimiento o
                 WHERE o.orden_estado <> 'ANULADA' AND o.orden_fecha_mantenimiento::date BETWEEN :d AND :h" . $filtro('o.fk_vehiculo_id'));
    $db->bind(':d', $desde);
    $db->bind(':h', $hasta);
    $bindIds();
    foreach ($db->resultset() as $o) {
        $o['rubros'] = json_decode($o['rubros'], true) ?: [];
        $o['trabajos'] = json_decode($o['trabajos'] ?? 'null', true) ?: [];
        $o['sugeridos'] = json_decode($o['sugeridos'] ?? 'null', true) ?: [];
        $o['total'] = round(array_sum($o['rubros']), 2);
        $datos[$o['v']] ??= $nuevo();
        $datos[$o['v']]['ordenes'][] = $o;
    }

    // Lecturas de kilometraje del período (todas las fuentes): km recorridos = mayor - menor
    $db->query("SELECT v, min(km) AS min, max(km) AS max FROM (
                    SELECT a.fk_unidad_id AS v, a.orden_kilometraje::numeric AS km, $f AS f
                      FROM logistica.tb_ordenesabastecimiento a WHERE a.orden_estado = 'VALIDADA'
                    UNION ALL SELECT fk_vehiculo_id, orden_km_mantenimiento, orden_fecha_mantenimiento::date
                      FROM logistica.tb_ordenesmantenimiento WHERE orden_estado <> 'ANULADA'
                    UNION ALL SELECT fk_unidad_id, orden_kilometraje_salida, orden_hora_salida::date
                      FROM logistica.tb_ordenesmovilizacion WHERE orden_estado <> 'ORDEN ANULADA'
                    UNION ALL SELECT fk_unidad_id, orden_kilometraje_entrada, COALESCE(orden_hora_entrada, orden_hora_salida)::date
                      FROM logistica.tb_ordenesmovilizacion WHERE orden_estado <> 'ORDEN ANULADA'
                    UNION ALL SELECT pv.fk_vehiculo_id, pv.parte_vehiculo_km_salida, COALESCE(pv.parte_vehiculo_hora_salida::date, p.parte_fecha)
                      FROM operaciones.tb_partes_vehiculos pv JOIN operaciones.tb_partes p ON p.parte_id = pv.fk_parte_id WHERE p.parte_estado <> 'ANULADO'
                    UNION ALL SELECT pv.fk_vehiculo_id, pv.parte_vehiculo_km_retorno, COALESCE(pv.parte_vehiculo_hora_fin_operaciones::date, p.parte_fecha)
                      FROM operaciones.tb_partes_vehiculos pv JOIN operaciones.tb_partes p ON p.parte_id = pv.fk_parte_id WHERE p.parte_estado <> 'ANULADO'
                ) x WHERE v IS NOT NULL AND km > 0 AND f BETWEEN :d AND :h" . $filtro('v') . " GROUP BY v");
    $db->bind(':d', $desde);
    $db->bind(':h', $hasta);
    $bindIds();
    foreach ($db->resultset() as $k) {
        $datos[$k['v']] ??= $nuevo();
        $datos[$k['v']]['km'] = ['min' => (float) $k['min'], 'max' => (float) $k['max']];
    }
    return $datos;
}

/** Parámetros de las alertas. Leer antes de preparar otras sentencias. */
function bitParametros(Database $db): array
{
    return [
        'ventana' => (int) parametro($db, 'BIT_VENTANA_REPETICION_DIAS', 180),
        'pct_rendimiento' => (int) parametro($db, 'BIT_ALERTA_RENDIMIENTO_PCT', 15),
        'pct_costo' => (int) parametro($db, 'BIT_ALERTA_COSTO_PCT', 30),
    ];
}

/** Grupo de comparación: misma marca, modelo y año (si el año falta, solo marca y modelo). */
function bitClaveGrupo(array $v): string
{
    return mb_strtoupper(trim((string) $v['vehiculo_marca'])) . '|' . mb_strtoupper(trim((string) $v['vehiculo_modelo'])) . '|' . ($v['vehiculo_anio'] ?? '');
}

const BIT_SQL_VEHICULOS = "SELECT vehiculo_id, vehiculo_sigla, vehiculo_placa, vehiculo_marca, vehiculo_modelo, vehiculo_anio, vehiculo_tipo,
                                  vehiculo_combustible, vehiculo_estado, vehiculo_chasis, vehiculo_motor FROM administrativo.tb_vehiculos";

/** Bitácora de la flota (vehículos activos) en el período: lo que devuelve getBitacoraFlota.php */
function bitFlota(Database $db, string $desde, string $hasta): array
{
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
    return ['desde' => $desde, 'hasta' => $hasta, 'parametros' => $p, 'vehiculos' => $filas];
}

/** Bitácora de un vehículo en el período (null si no existe): lo que devuelve getBitacoraVehiculo.php */
function bitVehiculo(Database $db, int $id, string $desde, string $hasta): ?array
{
    $p = bitParametros($db);
    $rubros = mantLista(parametro($db, 'MANT_RUBROS', 'MANO DE OBRA|REPUESTOS|ACEITES Y LUBRICANTES'));
    $db->query(BIT_SQL_VEHICULOS . ' WHERE vehiculo_id = :id');
    $db->bind(':id', $id);
    $vehiculo = $db->single();
    if (!$vehiculo) {
        return null;
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
    return [
        'desde' => $desde, 'hasta' => $hasta, 'parametros' => $p, 'rubros' => $rubros,
        'vehiculo' => $vehiculo,
        'indicadores' => $ind,
        'tramos' => $tramos,
        'gasto_mensual' => bitGastoMensual($d['cargas'], $d['ordenes'], $rubros, $desde, $hasta),
        'comparacion' => ['rendimiento' => $compRend, 'costo_mant_km' => $compCosto, 'costo_total_km' => $compTotal],
        'pares' => $pares,
        'alertas' => bitAlertas($ind, $compRend, $compCosto, $p['pct_rendimiento'], $p['pct_costo']),
        'eventos' => $eventos,
    ];
}
