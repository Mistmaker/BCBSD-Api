<?php
require_once __DIR__ . '/../../classes/auth.php';
$auth = requireAuth();
require_once __DIR__ . '/../../classes/reporteMantenimiento.php';
require_once __DIR__ . '/../../vendor/autoload.php';
// GET ?id=N -> Informe de mantenimiento de grupo (bitácora): todas las órdenes del informe con sus facturas y el total a cancelar
apiMetodo(['GET']);
try {
    $db = new Database();
    $id = apiParamId();
    $db->query("SELECT i.*, concat(t.persona_apellidos, ' ', t.persona_nombres) AS t_nombre, t.puesto_nombre AS t_puesto,
                       concat(da.persona_apellidos, ' ', da.persona_nombres) AS da_nombre, da.puesto_nombre AS da_puesto
                  FROM logistica.tb_informemantenimiento i
                  LEFT JOIN tthh.vw_personal_simple t ON t.ppersonal_id = i.tecnico_servicios
                  LEFT JOIN tthh.vw_personal_simple da ON da.ppersonal_id = i.director_administrativo
                 WHERE i.informe_id = :id");
    $db->bind(':id', (int) $id);
    $informe = $id ? $db->single() : null;
    if (!$informe) {
        jsonResponse(['error' => 'Informe no encontrado'], 404);
    }
    $db->query('SELECT io.fk_orden_id FROM logistica.tb_informe_ordenesmantenimiento io
                  JOIN logistica.tb_ordenesmantenimiento o ON o.orden_id = io.fk_orden_id
                 WHERE io.fk_informe_id = :id ORDER BY o.orden_fecha_mantenimiento, o.orden_id');
    $db->bind(':id', (int) $id);
    $ids = array_column($db->resultset(), 'fk_orden_id');
    $inst = reporteInstitucion($db);
    $taller = $informe['informe_taller'] ?: '________________';

    $bloques = '';
    $totalGeneral = 0;
    foreach ($ids as $n => $ordenId) {
        $o = mantDatosOrden($db, (int) $ordenId);
        $trabajos = implode('<br>', array_map(fn($t) => '&nbsp;&nbsp;- ' . e($t), mantTrabajosRealizados($o)));
        foreach ($o['facturas'] as $f) {
            $totalGeneral += (float) $f['factura_valor'];
        }
        $bloques .= '<nobreak><table class="t" style="margin-top:5mm;">'
            . '<tr><td class="bloque" style="width:100%;padding:6px;">ORDEN DE MANTENIMIENTO NÚMERO ' . ($n + 1) . ' - ' . e($o['vehiculo_sigla']) . '</td></tr>'
            . '<tr><td style="font-size:8px;line-height:1.3;">'
            . '<b>UNIDAD/PLACA:</b> ' . e($o['vehiculo_sigla']) . ' / ' . e($o['vehiculo_placa']) . '<br>'
            . '<b>NO. MOTOR/CHASIS:</b> ' . e($o['vehiculo_motor']) . ' / ' . e($o['vehiculo_chasis']) . '<br>'
            . '<b>FECHA DE MANTENIMIENTO:</b> ' . e($o['orden_fecha_mantenimiento']) . '<br>'
            . '<b>KM DE MANTENIMIENTO:</b> ' . e($o['orden_km_mantenimiento']) . '<br>'
            . '<b>TRABAJOS REALIZADOS:</b><br>' . $trabajos . '<br><br>'
            . '<b>SOLICITADO POR:</b> ' . e($o['s_nombre']) . ', ' . e($o['s_puesto'])
            . '</td></tr></table>' . reporteTablaFacturas($o['facturas']) . '</nobreak>';
    }

    $cuerpo = reporteTituloArea($inst)
        . '<div class="title-single" style="text-align:center;margin-bottom:6mm;">' . e($informe['informe_numero']) . '</div>'
        . '<div class="texto">Por medio de la presente tengo el agrado de informar que se procedió a validar la información presentada por <b>' . e($taller)
        . '</b>, y se confirma la <b>RECEPCIÓN CONFORME</b> del <b>SERVICIO DE MANTENIMIENTO PREVENTIVO Y CORRECTIVO</b> de las unidades pertenecientes al <b>'
        . e(mb_strtoupper($inst['sistema_nombre'])) . '</b>, según se detalla a continuación:</div>'
        . ($informe['informe_detalle'] ? '<div class="texto" style="margin-top:2mm;">' . nl2br(e($informe['informe_detalle'])) . '</div>' : '')
        . $bloques
        . '<div style="font-size:12px;margin-top:8mm;">Valor total a cancelar: <b>' . dinero($totalGeneral) . '</b> (' . e(montoEnLetras($totalGeneral)) . ')<br>'
        . 'Cancelar a favor de: <b>' . e($taller) . '</b></div>'
        . '<div style="font-size:9px;margin-top:8mm;">Atentamente,</div>'
        . '<nobreak><div style="font-size:8px;margin-top:20mm;">' . e($informe['t_nombre']) . '<br><b>' . e($informe['t_puesto']) . '</b><br><b>' . e($informe['tecnico_cargo']) . '</b></div>'
        . '<table class="t" style="width:60%;margin-top:2mm;"><tr><td style="width:25%;">ACCIÓN</td><td style="width:55%;">NOMBRE</td><td style="width:20%;">FIRMA</td></tr>'
        . '<tr><td>REVISADO POR</td><td>' . e($informe['da_nombre']) . '<br><b style="font-size:7px;">' . e($informe['da_puesto']) . '</b></td><td></td></tr></table></nobreak>';

    $cabecera = ['DIRECCIÓN ADMINISTRATIVA', 'MANTENIMIENTO VEHICULAR', 'INFORME DE MANTENIMIENTO', $informe['informe_numero']];
    reporteSalida(reporteHtml($inst, $cabecera, $cuerpo), 'Informe de mantenimiento ' . $informe['informe_numero'], 'Informe_mantenimiento.pdf');
} catch (Throwable $e) {
    apiError($e, 'No se pudo generar el reporte');
}
