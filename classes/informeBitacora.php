<?php
/*
 * Informes imprimibles de la Bitácora de vehículos (mantenimiento vehicular): flota y vehículo.
 * Mismas cifras que los tableros (bitFlota / bitVehiculo). Gráficos: flota -> 'gasto'; vehículo -> 'rendimiento', 'gasto'.
 */
require_once __DIR__ . '/bitacoraDatos.php';
require_once __DIR__ . '/informeEstadistico.php';

const INFORME_FLOTA_GRAFICOS = ['gasto'];
const INFORME_VEHICULO_GRAFICOS = ['rendimiento', 'gasto'];
const INFORME_BITACORA_NOTAS = "Rendimiento: km recorridos entre cargas de tanque lleno divididos para los galones; una carga sin lectura válida de kilometraje se suma a la siguiente.\n"
    . "Costo por km: combustible más mantenimiento del período divididos para los km recorridos (diferencia entre la mayor y la menor lectura del período).\n"
    . "Vehículos iguales: misma marca, modelo y año. Se excluyen órdenes anuladas; el combustible considera solo órdenes validadas.\n"
    . 'Los datos corresponden a lo registrado en el sistema a la fecha y hora de generación.';

/** Nombre corto del vehículo: 'B-1 · PEA-0001' */
function informeVehiculoCorto(array $v): string
{
    return implode(' · ', array_filter([$v['vehiculo_sigla'] ?? null, $v['vehiculo_placa'] ?? null]));
}

/** Modelo del vehículo: 'CHEVROLET NPR 2015' */
function informeVehiculoModelo(array $v): string
{
    return trim(implode(' ', array_filter([$v['vehiculo_marca'] ?? null, $v['vehiculo_modelo'] ?? null, $v['vehiculo_anio'] ?? null],
        fn($x) => $x !== null && $x !== '')));
}

/** Alertas graves ('serious') de una fila */
function informeGraves(array $alertas): int
{
    return count(array_filter($alertas, fn($a) => $a['nivel'] === 'serious'));
}

/** Orden por defecto del tablero de la flota: alertas graves, alertas, costo por km (mayor primero) */
function informeOrdenFlota(array $filas): array
{
    usort($filas, fn($a, $b) => [informeGraves($b['alertas']), count($b['alertas']), $b['costo_total_km'] ?? -INF]
        <=> [informeGraves($a['alertas']), count($a['alertas']), $a['costo_total_km'] ?? -INF]);
    return $filas;
}

function informeAlertasTabla(array $filas): string
{
    return informeTabla([['Vehículo', 18, 'left'], ['Nivel', 10, 'left'], ['Detalle', 72, 'left']], $filas, 'Sin alertas en el período.');
}

function informeFlotaHtml(Database $db, string $desde, string $hasta, array $graficos, array $autor): string
{
    $inst = reporteInstitucion($db);
    $r = bitFlota($db, $desde, $hasta);
    $filas = informeOrdenFlota($r['vehiculos']);
    $p = $r['parametros'];
    $km = array_sum(array_column($filas, 'km_recorridos'));
    $comb = array_sum(array_column($filas, 'gasto_combustible'));
    $mant = array_sum(array_column($filas, 'gasto_mantenimiento'));
    $conGraves = count(array_filter($filas, fn($v) => informeGraves($v['alertas']) > 0));
    $n = 0;
    $s = informeSeccion(++$n, 'Resumen', null, informeCifras([
        ['Vehículos activos', count($filas), $conGraves . ' requieren revisión'],
        ['Km recorridos', informeNumero($km), 'suma de la flota'],
        ['Costo por km de la flota', $km > 0 ? informeDinero(($comb + $mant) / $km, 3) : '—', 'combustible + mantenimiento'],
        ['Gasto de combustible', informeDinero($comb), array_sum(array_column($filas, 'cargas')) . ' cargas'],
        ['Gasto de mantenimiento', informeDinero($mant), array_sum(array_column($filas, 'mantenimientos')) . ' órdenes'],
        ['Gasto total', informeDinero($comb + $mant), 'del período'],
    ]));
    $s .= informeSeccion(++$n, 'Indicadores por vehículo', $graficos['gasto'] ?? null, informeTabla([
        ['Vehículo', 22, 'left'], ['Km', 9, 'right'], ['km/gal', 8, 'right'], ['vs. iguales', 10, 'right'], ['Combustible', 12, 'right'],
        ['Mantenimiento', 13, 'right'], ['Costo por km', 11, 'right'], ['Costo total', 10, 'right'], ['Alertas', 5, 'center'],
    ], array_map(fn($v) => [
        informeVehiculoCorto($v) . ' — ' . informeVehiculoModelo($v), informeNumero($v['km_recorridos']), informeNumero($v['rendimiento'], 1),
        $v['rendimiento_dif_pct'] === null ? '—' : ($v['rendimiento_dif_pct'] > 0 ? '+' : '') . informeNumero($v['rendimiento_dif_pct'], 1) . ' %',
        informeDinero($v['gasto_combustible']), informeDinero($v['gasto_mantenimiento']), informeDinero($v['costo_total_km'], 3),
        informeDinero($v['costo_total']), count($v['alertas']) ?: '—',
    ], $filas), 'Sin vehículos activos.'), INFORME_ANCHO_MM,
        'Ordenado por alertas y costo por km. El gráfico muestra el gasto de los 15 vehículos con mayor gasto total.');
    $alertas = [];
    foreach ($filas as $v) {
        foreach ($v['alertas'] as $a) {
            $alertas[] = [informeVehiculoCorto($v), $a['nivel'] === 'serious' ? 'Revisar' : 'Atención', $a['mensaje']];
        }
    }
    $s .= informeSeccion(++$n, 'Alertas', null, informeAlertasTabla($alertas), INFORME_ANCHO_MM, sprintf(
        'Revisar: trabajo repetido en menos de %d días, rendimiento %d %% menor o mantenimiento por km %d %% mayor que vehículos iguales.',
        $p['ventana'], $p['pct_rendimiento'], $p['pct_costo']));
    return informeDocumento($inst, 'DIRECCIÓN ADMINISTRATIVA', 'Bitácora de vehículos — flota', [
        ['Período', informeFecha($desde) . ' al ' . informeFecha($hasta)], ['Vehículos', 'Activos'],
    ], $s, INFORME_BITACORA_NOTAS, $autor);
}

/** null si el vehículo no existe */
function informeVehiculoHtml(Database $db, int $id, string $desde, string $hasta, array $graficos, array $autor): ?string
{
    $inst = reporteInstitucion($db);
    $r = bitVehiculo($db, $id, $desde, $hasta);
    if ($r === null) {
        return null;
    }
    $v = $r['vehiculo'];
    $i = $r['indicadores'];
    $c = $r['comparacion'];
    $dif = fn(?float $pct) => $pct === null ? 'sin vehículos iguales con datos' : ($pct > 0 ? '+' : '') . informeNumero($pct, 1) . ' % vs. iguales';
    $n = 0;
    $s = informeSeccion(++$n, 'Resumen', null, informeCifras([
        ['Km recorridos', informeNumero($i['km_recorridos']), $i['km_actual'] ? 'último registro ' . informeNumero($i['km_actual']) . ' km' : ''],
        ['Rendimiento de combustible', $i['combustible']['rendimiento'] === null ? '—' : informeNumero($i['combustible']['rendimiento'], 1) . ' km/gal',
            $dif($c['rendimiento']['diferencia_pct'])],
        ['Costo por km', informeDinero($i['costo_total_km'], 3), $dif($c['costo_total_km']['diferencia_pct'])],
        ['Combustible', informeDinero($i['combustible']['valor']), informeNumero($i['combustible']['galones'], 2) . ' gal en ' . $i['combustible']['cargas'] . ' cargas'],
        ['Mantenimiento', informeDinero($i['mantenimiento']['total']), $i['mantenimiento']['ordenes'] . ' órdenes'],
        ['Gasto total', informeDinero($i['costo_total']), 'del período'],
    ]));
    $s .= informeSeccion(++$n, 'Alertas', null, informeAlertasTabla(array_map(fn($a) => [informeVehiculoCorto($v),
        $a['nivel'] === 'serious' ? 'Revisar' : 'Atención', $a['mensaje']], $r['alertas'])));
    $validos = array_values(array_filter($r['tramos'], fn($t) => $t['valido']));
    $s .= informeSeccion(++$n, 'Rendimiento por carga', $graficos['rendimiento'] ?? null, informeTabla([
        ['Fecha', 14, 'left'], ['Documento', 18, 'left'], ['Km', 12, 'right'], ['Km recorridos', 14, 'right'], ['Galones', 12, 'right'],
        ['km/gal', 10, 'right'], ['Costo por km', 20, 'right'],
    ], array_map(fn($t) => [informeFecha($t['fecha']), $t['codigo'], informeNumero($t['km']), informeNumero($t['km_recorridos']),
        informeNumero($t['galones'], 2), ['b' => informeNumero($t['rendimiento'], 1)], informeDinero($t['costo_km'], 3)], $validos),
        'Se necesitan al menos dos cargas con kilometraje para calcular el rendimiento.'), INFORME_ANCHO_MM,
        $c['rendimiento']['promedio_pares'] !== null ? 'Línea punteada: promedio de vehículos iguales (' . informeNumero($c['rendimiento']['promedio_pares'], 1) . ' km/gal).' : '');
    $series = array_merge(['COMBUSTIBLE'], $r['rubros']);
    $columnas = [['Mes', 16, 'left']];
    foreach ($series as $x) {
        $columnas[] = [informeEtiqueta($x), round(70 / count($series), 1), 'right'];
    }
    $columnas[] = ['Total', 14, 'right'];
    $meses = array_values(array_filter($r['gasto_mensual'], fn($m) => $m['total'] > 0));
    $filasGasto = array_map(fn($m) => array_merge([informeMes($m['mes'])], array_map(fn($x) => informeDinero($m[$x] ?? 0), $series),
        [['b' => informeDinero($m['total'])]]), $meses);
    if ($meses) {
        $filasGasto[] = array_merge([['b' => 'Total']], array_map(fn($x) => ['b' => informeDinero(array_sum(array_column($meses, $x)))], $series),
            [['b' => informeDinero(array_sum(array_column($meses, 'total')))]]);
    }
    $s .= informeSeccion(++$n, 'Gasto mensual', $graficos['gasto'] ?? null, informeTabla($columnas, $filasGasto), INFORME_ANCHO_MM,
        'La tabla muestra los meses con gasto; el gráfico, desde el primer mes con gasto.');
    $m = $i['mantenimiento'];
    $tipos = implode(' · ', array_map(fn($k, $x) => "$x " . mb_strtolower($k), array_keys($m['por_tipo']), $m['por_tipo']));
    $resumenMant = $m['ordenes'] . ' orden(es)' . ($tipos ? " ($tipos)" : '')
        . ($m['km_entre'] ? ' · una cada ' . informeNumero($m['km_entre']) . ' km' : '') . ($m['dias_entre'] ? ' / ' . informeNumero($m['dias_entre']) . ' días' : '');
    $rubros = array_map(fn($k, $x) => [informeEtiqueta($k), informeDinero($x)], array_keys($m['por_rubro']), $m['por_rubro']);
    if ($rubros) {
        $rubros[] = [['b' => 'Total'], ['b' => informeDinero($m['total'])]];
    }
    $s .= informeSeccion(++$n, 'Mantenimiento', null, '<div class="nota" style="margin-bottom:1mm;">' . e($resumenMant) . '</div>'
        . informeTabla([['Rubro', 70, 'left'], ['Valor', 30, 'right']], $rubros, 'Sin mantenimiento en el período.')
        . '<div style="height:2mm;"></div>'
        . informeTabla([['Trabajo repetido', 52, 'left'], ['Veces', 10, 'right'], ['Fechas', 38, 'left']], array_map(fn($t) => [
            ($t['en_ventana'] ? '(!) ' : '') . $t['trabajo'], $t['veces'], implode(', ', array_map(fn($o) => informeFecha($o['fecha']), $t['ocurrencias'])),
        ], $i['trabajos_repetidos']), 'Ningún trabajo se repitió en el período.'), INFORME_ANCHO_MM,
        $i['trabajos_repetidos'] ? '(!) repetido en menos de ' . $r['parametros']['ventana'] . ' días.' : '');
    $pares = array_merge([['vehiculo_sigla' => ($v['vehiculo_sigla'] ?: $v['vehiculo_placa']) . ' (este)', 'vehiculo_placa' => null,
        'km_recorridos' => $i['km_recorridos'], 'rendimiento' => $i['combustible']['rendimiento'], 'costo_mant_km' => $i['costo_mant_km'],
        'costo_total_km' => $i['costo_total_km']]], $r['pares']);
    $s .= informeSeccion(++$n, 'Vehículos iguales (' . informeVehiculoModelo($v) . ')', null, count($pares) > 1 ? informeTabla([
        ['Vehículo', 30, 'left'], ['Km', 16, 'right'], ['km/gal', 16, 'right'], ['Mant. por km', 19, 'right'], ['Costo por km', 19, 'right'],
    ], array_map(fn($x) => [informeVehiculoCorto($x), informeNumero($x['km_recorridos']), informeNumero($x['rendimiento'], 1),
        informeDinero($x['costo_mant_km'], 3), informeDinero($x['costo_total_km'], 3)], $pares))
        : '<div class="nota">No hay otros vehículos de la misma marca, modelo y año para comparar.</div>');
    $etiquetas = ['COMBUSTIBLE' => 'Combustible', 'MANTENIMIENTO' => 'Mantenimiento', 'MOVILIZACION' => 'Movilización', 'EMERGENCIA' => 'Emergencia'];
    $historial = informeTabla([['Fecha', 11, 'left'], ['Km', 14, 'right'], ['Tipo', 13, 'left'], ['Documento', 15, 'left'], ['Detalle', 35, 'left'], ['Valor', 12, 'right']],
        array_map(fn($ev) => [informeFecha($ev['fecha']), $ev['km'] === null ? '—' : informeNumero($ev['km']) . (!empty($ev['km_fin']) ? ' a ' . informeNumero($ev['km_fin']) : ''),
            $etiquetas[$ev['tipo']] ?? $ev['tipo'], $ev['codigo'],
            $ev['detalle'] . ($ev['tipo'] === 'COMBUSTIBLE' ? ' · ' . informeNumero($ev['galones'], 2) . ' gal' . ($ev['rendimiento'] ? ' · ' . informeNumero($ev['rendimiento'], 1) . ' km/gal' : '') : '')
            . ($ev['tipo'] === 'MANTENIMIENTO' && !empty($ev['trabajos']) ? ' · ' . implode('; ', $ev['trabajos']) : ''),
            isset($ev['valor']) ? informeDinero($ev['valor']) : ''], $r['eventos']), 'Sin registros en el período.',
        (++$n) . '. Historial (más reciente primero)');
    // El historial puede ocupar varias páginas: el título va en el encabezado de la tabla (se repite en cada página)
    $s .= '<div style="height:4mm;"></div>' . $historial;
    return informeDocumento($inst, 'DIRECCIÓN ADMINISTRATIVA', 'Bitácora del vehículo ' . informeVehiculoCorto($v), [
        ['Período', informeFecha($desde) . ' al ' . informeFecha($hasta)], ['Vehículo', informeVehiculoCorto($v)],
        ['Marca / modelo / año', informeVehiculoModelo($v)], ['Tipo / combustible', trim(($v['vehiculo_tipo'] ?? '') . ' · ' . ($v['vehiculo_combustible'] ?? ''), ' ·')],
    ], $s, INFORME_BITACORA_NOTAS, $autor);
}
