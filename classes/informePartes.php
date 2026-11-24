<?php
/*
 * Informe imprimible de la Estadística de partes (Operaciones > Panel). Mismas secciones y orden que el tablero.
 * Gráficos esperados (claves): mes, vehiculo, bombero, recurso, auxilio, hora.
 */
require_once __DIR__ . '/partes.php';
require_once __DIR__ . '/informeEstadistico.php';

const INFORME_PARTES_GRAFICOS = ['mes', 'vehiculo', 'bombero', 'recurso', 'auxilio', 'hora'];
const INFORME_DIAS = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];

/** Filtros validados del informe (mismos que el tablero). Lanza ValidacionException. */
function informePartesFiltros(object $p): array
{
    $desde = parteFecha(prop($p, 'desde') ?: date('Y') . '-01-01', 'desde', true);
    $hasta = parteFecha(prop($p, 'hasta') ?: date('Y-m-d'), 'hasta', true);
    if ($desde > $hasta) {
        throw new ValidacionException('La fecha inicial es posterior a la final');
    }
    $tipo = strtoupper(trim((string) prop($p, 'tipo', ''))) ?: null;
    if ($tipo !== null && !in_array($tipo, PARTE_TIPOS, true)) {
        throw new ValidacionException('Tipo inválido');
    }
    $estacion = prop($p, 'estacion') ? (int) prop($p, 'estacion') : null;
    return ['desde' => $desde, 'hasta' => $hasta, 'estacion' => $estacion ?: null, 'tipo' => $tipo];
}

/** HTML completo del informe. $graficos: informeGraficos(); $autor: informeAutor(). */
function informePartesHtml(Database $db, array $f, array $graficos, array $autor): string
{
    $inst = reporteInstitucion($db);
    $estacion = 'Todas';
    if ($f['estacion']) {
        $db->query('SELECT estacion_nombre FROM operaciones.tb_estaciones WHERE estacion_id = :e');
        $db->bind(':e', $f['estacion']);
        $estacion = $db->single()['estacion_nombre'] ?? 'Todas';
    }
    $d = parteEstadisticas($db, $f['desde'], $f['hasta'], $f['estacion'], $f['tipo']);
    $r = $d['resumen'];
    $n = 0;
    $s = '';
    $s .= informeSeccion(++$n, 'Resumen', null, informeCifras([
        ['Partes', $r['partes'], $r['auxilio'] . ' auxilio · ' . $r['incendio'] . ' incendio'],
        ['Tiempo de respuesta', informeMinutos($r['respuesta_prom_min']), 'promedio · mediana ' . informeMinutos($r['respuesta_mediana_min'])],
        ['Víctimas / fallecidos', $r['victimas'] . ' / ' . $r['fallecidos'], $r['personas_asistidas'] . ' personas asistidas'],
        ['Kilómetros recorridos', informeNumero($r['km']) . ' km', count($d['por_vehiculo']) . ' vehículos usados'],
        ['Horas de operación', informeNumero($r['horas_operacion'], 1) . ' h', 'salida a fin de operaciones'],
        ['Personal', count($d['por_bombero']), 'bomberos participaron'],
    ]));
    $meses = array_values(array_filter($d['por_mes'], fn($m) => $m['auxilio'] + $m['incendio'] > 0));
    $s .= informeSeccion(++$n, 'Partes por mes', $graficos['mes'] ?? null,
        informeTabla([['Mes', 40, 'left'], ['Auxilio', 20, 'right'], ['Incendio', 20, 'right'], ['Total', 20, 'right']],
            array_map(fn($m) => [informeMes($m['mes']), $m['auxilio'], $m['incendio'], ['b' => $m['auxilio'] + $m['incendio']]], $meses)),
        INFORME_ANCHO_MM, 'La tabla muestra los meses con partes; el gráfico, todo el período.');
    $s .= informeSeccion(++$n, 'Por estación', null, informeTabla([['Estación', 24, 'left'], ['Partes', 11, 'right'], ['Auxilio', 11, 'right'],
        ['Incendio', 11, 'right'], ['Respuesta prom.', 15, 'right'], ['Salidas de vehículos', 14, 'right'], ['Participaciones', 14, 'right']],
        array_map(fn($e) => [$e['estacion'], $e['partes'], $e['auxilio'], $e['incendio'], informeMinutos($e['respuesta_prom_min']), $e['salidas_vehiculos'],
            $e['participaciones']], $d['por_estacion'])));
    $s .= informeSeccion(++$n, 'Por vehículo', $graficos['vehiculo'] ?? null, informeTabla([['Vehículo', 34, 'left'], ['Salidas', 12, 'right'],
        ['Km', 12, 'right'], ['Horas', 12, 'right'], ['Respuesta', 15, 'right'], ['Última salida', 15, 'right']],
        array_map(fn($v) => [trim(($v['siglas'] ?? '') . ' · ' . ($v['placa'] ?? ''), ' ·') . ($v['externo'] ? ' (externo)' : ''), $v['salidas'],
            informeNumero($v['km']), informeNumero($v['horas'], 1), informeMinutos($v['respuesta_prom_min']), informeFecha($v['ultima'])], $d['por_vehiculo'])), 140,
        'El gráfico muestra los 10 vehículos con más salidas; la tabla, todos.');
    $s .= informeSeccion(++$n, 'Por bombero', $graficos['bombero'] ?? null, informeTabla([['Bombero', 34, 'left'], ['Rango', 14, 'left'],
        ['Partes', 10, 'right'], ['Al mando', 10, 'right'], ['APH', 10, 'right'], ['Operativo', 11, 'right'], ['Horas', 11, 'right']],
        array_map(fn($b) => [$b['nombre'], $b['rango'] ?? '', $b['participaciones'], $b['al_mando'], $b['aph'], $b['operativo'], informeNumero($b['horas'], 1)],
            $d['por_bombero'])), 140, 'El gráfico muestra los 10 bomberos con más participaciones; la tabla, todos.');
    $tipos = ['EQUIPO' => 'Equipo / herramienta', 'MATERIAL' => 'Material descartable', 'INSUMO' => 'Insumo'];
    $s .= informeSeccion(++$n, 'Equipos, herramientas y recursos', $graficos['recurso'] ?? null, informeTabla([['Tipo', 22, 'left'],
        ['Descripción', 48, 'left'], ['Partes', 15, 'right'], ['Cantidad', 15, 'right']],
        array_map(fn($x) => [$tipos[$x['tipo']] ?? $x['tipo'], $x['descripcion'], $x['partes'], informeNumero($x['cantidad'], 2)], $d['por_recurso'])), 140,
        'El gráfico muestra los equipos y herramientas más usados; la tabla incluye también material e insumos.');
    $s .= informeSeccion(++$n, 'Tipo de auxilio y posibles causas', $graficos['auxilio'] ?? null,
        informeTabla([['Clasificación / subclasificación', 80, 'left'], ['Partes', 20, 'right']],
            array_map(fn($t) => [trim($t['clasificacion'] . ' / ' . $t['subclasificacion'], ' /'), $t['partes']], $d['por_tipo_auxilio']))
        . '<div style="height:2mm;"></div>'
        . informeTabla([['Posible causa', 55, 'left'], ['Clasificación', 30, 'left'], ['Partes', 15, 'right']],
            array_map(fn($c) => [$c['descripcion'], $c['clasificacion'], $c['partes']], $d['por_causa']), 'Sin causas registradas.'), 140);
    $s .= informeSeccion(++$n, 'Hora y día del aviso', $graficos['hora'] ?? null,
        informeTabla(array_map(fn($dia) => [$dia, 14.28, 'center'], INFORME_DIAS), [$d['por_dia_semana']]));
    $tipoTexto = $f['tipo'] ? ucfirst(strtolower($f['tipo'])) : 'Auxilio e incendio';
    return informeDocumento($inst, 'UNIDAD DE OPERACIONES', 'Estadística de partes de servicio', [
        ['Período', informeFecha($f['desde']) . ' al ' . informeFecha($f['hasta'])], ['Estación', $estacion],
        ['Tipo de parte', $tipoTexto], ['Fuente', 'Partes de servicio no anulados'],
    ], $s, "Tiempo de respuesta: desde la hora del aviso hasta el primer arribo de un vehículo (se descartan valores mayores a 24 horas).\n"
        . "Horas de operación: desde la primera salida hasta el último fin de operaciones de cada parte. Kilómetros: ingreso menos salida de cada vehículo.\n"
        . 'Se excluyen los partes anulados. Los datos corresponden a lo registrado en el sistema a la fecha y hora de generación.', $autor);
}

/** '2026-03' -> 'marzo 2026' */
function informeMes(string $mes): string
{
    [$a, $m] = explode('-', $mes);
    return ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'][(int) $m - 1] . " $a";
}
