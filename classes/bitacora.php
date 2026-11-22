<?php
/*
 * Bitácora del vehículo: cálculos (funciones puras, sin base de datos).
 *
 * Combustible - método de tanque lleno: el combustible de una carga repone lo consumido desde la carga anterior,
 * así que el tramo i rinde (km_i - km_{i-1}) / galones_i. El rendimiento del período es la suma de km de los tramos
 * válidos dividida para la suma de sus galones (no el promedio de los rendimientos, que exagera los tramos cortos).
 *
 * Estructuras:
 *   carga = ['id','codigo','fecha'(Y-m-d),'km','galones','valor','tipo_combustible', 'referencia'(bool, carga previa al período)]
 *   orden = ['id','codigo','fecha','km','tipo','estado','total','rubros'=>[rubro=>valor], 'trabajos'=>[texto...]]
 */

const BIT_PALABRAS_VACIAS = ['DE', 'DEL', 'LA', 'LAS', 'EL', 'LOS', 'Y', 'E', 'A', 'AL', 'EN', 'PARA', 'POR', 'CON', 'UN', 'UNA', 'O'];

function bitDias(string $desde, string $hasta): int
{
    return (int) round((strtotime($hasta) - strtotime($desde)) / 86400);
}

function bitOrdenar(array $items): array
{
    usort($items, fn($a, $b) => [$a['fecha'], (float) ($a['km'] ?? 0)] <=> [$b['fecha'], (float) ($b['km'] ?? 0)]);
    return $items;
}

/**
 * Tramos entre cargas consecutivas, con el rendimiento de cada uno y por qué no se usa si no es válido.
 * Una carga sin kilometraje (o con uno menor al anterior) no tiene rendimiento propio, pero su combustible se suma al del
 * siguiente tramo válido, que se mide desde la última lectura buena: así el consumo total no se subestima.
 */
function bitTramosCombustible(array $cargas): array
{
    $cargas = bitOrdenar($cargas);
    $tramos = [];
    $ultima = null;              // última carga con kilometraje válido
    $galPendiente = 0.0;         // combustible de cargas sin lectura válida desde $ultima
    $valPendiente = 0.0;
    foreach ($cargas as $c) {
        $gal = (float) ($c['galones'] ?? 0);
        $km = $c['km'] !== null && (float) $c['km'] > 0 ? (float) $c['km'] : null;
        if ($ultima === null) {  // primera carga: solo sirve de punto de partida
            if ($km !== null) {
                $ultima = $c;
            }
            if (empty($c['referencia']) && $km === null) {
                $tramos[] = bitTramo($c, null, null, $gal, 'Carga sin kilometraje');
            }
            continue;
        }
        $motivo = null;
        if ($km === null) {
            $motivo = 'Carga sin kilometraje';
        } elseif ($km <= (float) $ultima['km']) {
            $motivo = 'Kilometraje menor o igual al de la carga anterior';
        } elseif ($gal + $galPendiente <= 0) {
            $motivo = 'Carga sin galones';
        }
        if (!empty($c['referencia'])) {
            $ultima = $km !== null ? $c : $ultima;
            continue;
        }
        if ($motivo !== null && $motivo !== 'Carga sin galones') {
            $tramos[] = bitTramo($c, $ultima, null, $gal, $motivo);
            $galPendiente += $gal;
            $valPendiente += (float) $c['valor'];
            continue;
        }
        $tramos[] = bitTramo($c, $ultima, $km - (float) $ultima['km'], $gal + $galPendiente, $motivo, (float) $c['valor'] + $valPendiente, $galPendiente > 0);
        $ultima = $c;
        $galPendiente = $valPendiente = 0.0;
    }
    return $tramos;
}

function bitTramo(array $c, ?array $desde, ?float $kmRec, float $gal, ?string $motivo, ?float $valor = null, bool $acumulado = false): array
{
    $valor ??= (float) $c['valor'];
    return [
        'carga_id' => $c['id'], 'codigo' => $c['codigo'], 'fecha' => $c['fecha'], 'km' => $c['km'],
        'km_recorridos' => $kmRec, 'galones' => round($gal, 3), 'valor' => round($valor, 2),
        'dias' => $desde ? bitDias($desde['fecha'], $c['fecha']) : null,
        'rendimiento' => $motivo ? null : round($kmRec / $gal, 2),
        'costo_km' => $motivo ? null : round($valor / $kmRec, 4),
        'valido' => $motivo === null, 'motivo' => $motivo,
        'incluye_cargas_sin_lectura' => $acumulado,
    ];
}

function bitResumenCombustible(array $cargas): array
{
    $delPeriodo = array_values(array_filter($cargas, fn($c) => empty($c['referencia'])));
    $tramos = bitTramosCombustible($cargas);
    $validos = array_values(array_filter($tramos, fn($t) => $t['valido']));
    $galones = array_sum(array_map(fn($c) => (float) ($c['galones'] ?? 0), $delPeriodo));
    $valor = array_sum(array_map(fn($c) => (float) $c['valor'], $delPeriodo));
    $kmTramos = array_sum(array_column($validos, 'km_recorridos'));
    $galTramos = array_sum(array_column($validos, 'galones'));
    $valTramos = array_sum(array_column($validos, 'valor'));
    return [
        'cargas' => count($delPeriodo),
        'galones' => round($galones, 3),
        'valor' => round($valor, 2),
        'precio_galon' => $galones > 0 ? round($valor / $galones, 3) : null,
        'km_tramos' => $kmTramos,
        'rendimiento' => $galTramos > 0 ? round($kmTramos / $galTramos, 2) : null,
        'costo_km' => $kmTramos > 0 ? round($valTramos / $kmTramos, 4) : null,
        'dias_entre_cargas' => $validos ? round(array_sum(array_column($validos, 'dias')) / count($validos), 1) : null,
        'inconsistencias' => count($tramos) - count($validos),
        'tramos' => $tramos,
    ];
}

function bitResumenMantenimiento(array $ordenes): array
{
    $ordenes = bitOrdenar($ordenes);
    $porTipo = [];
    $porRubro = [];
    foreach ($ordenes as $o) {
        $porTipo[$o['tipo']] = ($porTipo[$o['tipo']] ?? 0) + 1;
        foreach ($o['rubros'] as $rubro => $v) {
            $porRubro[$rubro] = round(($porRubro[$rubro] ?? 0) + (float) $v, 2);
        }
    }
    $kmEntre = [];
    $diasEntre = [];
    for ($i = 1; $i < count($ordenes); $i++) {
        $km = (float) $ordenes[$i]['km'] - (float) $ordenes[$i - 1]['km'];
        if ($km > 0) {
            $kmEntre[] = $km;
        }
        $diasEntre[] = bitDias($ordenes[$i - 1]['fecha'], $ordenes[$i]['fecha']);
    }
    return [
        'ordenes' => count($ordenes),
        'por_tipo' => $porTipo,
        'total' => round(array_sum(array_map(fn($o) => (float) $o['total'], $ordenes)), 2),
        'por_rubro' => $porRubro,
        'km_entre' => $kmEntre ? round(array_sum($kmEntre) / count($kmEntre)) : null,
        'dias_entre' => $diasEntre ? round(array_sum($diasEntre) / count($diasEntre), 1) : null,
    ];
}

/** "Cambio de automático del motor de arranque." -> "CAMBIO AUTOMATICO MOTOR ARRANQUE" */
function bitNormalizarTrabajo(string $texto): string
{
    $t = mb_strtoupper(trim($texto), 'UTF-8');
    $t = strtr($t, ['Á' => 'A', 'É' => 'E', 'Í' => 'I', 'Ó' => 'O', 'Ú' => 'U', 'Ü' => 'U', 'Ñ' => 'N']);
    $t = preg_replace('/[^A-Z0-9 ]+/', ' ', $t);
    $palabras = array_filter(preg_split('/\s+/', $t), fn($p) => $p !== '' && !in_array($p, BIT_PALABRAS_VACIAS, true));
    return implode(' ', $palabras);
}

/**
 * Trabajos que se repiten en órdenes distintas. en_ventana = alguna repetición ocurrió dentro de $ventanaDias.
 * Devuelve [['trabajo', 'veces', 'dias_min', 'km_min', 'en_ventana', 'ocurrencias' => [[codigo, fecha, km, texto]]]]
 */
function bitTrabajosRepetidos(array $ordenes, int $ventanaDias): array
{
    $grupos = [];
    foreach (bitOrdenar($ordenes) as $o) {
        foreach (array_unique(array_map('bitNormalizarTrabajo', $o['trabajos'])) as $clave) {
            if ($clave === '') {
                continue;
            }
            $texto = '';
            foreach ($o['trabajos'] as $t) {
                if (bitNormalizarTrabajo($t) === $clave) {
                    $texto = $t;
                    break;
                }
            }
            $grupos[$clave][] = ['codigo' => $o['codigo'], 'fecha' => $o['fecha'], 'km' => $o['km'], 'texto' => $texto];
        }
    }
    $repetidos = [];
    foreach ($grupos as $clave => $oc) {
        if (count($oc) < 2) {
            continue;
        }
        $dias = [];
        $kms = [];
        for ($i = 1; $i < count($oc); $i++) {
            $dias[] = bitDias($oc[$i - 1]['fecha'], $oc[$i]['fecha']);
            $kms[] = (float) $oc[$i]['km'] - (float) $oc[$i - 1]['km'];
        }
        $repetidos[] = ['trabajo' => $oc[count($oc) - 1]['texto'], 'clave' => $clave, 'veces' => count($oc),
            'dias_min' => min($dias), 'km_min' => min($kms), 'en_ventana' => min($dias) <= $ventanaDias, 'ocurrencias' => $oc];
    }
    usort($repetidos, fn($a, $b) => [$b['en_ventana'], $b['veces'], $a['dias_min']] <=> [$a['en_ventana'], $a['veces'], $b['dias_min']]);
    return $repetidos;
}

/** Comparación con vehículos iguales: promedio de los pares con dato y diferencia porcentual. */
function bitComparacion(?float $valor, array $valoresPares): array
{
    $pares = array_values(array_filter($valoresPares, fn($v) => $v !== null));
    $promedio = $pares ? array_sum($pares) / count($pares) : null;
    return [
        'valor' => $valor,
        'promedio_pares' => $promedio !== null ? round($promedio, 4) : null,
        'pares_con_dato' => count($pares),
        'diferencia_pct' => ($valor !== null && $promedio) ? round(($valor - $promedio) / $promedio * 100, 1) : null,
    ];
}

/** Gasto por mes: combustible y cada rubro de mantenimiento, con todos los meses del período (en cero si no hubo gasto). */
function bitGastoMensual(array $cargas, array $ordenes, array $rubros, string $desde, string $hasta): array
{
    $meses = [];
    for ($m = strtotime(date('Y-m-01', strtotime($desde))); $m <= strtotime($hasta); $m = strtotime('+1 month', $m)) {
        $meses[date('Y-m', $m)] = array_merge(['mes' => date('Y-m', $m), 'COMBUSTIBLE' => 0.0], array_fill_keys($rubros, 0.0));
    }
    foreach ($cargas as $c) {
        $mes = substr($c['fecha'], 0, 7);
        if (empty($c['referencia']) && isset($meses[$mes])) {
            $meses[$mes]['COMBUSTIBLE'] += (float) $c['valor'];
        }
    }
    foreach ($ordenes as $o) {
        $mes = substr($o['fecha'], 0, 7);
        if (!isset($meses[$mes])) {
            continue;
        }
        foreach ($o['rubros'] as $rubro => $v) {
            $meses[$mes][$rubro] = ($meses[$mes][$rubro] ?? 0) + (float) $v;
        }
    }
    foreach ($meses as &$fila) {
        $total = 0;
        foreach ($fila as $k => &$v) {
            if ($k !== 'mes') {
                $v = round($v, 2);
                $total += $v;
            }
        }
        unset($v);
        $fila['total'] = round($total, 2);
    }
    return array_values($meses);
}

/** Indicadores de un vehículo en el período. $km = ['min' => ?, 'max' => ?] de todas las lecturas del período. */
function bitIndicadores(array $cargas, array $ordenes, array $km, int $ventanaDias): array
{
    $comb = bitResumenCombustible($cargas);
    $mant = bitResumenMantenimiento($ordenes);
    $kmRec = ($km['min'] !== null && $km['max'] !== null) ? max(0, (float) $km['max'] - (float) $km['min']) : 0;
    $repetidos = bitTrabajosRepetidos($ordenes, $ventanaDias);
    return [
        'km_recorridos' => $kmRec,
        'km_actual' => $km['max'],
        'combustible' => $comb,
        'mantenimiento' => $mant,
        'costo_mant_km' => $kmRec > 0 ? round($mant['total'] / $kmRec, 4) : null,
        'costo_total' => round($comb['valor'] + $mant['total'], 2),
        'costo_total_km' => $kmRec > 0 ? round(($comb['valor'] + $mant['total']) / $kmRec, 4) : null,
        'trabajos_repetidos' => $repetidos,
    ];
}

/**
 * Alertas a partir de los indicadores y la comparación con vehículos iguales.
 * nivel: 'serious' (requiere revisión) | 'warning' (atención).
 */
function bitAlertas(array $ind, array $compRendimiento, array $compCostoMant, int $pctRendimiento, int $pctCosto): array
{
    $alertas = [];
    foreach ($ind['trabajos_repetidos'] as $r) {
        if ($r['en_ventana']) {
            $alertas[] = ['tipo' => 'TRABAJO_REPETIDO', 'nivel' => 'serious',
                'mensaje' => sprintf('"%s" se realizó %d veces; la repetición más cercana fue a los %d días (%s km).',
                    $r['trabajo'], $r['veces'], $r['dias_min'], number_format($r['km_min'], 0, ',', '.'))];
        }
    }
    if ($compRendimiento['diferencia_pct'] !== null && $compRendimiento['diferencia_pct'] <= -$pctRendimiento) {
        $alertas[] = ['tipo' => 'RENDIMIENTO_BAJO', 'nivel' => 'serious',
            'mensaje' => sprintf('Rinde %s km/gal, %s %% menos que vehículos iguales (%s km/gal).',
                number_format($compRendimiento['valor'], 2, ',', '.'), number_format(abs($compRendimiento['diferencia_pct']), 1, ',', '.'),
                number_format($compRendimiento['promedio_pares'], 2, ',', '.'))];
    }
    if ($compCostoMant['diferencia_pct'] !== null && $compCostoMant['diferencia_pct'] >= $pctCosto) {
        $alertas[] = ['tipo' => 'COSTO_MANTENIMIENTO_ALTO', 'nivel' => 'serious',
            'mensaje' => sprintf('El mantenimiento cuesta $%s por km, %s %% más que vehículos iguales ($%s por km).',
                number_format($compCostoMant['valor'], 3, ',', '.'), number_format($compCostoMant['diferencia_pct'], 1, ',', '.'),
                number_format($compCostoMant['promedio_pares'], 3, ',', '.'))];
    }
    if ($ind['combustible']['inconsistencias'] > 0) {
        $alertas[] = ['tipo' => 'LECTURAS_KM', 'nivel' => 'warning',
            'mensaje' => sprintf('%d carga(s) de combustible con kilometraje faltante o menor al anterior; no se usan en el rendimiento.',
                $ind['combustible']['inconsistencias'])];
    }
    return $alertas;
}
