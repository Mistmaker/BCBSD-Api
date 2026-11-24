<?php
/*
 * Utilidades para reportes PDF (spipu/html2pdf) con la cabecera y el pie institucionales.
 * Los datos de la institución salen de admin.tb_sistema; si no existe el registro se usan los de CBSD.
 */
require_once __DIR__ . '/api.php';

use Spipu\Html2Pdf\Html2Pdf;

const REPORTE_INSTITUCION_POR_DEFECTO = [
    'sistema_nombre' => 'CUERPO DE BOMBEROS SANTO DOMINGO',
    'sistema_siglas' => 'CBSD',
    'sistema_slogan' => 'Juntos hacia el crecimiento institucional',
    'sistema_ciudad' => 'Santo Domingo',
    'sistema_direccion' => 'Av. Jacinto Cortez y Jorge Icaza',
    'sistema_telefono' => '(02) 3959-340',
    'sistema_correo' => 'info@cbsd.gob.ec',
    'sistema_sitioweb' => 'http://bomberosantodomingo.gob.ec',
    'sistema_facebook' => '/CuerpoDeBomberosSantoDomingo',
    'sistema_twitter' => '@BomberosSD',
];

function reporteInstitucion(Database $db): array
{
    return array_merge(REPORTE_INSTITUCION_POR_DEFECTO, array_filter(institucion($db), fn($v) => $v !== null && $v !== ''));
}

/** Escapa texto para HTML. */
function e($valor): string
{
    return htmlspecialchars((string) ($valor ?? ''), ENT_QUOTES, 'UTF-8');
}

// ---------------------------------------------------------------- números y fechas en letras

function numeroEnLetras(int $n, bool $apocope = false): string
{
    if ($n === 0) {
        return 'CERO';
    }
    $unidades = ['', 'UNO', 'DOS', 'TRES', 'CUATRO', 'CINCO', 'SEIS', 'SIETE', 'OCHO', 'NUEVE', 'DIEZ', 'ONCE', 'DOCE', 'TRECE',
        'CATORCE', 'QUINCE', 'DIECISÉIS', 'DIECISIETE', 'DIECIOCHO', 'DIECINUEVE', 'VEINTE', 'VEINTIUNO', 'VEINTIDÓS', 'VEINTITRÉS',
        'VEINTICUATRO', 'VEINTICINCO', 'VEINTISÉIS', 'VEINTISIETE', 'VEINTIOCHO', 'VEINTINUEVE'];
    $decenas = [3 => 'TREINTA', 'CUARENTA', 'CINCUENTA', 'SESENTA', 'SETENTA', 'OCHENTA', 'NOVENTA'];
    $centenas = [1 => 'CIENTO', 'DOSCIENTOS', 'TRESCIENTOS', 'CUATROCIENTOS', 'QUINIENTOS', 'SEISCIENTOS', 'SETECIENTOS', 'OCHOCIENTOS', 'NOVECIENTOS'];

    $menorMil = function (int $n) use ($unidades, $decenas, $centenas): string {
        if ($n === 100) {
            return 'CIEN';
        }
        $partes = [];
        if ($n >= 100) {
            $partes[] = $centenas[intdiv($n, 100)];
            $n %= 100;
        }
        if ($n >= 30) {
            $partes[] = $decenas[intdiv($n, 10)] . ($n % 10 ? ' Y ' . $unidades[$n % 10] : '');
        } elseif ($n > 0) {
            $partes[] = $unidades[$n];
        }
        return implode(' ', $partes);
    };

    $partes = [];
    $millones = intdiv($n, 1000000);
    $miles = intdiv($n % 1000000, 1000);
    $resto = $n % 1000;
    if ($millones) {
        $partes[] = $millones === 1 ? 'UN MILLÓN' : numeroEnLetras($millones, true) . ' MILLONES';
    }
    if ($miles) {
        $partes[] = $miles === 1 ? 'MIL' : preg_replace(['/VEINTIUNO$/', '/UNO$/'], ['VEINTIÚN', 'UN'], $menorMil($miles)) . ' MIL';
    }
    if ($resto) {
        $partes[] = $menorMil($resto);
    }
    $texto = implode(' ', $partes);
    if ($apocope) { // "veintiún dólares", "treinta y un dólares"
        $texto = preg_replace(['/VEINTIUNO$/', '/UNO$/'], ['VEINTIÚN', 'UN'], $texto);
    }
    return $texto;
}

/** 466.10 -> "CUATROCIENTOS SESENTA Y SEIS DÓLARES CON DIEZ CENTAVOS" */
function montoEnLetras(float $monto): string
{
    $centavosTotales = (int) round($monto * 100);
    $dolares = intdiv($centavosTotales, 100);
    $centavos = $centavosTotales % 100;
    $texto = numeroEnLetras($dolares, true) . ($dolares === 1 ? ' DÓLAR' : ' DÓLARES');
    if ($dolares >= 1000000 && $dolares % 1000000 === 0) {
        $texto = numeroEnLetras($dolares, true) . ' DE DÓLARES';
    }
    return $texto . ' CON ' . numeroEnLetras($centavos, true) . ($centavos === 1 ? ' CENTAVO' : ' CENTAVOS');
}

const REPORTE_MESES = ['ENERO', 'FEBRERO', 'MARZO', 'ABRIL', 'MAYO', 'JUNIO', 'JULIO', 'AGOSTO', 'SEPTIEMBRE', 'OCTUBRE', 'NOVIEMBRE', 'DICIEMBRE'];

/** '2026-06-01' -> "01 DÍAS DEL MES DE JUNIO DE 2026" */
function fechaEnLetras(?string $fecha): string
{
    $t = $fecha ? strtotime($fecha) : time();
    return date('d', $t) . ' DÍAS DEL MES DE ' . REPORTE_MESES[(int) date('n', $t) - 1] . ' DE ' . date('Y', $t);
}

function dinero($valor): string
{
    return '$ ' . number_format((float) $valor, 2, '.', ',');
}

// ---------------------------------------------------------------- página

/**
 * Arma el HTML completo: cabecera (área, documento, código), escudo de fondo, pie institucional y cuerpo.
 * $lineasCabecera: líneas del bloque azul superior izquierdo (la última va en negrita).
 * $marcaAgua: imagen de fondo de reportes/recursos/img-reports/ (escudo.jpg o escudo-tenue.jpg).
 */
function reporteHtml(array $inst, array $lineasCabecera, string $cuerpo, string $marcaAgua = 'escudo.jpg'): string
{
    $recursos = realpath(__DIR__ . '/../reportes/recursos');
    $estilos = file_get_contents($recursos . '/style.css');
    $estilos = str_replace(['{{margin_left}}', '{{margin_right}}'], ['20', '20'], $estilos);
    $ultima = array_pop($lineasCabecera);
    $cabecera = implode('<br>', array_map('e', $lineasCabecera)) . '<br><b>' . e($ultima) . '</b>';

    $header = file_get_contents($recursos . '/../formatos/HEADER_PROCESS_CBSD.html');
    $footer = file_get_contents($recursos . '/../formatos/FOOTER_PAGE_MAIN.html');
    $html = '<style>' . $estilos . '
        .t{width:100%;border-collapse:collapse;font-size:9px;}
        .t td,.t th{border:1px solid #222d32;padding:5px;}
        .t th{background:none;color:black;font-weight:bold;text-align:center;}
        .datos{width:100%;font-size:9px;} .datos td{padding:4px 2px;vertical-align:middle;}
        .lbl{font-weight:bold;width:22%;} .val{width:28%;}
        .bloque{background:#d0d0d0;font-size:12px;font-weight:bold;text-align:center;}
        .texto{font-size:11px;text-align:justify;line-height:1.4;}
        .firma{font-size:8px;text-align:center;}
    </style>
    <page backtop="38mm" backbottom="38mm" backleft="20mm" backright="20mm">'
        . $header . $footer . $cuerpo . '</page>';

    $reemplazos = [
        '{{report_info_entity}}' => $cabecera,
        // marca de agua tenue (como en los formatos del sistema anterior)
        // escudo-tenue.jpg: para informes con gráficos (deja leer mejor los datos)
        '../reportes/recursos/escudo.png' => $recursos . '/img-reports/' . basename($marcaAgua),
        '../reportes/recursos/' => $recursos . '/',
        '{{sistema_direccion}}' => e($inst['sistema_direccion']),
        '{{sistema_telefono}}' => e($inst['sistema_telefono']),
        '{{sistema_correo}}' => e($inst['sistema_correo']),
        '{{sistema_sitioweb}}' => e($inst['sistema_sitioweb']),
        '{{SYSTEM_FACEBOOK_URI}}' => e($inst['sistema_facebook']),
        '{{SYSTEM_TWITTER_URI}}' => e($inst['sistema_twitter']),
    ];
    return strtr($html, $reemplazos);
}

/** Tabla "FACTURAS GENERADAS" con total y monto en letras. */
function reporteTablaFacturas(array $facturas): string
{
    $filas = '';
    $total = 0;
    $i = 0;
    foreach ($facturas as $f) {
        if ($f['factura_valor'] === null && trim((string) $f['factura_descripcion']) === '') {
            continue;
        }
        $total += (float) $f['factura_valor'];
        $numero = $f['factura_descripcion'] ?: $f['factura_numero'];
        $filas .= '<tr><td style="width:8%;text-align:center;">' . ++$i . '</td><td style="width:37%;">' . e($numero) . '</td><td style="width:37%;">'
            . e($f['factura_tipo']) . '</td><td style="width:18%;text-align:right;">' . dinero($f['factura_valor']) . '</td></tr>';
    }
    return '<table class="t" style="margin-top:4mm;">'
        . '<tr><th colspan="4" style="padding:8px;">FACTURAS GENERADAS</th></tr>'
        . '<tr><th style="width:8%;">ITEM</th><th style="width:37%;">NO. FACTURA</th><th style="width:37%;">DETALLE</th><th style="width:18%;">VALOR</th></tr>'
        . ($filas ?: '<tr><td colspan="4" style="text-align:center;">Sin valores registrados</td></tr>')
        . '<tr><td colspan="3" style="text-align:center;">COSTO TOTAL DE MANTENIMIENTO</td><td style="text-align:right;"><b>' . dinero($total) . '</b></td></tr>'
        . '<tr><td colspan="4" style="text-align:center;"><b>' . e(montoEnLetras($total)) . '</b></td></tr>'
        . '</table>';
}

/** Carga una plantilla de reportes/formatos/ y reemplaza {{variable}} (los valores ya deben venir escapados). */
function reportePlantilla(string $rutaRelativa, array $variables): string
{
    $html = file_get_contents(__DIR__ . '/../reportes/formatos/' . $rutaRelativa);
    $pares = [];
    foreach ($variables as $clave => $valor) {
        $pares['{{' . $clave . '}}'] = (string) $valor;
    }
    return strtr($html, $pares);
}

/** Genera el PDF y lo envía al navegador (inline). */
function reporteSalida(string $html, string $titulo, string $archivo): void
{
    $pdf = new Html2Pdf('P', 'A4', 'es', true, 'UTF-8', [0, 0, 0, 0]);
    $pdf->pdf->SetDisplayMode('real');
    $pdf->pdf->SetCreator('BCBSD');
    $pdf->pdf->SetTitle($titulo);
    $pdf->writeHTML($html);
    $pdf->output($archivo);
}
