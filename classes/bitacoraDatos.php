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
                    UNION ALL SELECT fk_vehiculo_id, parte_unidad_kilometraje_salida, parte_unidad_despacho::date FROM operaciones.tb_parte_unidades
                    UNION ALL SELECT fk_vehiculo_id, parte_unidad_kilometraje_ingreso, COALESCE(parte_unidad_fin_operaciones, parte_unidad_despacho)::date
                      FROM operaciones.tb_parte_unidades
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
