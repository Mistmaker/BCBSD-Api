<?php
/*
 * Informe estadístico imprimible (PDF A4 vertical) de los tableros: Estadística de partes, Bitácora de vehículos y
 * Resumen gerencial. Los gráficos los dibuja el navegador en versión para impresión (los mismos del tablero) y llegan
 * como PNG en base64; las cifras y tablas se recalculan siempre en el servidor con los mismos filtros.
 * Estructura: cabecera institucional, datos del informe, secciones (gráfico + tabla con sus datos), notas y
 * "Elaborado por". Escudo de fondo atenuado. Sin número de informe (por ahora).
 */
require_once __DIR__ . '/reporte.php';

const INFORME_MAX_GRAFICOS = 20;
const INFORME_MAX_BYTES = 3 * 1024 * 1024;
const INFORME_MAX_PX = 4000;
const INFORME_ANCHO_MM = 170;
const INFORME_ALTO_MAX_MM = 95;
/** Secciones con más filas que esto no se mantienen en una sola página */
const INFORME_FILAS_JUNTAS = 18;

/**
 * Valida y guarda en archivos temporales los gráficos recibidos ({clave: 'data:image/png;base64,...'}).
 * Solo se aceptan las $claves conocidas; las demás se ignoran. Un gráfico ausente deja la sección solo con su tabla.
 * Devuelve [clave => ['ruta' => archivo, 'ancho' => px, 'alto' => px]]. Lanza ValidacionException si uno no es un PNG.
 */
function informeGraficos($graficos, array $claves): array
{
    $graficos = (array) ($graficos ?? []);
    if (count($graficos) > INFORME_MAX_GRAFICOS) {
        throw new ValidacionException('Demasiados gráficos en el informe');
    }
    $res = [];
    foreach ($claves as $clave) {
        $dato = $graficos[$clave] ?? null;
        if (!is_string($dato) || $dato === '') {
            continue;
        }
        $base64 = preg_replace('#^data:image/png;base64,#', '', $dato);
        $bytes = base64_decode($base64, true);
        if ($bytes === false || strlen($bytes) > INFORME_MAX_BYTES || !str_starts_with($bytes, "\x89PNG\r\n\x1a\n")) {
            throw new ValidacionException("El gráfico \"$clave\" no es una imagen PNG válida");
        }
        $info = @getimagesizefromstring($bytes);
        if (!$info || $info[2] !== IMAGETYPE_PNG || $info[0] < 10 || $info[1] < 10 || $info[0] > INFORME_MAX_PX || $info[1] > INFORME_MAX_PX) {
            throw new ValidacionException("El gráfico \"$clave\" no es una imagen PNG válida");
        }
        $ruta = tempnam(sys_get_temp_dir(), 'informe-') . '.png';
        file_put_contents($ruta, $bytes);
        $res[$clave] = ['ruta' => $ruta, 'ancho' => $info[0], 'alto' => $info[1]];
    }
    return $res;
}

/** Borra los archivos temporales de los gráficos */
function informeLimpiar(array $graficos): void
{
    foreach ($graficos as $g) {
        @unlink($g['ruta']);
        @unlink(preg_replace('/\.png$/', '', $g['ruta'])); // archivo vacío de tempnam()
    }
}

/**
 * Medidas en mm de un gráfico: ancho pedido y alto proporcional; si el alto supera el máximo, se reduce el ancho.
 * Devuelve [ancho, alto].
 */
function informeMedidas(int $px, int $py, float $anchoMm = INFORME_ANCHO_MM, float $altoMax = INFORME_ALTO_MAX_MM): array
{
    $alto = $anchoMm * $py / max(1, $px);
    if ($alto > $altoMax) {
        $anchoMm = $anchoMm * $altoMax / $alto;
        $alto = $altoMax;
    }
    return [round($anchoMm, 1), round($alto, 1)];
}

/** Nombre y cargo (puesto en funciones en Talento Humano) del usuario que genera el informe */
function informeAutor(Database $db, int $usuarioId): array
{
    $db->query("SELECT concat_ws(' ', pe.persona_nombres, pe.persona_apellidos) AS nombre,
                       (SELECT pu.puesto_nombre FROM tthh.tb_personal t
                          JOIN tthh.tb_personal_puestos pp ON pp.fk_personal_id = t.personal_id AND pp.ppersonal_estado = 'EN FUNCIONES'
                          JOIN tthh.tb_puestos pu ON pu.puesto_id = pp.fk_puesto_id
                         WHERE t.fk_persona_id = u.fk_persona_id ORDER BY pp.ppersonal_id DESC LIMIT 1) AS cargo,
                       u.usuario_login
                  FROM admin.tb_usuarios u LEFT JOIN resources.tb_personas pe ON pe.persona_id = u.fk_persona_id
                 WHERE u.usuario_id = :u");
    $db->bind(':u', $usuarioId);
    $f = $db->single() ?: [];
    return ['nombre' => mb_strtoupper(trim((string) ($f['nombre'] ?? '')) ?: (string) ($f['usuario_login'] ?? '')), 'cargo' => (string) ($f['cargo'] ?? '')];
}

/** '2026-11-20' -> '20/11/2026' */
function informeFecha(?string $fecha): string
{
    return $fecha ? date('d/m/Y', strtotime($fecha)) : '';
}

/** 15 -> '15 min'; 75 -> '1 h 15 min'; null -> '—' */
function informeMinutos($min): string
{
    if ($min === null) {
        return '—';
    }
    $m = (int) round((float) $min);
    return $m < 60 ? "$m min" : intdiv($m, 60) . ' h ' . str_pad((string) ($m % 60), 2, '0', STR_PAD_LEFT) . ' min';
}

/** Número con separadores ecuatorianos (miles con punto, decimales con coma); null -> '—' */
function informeNumero($v, int $decimales = 0): string
{
    return $v === null ? '—' : number_format((float) $v, $decimales, ',', '.');
}

/** '2026-03' -> 'marzo 2026' */
function informeMes(string $mes): string
{
    [$a, $m] = explode('-', $mes);
    return ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'][(int) $m - 1] . " $a";
}

/** Valor en dólares: '$ 1.234,56'; null -> '—' */
function informeDinero($v, int $decimales = 2): string
{
    return $v === null ? '—' : '$ ' . informeNumero($v, $decimales);
}

/** 'ACEITES Y LUBRICANTES' -> 'Aceites y lubricantes' */
function informeEtiqueta(string $s): string
{
    $t = mb_strtolower($s);
    return mb_strtoupper(mb_substr($t, 0, 1)) . mb_substr($t, 1);
}

/**
 * Rango de fechas del cuerpo del informe (desde/hasta, Y-m-d). Por defecto los últimos $mesesDefecto meses.
 * Lanza ValidacionException si una fecha no es válida o el rango está invertido.
 */
function informeRango(object $p, int $mesesDefecto = 12): array
{
    $leer = function ($v, string $campo): ?string {
        if ($v === null || $v === '') {
            return null;
        }
        $d = DateTime::createFromFormat('!Y-m-d', (string) $v);
        if (!$d || $d->format('Y-m-d') !== (string) $v) {
            throw new ValidacionException("Fecha inválida en \"$campo\"");
        }
        return (string) $v;
    };
    $hasta = $leer(prop($p, 'hasta'), 'hasta') ?? date('Y-m-d');
    $desde = $leer(prop($p, 'desde'), 'desde') ?? date('Y-m-d', strtotime("$hasta -$mesesDefecto months +1 day"));
    if ($desde > $hasta) {
        throw new ValidacionException('La fecha inicial es posterior a la final');
    }
    return [$desde, $hasta];
}

/**
 * Tabla con encabezados [[título, ancho %, alineación], ...] y filas de texto (se escapan).
 * Una celda puede ser ['b' => 'texto'] para negrita.
 */
function informeTabla(array $columnas, array $filas, string $vacio = 'Sin datos en el período.', ?string $tituloSeccion = null): string
{
    // Encabezados en <thead>: se repiten si la tabla continúa en otra página (con el título de la sección, si se indica)
    $h = '<table class="t"><thead>';
    if ($tituloSeccion !== null) {
        $h .= '<tr><th colspan="' . count($columnas) . '" class="seccion-th">' . e(mb_strtoupper($tituloSeccion)) . '</th></tr>';
    }
    $h .= '<tr>';
    foreach ($columnas as [$titulo, $ancho]) {
        $h .= '<th style="width:' . $ancho . '%;">' . e($titulo) . '</th>';
    }
    $h .= '</tr></thead>';
    if (!$filas) {
        return $h . '<tr><td colspan="' . count($columnas) . '" style="text-align:center;color:#555;">' . e($vacio) . '</td></tr></table>';
    }
    foreach ($filas as $fila) {
        $h .= '<tr>';
        foreach (array_values($fila) as $i => $c) {
            [, $ancho, $alinear] = $columnas[$i] + [null, null, 'left'];
            $texto = is_array($c) ? '<b>' . e($c['b']) . '</b>' : e((string) $c);
            $h .= '<td style="width:' . $ancho . '%;text-align:' . $alinear . ';">' . $texto . '</td>';
        }
        $h .= '</tr>';
    }
    return $h . '</table>';
}

/** Cifras principales en filas de 3: [[título, valor, nota], ...] */
function informeCifras(array $cifras): string
{
    $h = '<table class="t">';
    foreach (array_chunk($cifras, 3) as $fila) {
        $h .= '<tr>';
        foreach ($fila as [$titulo, $valor, $nota]) {
            $h .= '<td style="width:33.3%;"><div style="font-size:7px;color:#555;">' . e($titulo) . '</div>'
                . '<div style="font-size:14px;font-weight:bold;">' . e((string) $valor) . '</div>'
                . '<div style="font-size:7px;color:#555;">' . e((string) $nota) . '</div></td>';
        }
        for ($i = count($fila); $i < 3; $i++) {
            $h .= '<td style="width:33.3%;"></td>';
        }
        $h .= '</tr>';
    }
    return $h . '</table>';
}

/**
 * Sección numerada: título, gráfico (si llegó) y contenido HTML (tablas). $ancho: ancho del gráfico en mm.
 * Se mantiene junta en una página (salvo que sea más larga que una página).
 */
function informeSeccion(int $n, string $titulo, ?array $grafico, string $contenido, float $ancho = INFORME_ANCHO_MM, string $nota = ''): string
{
    $img = '';
    if ($grafico) {
        [$w, $h] = informeMedidas($grafico['ancho'], $grafico['alto'], $ancho);
        $img = '<div style="text-align:center;margin-bottom:2mm;"><img src="' . e($grafico['ruta']) . '" style="width:' . $w . 'mm;height:' . $h . 'mm;"></div>';
    }
    $cabecera = '<div class="seccion">' . $n . '. ' . e(mb_strtoupper($titulo)) . '</div>' . $img;
    $nota = $nota !== '' ? '<div class="nota">' . e($nota) . '</div>' : '';
    // Una tabla larga no cabe junto al gráfico: solo el título y el gráfico van juntos; la tabla continúa en la página siguiente
    if (substr_count($contenido, '<tr>') > INFORME_FILAS_JUNTAS) {
        return '<nobreak>' . $cabecera . '</nobreak>' . $contenido . $nota;
    }
    return '<nobreak>' . $cabecera . $contenido . $nota . '</nobreak>';
}

/**
 * Documento completo. $area: primera línea de la cabecera (p. ej. 'UNIDAD DE OPERACIONES'); $titulo del informe;
 * $datos: [[etiqueta, valor], ...] (período, filtros...); $secciones: HTML de informeSeccion(); $notas: texto;
 * $autor: informeAutor().
 */
function informeDocumento(array $inst, string $area, string $titulo, array $datos, string $secciones, string $notas, array $autor): string
{
    $filas = '';
    foreach (array_chunk(array_merge($datos, [['Generado por', $autor['nombre']], ['Fecha de generación', date('d/m/Y H:i')]]), 2) as $par) {
        $filas .= '<tr>';
        foreach ($par as [$etiqueta, $valor]) {
            $filas .= '<td style="width:18%;"><b>' . e($etiqueta) . ':</b></td><td style="width:32%;">' . e((string) $valor) . '</td>';
        }
        if (count($par) === 1) {
            $filas .= '<td style="width:18%;"></td><td style="width:32%;"></td>';
        }
        $filas .= '</tr>';
    }
    $cuerpo = '<style>
        .seccion{background:#9dc3e6;font-size:9px;font-weight:bold;padding:3px 4px;margin-top:4mm;margin-bottom:2mm;}
        .t td,.t th{padding:2px 4px;font-size:7.5px;}
        .nota{font-size:7px;color:#444;margin-top:1mm;}
        .seccion-th{background:#9dc3e6;font-size:9px;font-weight:bold;text-align:left;padding:3px 4px;}
    </style>
    <div style="text-align:center;font-size:14px;font-weight:bold;margin-bottom:3mm;">' . e(mb_strtoupper($titulo)) . '</div>
    <table class="t">' . $filas . '</table>' . $secciones
        . '<nobreak><div class="seccion">NOTAS</div><div class="nota">' . nl2br(e($notas)) . '</div>'
        . '<div style="margin-top:20mm;margin-left:24mm;width:60mm;text-align:center;font-size:8px;">'
        . '<div style="border-top:1px solid #222d32;padding-top:1mm;">' . e($autor['nombre']) . '</div>'
        . ($autor['cargo'] !== '' ? '<div>' . e($autor['cargo']) . '</div>' : '') . '<div><b>ELABORADO POR</b></div></div></nobreak>';
    $html = reporteHtml($inst, [$area, 'INFORME ESTADÍSTICO', $titulo], $cuerpo, 'escudo-tenue.jpg');
    return str_replace('</page_footer>', '<div style="position:absolute;right:20mm;bottom:2mm;font-size:7px;">Página [[page_cu]] de [[page_nb]]</div></page_footer>', $html);
}
