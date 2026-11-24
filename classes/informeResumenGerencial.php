<?php
/*
 * Informe imprimible del Resumen gerencial de la Dirección Administrativa (mes AAAA-MM). Mismas cifras que el tablero
 * (resumenGerencial), con las listas completas. Gráfico: 'gasto' (últimos 12 meses).
 */
require_once __DIR__ . '/resumenGerencial.php';
require_once __DIR__ . '/informeEstadistico.php';

const INFORME_RESUMEN_GRAFICOS = ['gasto'];
const INFORME_TEXTO_ALERTA = ['TRABAJO_REPETIDO' => 'trabajo repetido', 'RENDIMIENTO_BAJO' => 'consume más combustible',
    'COSTO_MANTENIMIENTO_ALTO' => 'mantenimiento caro', 'LECTURAS_KM' => 'lecturas de km'];

/** Mes del cuerpo (AAAA-MM, por defecto el actual). Lanza ValidacionException. */
function informeMesValido(object $p): string
{
    $mes = (string) (prop($p, 'mes') ?: date('Y-m'));
    if (!preg_match('/^\d{4}-(0[1-9]|1[0-2])$/', $mes)) {
        throw new ValidacionException('Mes inválido (AAAA-MM)');
    }
    return $mes;
}

/** Variación porcentual frente al mes anterior; null sin base */
function informeVariacion(float $actual, ?float $anterior): ?float
{
    return $anterior ? round(($actual - $anterior) / $anterior * 100, 1) : null;
}

function informeResumenHtml(Database $db, string $mes, array $graficos, array $autor): string
{
    $inst = reporteInstitucion($db);
    $d = resumenGerencial($db, $mes, null);
    $f = $d['flota'];
    $g = $d['gasto'];
    $total = fn($m) => (float) $m['combustible'] + (float) $m['mantenimiento'];
    $meses = $g['meses'];
    $anterior = count($meses) > 1 ? $meses[count($meses) - 2] : null;
    $var = informeVariacion($total($g['mes']), $anterior ? $total($anterior) : null);
    $nombreMes = informeMes($mes);
    $anio = substr($mes, 0, 4);
    $n = 0;
    $s = informeSeccion(++$n, 'Resumen', null, informeCifras([
        ['Vehículos activos', $f['activos'], $f['en_taller'] . ' en taller · ' . $f['en_salida'] . ' en salida'],
        ['Gasto de ' . $nombreMes, informeDinero($total($g['mes']), 0),
            $var === null ? 'combustible y mantenimiento' : ($var > 0 ? '+' : '') . informeNumero($var, 1) . ' % vs. mes anterior'],
        ['Gasto del año ' . $anio, informeDinero($g['anio']['combustible'] + $g['anio']['mantenimiento'], 0),
            'combustible ' . informeDinero($g['anio']['combustible'], 0) . ' · mant. ' . informeDinero($g['anio']['mantenimiento'], 0)],
        ['Requieren atención', $d['alertas']['vehiculos'] + $f['mantenimiento_vencido'],
            $d['alertas']['vehiculos'] . ' con alertas · ' . $f['mantenimiento_vencido'] . ' con mantenimiento vencido'],
        ['Licencias de operadores', $d['licencias']['VIGENTE'] . ' vigentes', $d['licencias']['POR VENCER'] . ' por vencer · ' . $d['licencias']['VENCIDA'] . ' vencidas'],
        ['Peticiones de materiales', $d['peticiones']['mes'], $d['peticiones']['anio'] . ' en el año'],
    ]));
    $filas = array_map(fn($m) => [informeMes($m['mes']), informeDinero($m['combustible']), informeNumero($m['galones'], 1),
        informeDinero($m['mantenimiento']), $m['ordenes_mantenimiento'], $m['movilizaciones'], ['b' => informeDinero($total($m))]], $meses);
    $filas[] = [['b' => 'Total 12 meses'], ['b' => informeDinero(array_sum(array_column($meses, 'combustible')))],
        ['b' => informeNumero(array_sum(array_column($meses, 'galones')), 1)], ['b' => informeDinero(array_sum(array_column($meses, 'mantenimiento')))],
        ['b' => array_sum(array_column($meses, 'ordenes_mantenimiento'))], ['b' => array_sum(array_column($meses, 'movilizaciones'))],
        ['b' => informeDinero(array_sum(array_map($total, $meses)))]];
    $s .= informeSeccion(++$n, 'Gasto de los últimos 12 meses', $graficos['gasto'] ?? null, informeTabla([
        ['Mes', 20, 'left'], ['Combustible', 15, 'right'], ['Galones', 11, 'right'], ['Mantenimiento', 15, 'right'],
        ['Órdenes de mant.', 13, 'right'], ['Movilizaciones', 12, 'right'], ['Total', 14, 'right'],
    ], $filas));
    $rubros = array_map(fn($r) => [informeEtiqueta($r['rubro']), informeDinero($r['total'])], $g['anio']['por_rubro']);
    if ($rubros) {
        $rubros[] = [['b' => 'Total'], ['b' => informeDinero(array_sum(array_column($g['anio']['por_rubro'], 'total')))]];
    }
    $s .= informeSeccion(++$n, ucfirst($nombreMes) . ' y mantenimiento del año por rubro', null,
        informeTabla([[ucfirst($nombreMes), 65, 'left'], ['Valor', 35, 'right']], [
            ['Combustible', informeDinero($g['mes']['combustible'])], ['Galones cargados', informeNumero($g['mes']['galones'], 1)],
            ['Mantenimiento', informeDinero($g['mes']['mantenimiento'])], ['Órdenes de mantenimiento', $g['mes']['ordenes_mantenimiento']],
            ['Órdenes de movilización', $g['mes']['movilizaciones']], ['Peticiones de materiales', $d['peticiones']['mes']],
        ]) . '<div style="height:2mm;"></div>'
        . informeTabla([['Mantenimiento del año ' . $anio . ' por rubro', 65, 'left'], ['Valor', 35, 'right']], $rubros, 'Sin gasto registrado.'));
    $s .= informeSeccion(++$n, 'Vehículos con alertas', null, informeTabla([['Vehículo', 25, 'left'], ['Alertas', 55, 'left'], ['Gasto 12 meses', 20, 'right']],
        array_map(fn($v) => [informeVehiculoTexto($v), implode(', ', array_map(fn($a) => INFORME_TEXTO_ALERTA[$a] ?? mb_strtolower($a), $v['alertas'])),
            informeDinero($v['costo_total'])], $d['alertas']['detalle']), 'Ningún vehículo con alertas.'), INFORME_ANCHO_MM,
        'Últimos 12 meses: trabajos repetidos, consumo o costo de mantenimiento por encima de vehículos iguales (detalle en la Bitácora de vehículos).');
    $s .= informeSeccion(++$n, 'Mantenimiento preventivo', null, informeTabla([['Vehículo', 34, 'left'], ['Km actual', 22, 'right'], ['Estado', 22, 'left'],
        ['Próximo mantenimiento (km)', 22, 'right']], array_map(fn($v) => [informeVehiculoTexto($v), informeNumero($v['km_actual']),
            $v['estado'] === 'VENCIDO' ? 'Vencido' : 'Próximo', informeNumero($v['km_proximo'])], $f['atencion']), 'Todos los vehículos al día.'), INFORME_ANCHO_MM,
        $f['mantenimiento_vencido'] . ' vencido(s) · ' . $f['mantenimiento_proximo'] . ' próximo(s) · ' . $f['sin_plan'] . ' sin plan de mantenimiento.');
    $s .= informeSeccion(++$n, 'Contratos de mantenimiento vigentes', null, informeTabla([['Contrato', 25, 'left'], ['Taller', 22, 'left'],
        ['Asignado', 13, 'right'], ['Consumido', 13, 'right'], ['Saldo', 12, 'right'], ['%', 6, 'right'], ['Hasta', 9, 'left']],
        array_map(fn($c) => [$c['contrato_codigo'], $c['contrato_taller'] ?? '', informeDinero($c['asignado']), informeDinero($c['consumido']),
            ['b' => informeDinero($c['saldo'])], (float) $c['asignado'] > 0 ? informeNumero(min(100, $c['consumido'] / $c['asignado'] * 100), 1) : '—',
            informeFecha($c['contrato_fecha_fin'])], $d['contratos']), 'No hay contratos vigentes.'));
    return informeDocumento($inst, 'DIRECCIÓN ADMINISTRATIVA', 'Resumen gerencial — ' . $nombreMes, [
        ['Mes', ucfirst($nombreMes)], ['Gasto de 12 meses', informeMes($meses[0]['mes']) . ' a ' . $nombreMes],
    ], $s, "Gasto: combustible de órdenes validadas (por fecha de la orden) y mantenimiento de facturas activas de órdenes no anuladas (por fecha del mantenimiento).\n"
        . "Requieren atención: vehículos con alertas graves de la bitácora en los últimos 12 meses más los de mantenimiento preventivo vencido.\n"
        . 'Los datos corresponden a lo registrado en el sistema a la fecha y hora de generación.', $autor);
}

/** 'B-1 · PEA-0001' a partir de vehiculo_sigla / vehiculo_placa */
function informeVehiculoTexto(array $v): string
{
    return implode(' · ', array_filter([$v['vehiculo_sigla'] ?? null, $v['vehiculo_placa'] ?? null]));
}
