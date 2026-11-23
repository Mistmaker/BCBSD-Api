<?php
require_once __DIR__ . '/../../classes/auth.php';
$auth = requireAuth();
require_once __DIR__ . '/../../classes/reporteParte.php';
require_once __DIR__ . '/../../vendor/autoload.php';
// GET ?id=N -> PDF del parte de servicio para imprimir y firmar (formato del área operativa).
// Plantilla editable: reportes/formatos/operaciones/parte.html. Privilegio: OPE_PARTES.
apiMetodo(['GET']);
try {
    $db = new Database();
    requirePermiso($db, 'OPE_PARTES');
    $id = apiParamId();
    $r = $id ? parteReporteHtml($db, $id) : null;
    if (!$r) {
        jsonResponse(['error' => 'Parte no encontrado'], 404);
    }
    reporteSalida($r['html'], $r['titulo'], str_replace(' ', '_', $r['titulo']) . '.pdf');
} catch (Throwable $e) {
    apiError($e, 'No se pudo generar el PDF del parte');
}
