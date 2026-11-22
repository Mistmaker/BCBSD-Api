<?php
require_once __DIR__ . '/../../classes/auth.php';
$auth = requireAuth();
require_once __DIR__ . '/../../classes/reporteMantenimiento.php';
require_once __DIR__ . '/../../vendor/autoload.php';
// GET ?id=N -> Informe de mantenimiento de grupo (bitácora): todas las órdenes con sus facturas y el total a cancelar
// Formatos editables: reportes/formatos/mantenimiento/bitacora.html y bitacora_orden.html (bloque por orden)
apiMetodo(['GET']);
try {
    $db = new Database();
    $id = apiParamId();
    $db->query("SELECT i.*, concat(t.persona_apellidos, ' ', t.persona_nombres) AS t_nombre, t.puesto_nombre AS t_puesto,
                       concat(da.persona_apellidos, ' ', da.persona_nombres) AS da_nombre, da.puesto_nombre AS da_puesto, c.contrato_taller
                  FROM logistica.tb_informemantenimiento i
                  LEFT JOIN tthh.vw_personal_simple t ON t.ppersonal_id = i.tecnico_servicios
                  LEFT JOIN tthh.vw_personal_simple da ON da.ppersonal_id = i.director_administrativo
                  LEFT JOIN logistica.tb_contratosmantenimiento c ON c.contrato_id = i.fk_contrato_id
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
    $taller = $informe['informe_taller'] ?: ($informe['contrato_taller'] ?: '________________');

    $bloques = '';
    $total = 0;
    foreach ($ids as $n => $ordenId) {
        $o = mantDatosOrden($db, (int) $ordenId);
        $total += array_sum(array_map(fn($f) => (float) $f['factura_valor'], $o['facturas']));
        $v = mantVariablesOrden($o, $inst);
        $v['n'] = $n + 1;
        $v['trabajos_guion_html'] = $v['trabajos_realizados_guion_html'];
        $bloques .= mantPlantilla('bitacora_orden.html', $v);
    }

    $cuerpo = mantPlantilla('bitacora.html', [
        'slogan' => e($inst['sistema_slogan']), 'institucion' => e(mb_strtoupper($inst['sistema_nombre'])),
        'numero_informe' => e($informe['informe_numero']), 'taller' => e($taller),
        'detalle_html' => $informe['informe_detalle'] ? '<div class="texto" style="margin-top:2mm;">' . nl2br(e($informe['informe_detalle'])) . '</div>' : '',
        'ordenes_html' => $bloques, 'total' => dinero($total), 'total_letras' => e(montoEnLetras($total)),
        'tecnico_nombre' => e($informe['t_nombre']), 'tecnico_puesto' => e($informe['t_puesto']), 'tecnico_cargo' => e($informe['tecnico_cargo']),
        'director_nombre' => e($informe['da_nombre']), 'director_puesto' => e($informe['da_puesto']),
    ]);
    $cabecera = ['DIRECCIÓN ADMINISTRATIVA', 'MANTENIMIENTO VEHICULAR', 'INFORME DE MANTENIMIENTO', $informe['informe_numero']];
    reporteSalida(reporteHtml($inst, $cabecera, $cuerpo), 'Informe de mantenimiento ' . $informe['informe_numero'], 'Informe_mantenimiento.pdf');
} catch (Throwable $e) {
    apiError($e, 'No se pudo generar el reporte');
}
