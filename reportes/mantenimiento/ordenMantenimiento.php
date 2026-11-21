<?php
require_once __DIR__ . '/../../classes/auth.php';
$auth = requireAuth();
require_once __DIR__ . '/../../classes/reporteMantenimiento.php';
require_once __DIR__ . '/../../vendor/autoload.php';
// GET ?id=N&doc=orden    -> Orden de mantenimiento (pág. 1 trabajos a realizar; pág. 2 con sugeridos del taller, si hay)
// GET ?id=N&doc=informe  -> Informe de mantenimiento individual (recepción conforme y facturas)
// GET ?id=N&doc=acta     -> Acta entrega-recepción de satisfacción vehicular
apiMetodo(['GET']);
$doc = $_GET['doc'] ?? 'orden';
if (!in_array($doc, ['orden', 'informe', 'acta'], true)) {
    jsonResponse(['error' => 'Documento inválido'], 400);
}
try {
    $db = new Database();
    $id = apiParamId();
    $orden = $id ? mantDatosOrden($db, $id) : null;
    if (!$orden) {
        jsonResponse(['error' => 'Orden no encontrada'], 404);
    }
    $inst = reporteInstitucion($db);
    $o = $orden;
    $no = mantNumero($o['orden_serie']);
    $institucion = mb_strtoupper($inst['sistema_nombre']);

    if ($doc === 'orden') {
        $datos = '<table class="datos">
            <tr><td colspan="4"><b>DATOS DE MANTENIMIENTO A REALIZAR</b></td></tr>
            <tr><td class="lbl">VEHICULO:</td><td class="val">' . e($o['vehiculo_sigla']) . '</td><td class="lbl">PLACAS:</td><td class="val">' . e($o['vehiculo_placa']) . '</td></tr>
            <tr><td class="lbl">NO. MOTOR:</td><td class="val">' . e($o['vehiculo_motor']) . '</td><td class="lbl">NO. CHASIS:</td><td class="val">' . e($o['vehiculo_chasis']) . '</td></tr>
            <tr><td class="lbl">KM. ACTUAL:</td><td class="val">' . e((float) $o['orden_km_mantenimiento']) . '</td><td class="lbl">FECHA:</td><td class="val">' . e(mantFecha($o['orden_fecha_mantenimiento'])) . '</td></tr>
            <tr><td class="lbl">TIPO MANTENIMIENTO:</td><td class="val">' . e($o['orden_tipomantenimiento']) . '</td><td class="lbl">KM. PRÓXIMO MTO. PREVENTIVO:</td><td class="val">' . e($o['orden_proximomantenimiento'] ?? '—') . '</td></tr>
            <tr><td class="lbl">SOLICITADO POR:</td><td colspan="3">' . e($o['s_nombre']) . '<br><b>' . e($o['s_puesto']) . '</b></td></tr>
            <tr><td colspan="4"><b>DATOS DE ÚLTIMO MANTENIMIENTO REALIZADO</b></td></tr>
            <tr><td class="lbl">KM. ÚLTIMO MANTENIMIENTO:</td><td class="val">' . e($o['ultimo_km_mantenimiento'] !== null ? (float) $o['ultimo_km_mantenimiento'] : '—') . '</td>
                <td class="lbl">FECHA ÚLTIMO MANTENIMIENTO:</td><td class="val">' . e($o['ultimo_fecha_mantenimiento'] ?? '—') . '</td></tr>
        </table>';
        $pie = mantTablaLista('ANEXOS', $o['anexos'], 'anexo_descripcion')
            . '<table class="t" style="margin-top:4mm;"><tr><td style="width:100%;"><b>OBSERVACIONES:</b></td></tr><tr><td>' . nl2br(e($o['orden_observaciones'])) . '</td></tr></table>'
            . '<div style="font-size:9px;margin-top:2mm;">Firmas de Responsabilidad:</div>'
            . '<table style="width:100%;margin-top:22mm;"><tr>'
            . '<td style="width:50%;">' . reporteFirma($o['t_nombre'], $o['t_cc'], $o['tecnico_puesto'], 'ELABORADO POR') . '</td>'
            . '<td style="width:50%;">' . reporteFirma($o['da_nombre'], $o['da_cc'], $o['da_puesto'], 'AUTORIZADO POR') . '</td></tr></table>';
        $pagina = function (bool $conSugeridos) use ($o, $no, $datos, $pie) {
            return '<div class="title-single" style="text-align:center;margin:4mm 0 6mm;">ORDEN DE MANTENIMIENTO No. ' . e($no) . '</div>' . $datos
                . mantTablaLista('TRABAJOS A REALIZAR', $o['trabajos'], 'trabajo_descripcion')
                . ($conSugeridos ? mantTablaLista('TRABAJOS SUGERIDOS POR EL TALLER', $o['sugeridos'], 'trabajo_descripcion') : '')
                . $pie;
        };
        $cuerpo = $pagina(false) . ($o['sugeridos'] ? '<div style="page-break-before:always;"></div>' . $pagina(true) : '');
        $cabecera = ['DIRECCIÓN ADMINISTRATIVA', 'MANTENIMIENTO VEHICULAR', 'ORDEN DE MANTENIMIENTO', $o['orden_codigo']];
        $titulo = 'Orden de mantenimiento ' . $o['orden_codigo'];
    } elseif ($doc === 'informe') {
        $lista = implode('<br>', array_map(fn($t) => '- ' . e($t), array_column($o['trabajos'], 'trabajo_descripcion')));
        $cuerpo = reporteTituloArea($inst)
            . '<div class="title-single" style="text-align:center;margin-bottom:6mm;">NO. ' . e($no) . '</div>'
            . '<div class="texto">Por medio del presente le informo que se procedió a validar la información presentada por ' . e($o['taller'] ?: '________________')
            . ', y se confirma la <b>RECEPCIÓN CONFORME</b> del <b>SERVICIO DE MANTENIMIENTO ' . e($o['orden_tipomantenimiento']) . '</b> de la unidad <b>' . e($o['vehiculo_sigla'])
            . '</b> perteneciente al <b>' . e($institucion) . '</b>, según se detalla a continuación:</div>'
            . '<table class="datos" style="margin-top:3mm;"><tr><td style="width:50%;"><b>VEHICULO:</b> ' . e($o['vehiculo_sigla']) . '</td><td style="width:50%;"><b>PLACAS:</b> ' . e($o['vehiculo_placa']) . '</td></tr>'
            . '<tr><td><b>NO. MOTOR:</b> ' . e($o['vehiculo_motor']) . '</td><td><b>NO. CHASIS:</b> ' . e($o['vehiculo_chasis']) . '</td></tr></table>'
            . '<div style="font-size:11px;margin-top:2mm;">' . $lista . '</div>'
            . reporteTablaFacturas($o['facturas'])
            . '<div style="font-size:9px;margin-top:8mm;">Atentamente,</div>'
            . '<div style="font-size:8px;margin-top:20mm;">' . e($o['t_nombre']) . '<br><b>' . e($o['t_puesto']) . '</b></div>';
        $cabecera = ['DIRECCIÓN ADMINISTRATIVA', 'MANTENIMIENTO VEHICULAR', 'INFORME DE MANTENIMIENTO', $o['orden_codigo']];
        $titulo = 'Informe de mantenimiento No. ' . $no;
    } else {
        $trabajos = mantTrabajosRealizados($o);
        $lista = '';
        foreach ($trabajos as $i => $t) {
            $lista .= ($i + 1) . '. ' . e($t) . '<br>';
        }
        $cuerpo = reporteTituloArea($inst)
            . '<div class="title-single" style="text-align:center;margin-bottom:6mm;">ACTA ENTREGA RECEPCIÓN DE SATISFACCIÓN VEHICULAR</div>'
            . '<div class="texto">En la ciudad de ' . e($inst['sistema_ciudad']) . ', a los <b>' . e(fechaEnLetras($o['orden_fecha_recepcion'] ?: null))
            . '</b>, comparecen los señores <b>' . e($o['t_nombre']) . '</b>, ' . e($o['t_puesto']) . ' y <b>' . e($o['s_nombre']) . '</b>, ' . e($o['s_puesto'])
            . ', solicitante del mantenimiento del vehículo <b>' . e($o['vehiculo_sigla']) . '</b> perteneciente al <b>' . e($institucion)
            . '</b>, quienes constituyen con el objeto a suscribir la presente Acta de Entrega-Recepción del vehículo ' . e($o['vehiculo_marca'])
            . ', de placa <b>' . e($o['vehiculo_placa']) . '</b>, registrado con siglas <b>' . e($o['vehiculo_sigla'])
            . '</b>, el mismo que se encontró en perfecto estado de funcionamiento después de haberse realizado el mantenimiento ' . e(mb_strtolower($o['orden_tipomantenimiento']))
            . ' en <b>' . e($o['taller'] ?: '________________') . '</b>, el mismo que se detalla a continuación:</div>'
            . '<div style="font-size:11px;margin:3mm 0 3mm 8mm;">' . $lista . '</div>'
            . '<div class="texto">Leída y aceptada que fuere la presente acta, la suscriben en dos ejemplares del mismo contenido, administrador de contrato, el área requirente y contratista.</div>'
            . '<table style="width:100%;margin-top:22mm;"><tr>'
            . '<td style="width:50%;">' . reporteFirma($o['s_nombre'], $o['s_cc'], $o['s_puesto'], 'RECIBE CONFORME') . '</td>'
            . '<td style="width:50%;">' . reporteFirma($o['t_nombre'], $o['t_cc'], $o['tecnico_puesto'], 'ENTREGA CONFORME') . '</td></tr></table>';
        $cabecera = ['DIRECCIÓN ADMINISTRATIVA', 'SERVICIOS GENERALES', 'ACTA ENTREGA RECEPCIÓN DE SATISFACCIÓN VEHICULAR', $o['orden_codigo']];
        $titulo = 'Acta entrega recepción ' . $o['orden_codigo'];
    }
    reporteSalida(reporteHtml($inst, $cabecera, $cuerpo), $titulo, str_replace(' ', '_', $titulo) . '.pdf');
} catch (Throwable $e) {
    apiError($e, 'No se pudo generar el reporte');
}
