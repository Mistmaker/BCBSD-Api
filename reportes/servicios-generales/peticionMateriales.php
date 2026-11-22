<?php
require_once __DIR__ . '/../../classes/auth.php';
$auth = requireAuth();
require_once __DIR__ . '/../../classes/peticionMateriales.php';
require_once __DIR__ . '/../../classes/reporte.php';
require_once __DIR__ . '/../../vendor/autoload.php';
// GET ?id=N -> PDF de la petición de materiales para firmar. Formato editable:
//              reportes/formatos/servicios-generales/peticion_materiales.html
apiMetodo(['GET']);
try {
    $db = new Database();
    requirePermiso($db, 'ADM_PETICIONES_MATERIALES', 'ADM_PETICION_MATERIALES_GESTIONAR');
    $filasMinimas = (int) parametro($db, 'PDM_FILAS_MINIMAS', 15);
    $id = apiParamId();
    $p = $id ? (pdmListar($db, 'AND p.peticion_id = :id', [':id' => $id])[0] ?? null) : null;
    if (!$p) {
        jsonResponse(['error' => 'Petición no encontrada'], 404);
    }
    $inst = reporteInstitucion($db);
    $detalle = pdmDetalle($db, $id);

    $filas = '';
    foreach ($detalle as $d) {
        $filas .= '<tr><td style="width:15%;text-align:center;">' . e(pdmCantidad($d['detalle_cantidad'])) . '</td><td style="width:18%;text-align:center;">'
            . e($d['detalle_unidad']) . '</td><td style="width:67%;">' . e($d['detalle_descripcion']) . '</td></tr>';
    }
    for ($i = count($detalle); $i < $filasMinimas; $i++) {
        $filas .= '<tr><td style="width:15%;">&nbsp;</td><td style="width:18%;"></td><td style="width:67%;"></td></tr>';
    }
    $marca = fn($v) => $p['peticion_autorizado_para'] === $v ? '<b>(X)</b>' : '(&nbsp;&nbsp;)';
    $anulada = $p['peticion_estado'] === 'ANULADA'
        ? '<div style="text-align:center;color:#bf0411;font-size:14px;font-weight:bold;margin-bottom:3mm;">ANULADA: ' . e($p['peticion_observaciones']) . '</div>' : '';
    $cuerpo = reportePlantilla('servicios-generales/peticion_materiales.html', [
        'codigo' => e($p['peticion_codigo']),
        'anulada_html' => $anulada,
        'institucion' => e(mb_strtoupper($inst['sistema_nombre'])),
        'destino' => e($p['peticion_destino']),
        'filas_html' => $filas,
        'lugar_fecha' => e(pdmLugarFecha($p['peticion_lugar'], $p['peticion_fecha'])),
        'marca_adquisicion' => $marca('ADQUISICION'),
        'marca_bodega' => $marca('BODEGA'),
        'solicitante_nombre' => e($p['solicitante_nombre']),
        'solicitante_cargo' => e($p['solicitante_cargo'] ?: $p['solicitante_puesto']),
        'autoriza_nombre' => e($p['autoriza_nombre'] ?? ''),
        'autoriza_cargo' => e($p['autoriza_cargo'] ?: ($p['autoriza_puesto'] ?? '')),
        'observaciones_html' => $p['peticion_observaciones'] && $p['peticion_estado'] !== 'ANULADA'
            ? '<div style="font-size:9px;margin-top:3mm;"><b>Observaciones:</b> ' . nl2br(e($p['peticion_observaciones'])) . '</div>' : '',
    ]);
    $titulo = 'Peticion de materiales ' . $p['peticion_codigo'];
    reporteSalida(reporteHtml($inst, ['DIRECCIÓN ADMINISTRATIVA', 'SERVICIOS GENERALES', 'PETICIÓN DE MATERIALES', $p['peticion_codigo']], $cuerpo),
        $titulo, str_replace(' ', '_', $titulo) . '.pdf');
} catch (Throwable $e) {
    apiError($e, 'No se pudo generar la petición de materiales');
}
