<?php
require_once __DIR__ . '/../../classes/auth.php';
$auth = requireAuth();
require_once __DIR__ . '/../../classes/informeResumenGerencial.php';
require_once __DIR__ . '/../../vendor/autoload.php';
// POST { mes: 'AAAA-MM', graficos: { gasto } (PNG en base64) } -> PDF del Resumen gerencial (A4 vertical).
// Las cifras se recalculan en el servidor. Privilegio: el del tablero (ADM_DASHBOARD).
apiMetodo(['POST']);
$p = apiCuerpoJson();
$graficos = [];
try {
    $db = new Database();
    requirePermiso($db, 'ADM_DASHBOARD');
    $mes = informeMesValido($p);
    $graficos = informeGraficos(prop($p, 'graficos'), INFORME_RESUMEN_GRAFICOS);
    $html = informeResumenHtml($db, $mes, $graficos, informeAutor($db, (int) authUsuarioId()));
    reporteSalida($html, 'Resumen gerencial', "Resumen_gerencial_$mes.pdf");
} catch (Throwable $e) {
    apiError($e, 'No se pudo generar el resumen gerencial');
} finally {
    informeLimpiar($graficos);
}
