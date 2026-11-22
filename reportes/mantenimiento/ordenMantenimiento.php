<?php
require_once __DIR__ . '/../../classes/auth.php';
$auth = requireAuth();
require_once __DIR__ . '/../../classes/reporteMantenimiento.php';
require_once __DIR__ . '/../../vendor/autoload.php';
// GET ?id=N&doc=orden    -> Orden de mantenimiento (pág. 1 trabajos a realizar; pág. 2 con sugeridos del taller, si hay)
// GET ?id=N&doc=informe  -> Informe de mantenimiento individual (recepción conforme y facturas)
// GET ?id=N&doc=acta     -> Acta entrega-recepción de satisfacción vehicular
// Formatos editables: reportes/formatos/mantenimiento/{orden,informe,acta}.html
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
    $v = mantVariablesOrden($orden, $inst);

    if ($doc === 'orden') {
        $cuerpo = mantPlantilla('orden.html', $v);
        if ($orden['sugeridos']) {
            $v['sugeridos_html'] = mantTablaLista('TRABAJOS SUGERIDOS POR EL TALLER', $orden['sugeridos'], 'trabajo_descripcion');
            $cuerpo .= '<div style="page-break-before:always;"></div>' . mantPlantilla('orden.html', $v);
        }
        $cabecera = ['DIRECCIÓN ADMINISTRATIVA', 'MANTENIMIENTO VEHICULAR', 'ORDEN DE MANTENIMIENTO', $orden['orden_codigo']];
        $titulo = 'Orden de mantenimiento ' . $orden['orden_codigo'];
    } elseif ($doc === 'informe') {
        $cuerpo = mantPlantilla('informe.html', $v);
        $cabecera = ['DIRECCIÓN ADMINISTRATIVA', 'MANTENIMIENTO VEHICULAR', 'INFORME DE MANTENIMIENTO', $orden['orden_codigo']];
        // Lleva el número de serie de la orden para que ambos documentos queden vinculados (el número del informe de pago es aparte)
        $titulo = 'Informe de mantenimiento No. ' . mantNumero($orden['orden_serie']);
    } else {
        $cuerpo = mantPlantilla('acta.html', $v);
        $cabecera = ['DIRECCIÓN ADMINISTRATIVA', 'SERVICIOS GENERALES', 'ACTA ENTREGA RECEPCIÓN DE SATISFACCIÓN VEHICULAR', $orden['orden_codigo']];
        $titulo = 'Acta entrega recepcion ' . $orden['orden_codigo'];
    }
    reporteSalida(reporteHtml($inst, $cabecera, $cuerpo), $titulo, str_replace(' ', '_', $titulo) . '.pdf');
} catch (Throwable $e) {
    apiError($e, 'No se pudo generar el reporte');
}
