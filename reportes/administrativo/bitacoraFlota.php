<?php
require_once __DIR__ . '/../../classes/auth.php';
$auth = requireAuth();
require_once __DIR__ . '/../../classes/informeBitacora.php';
require_once __DIR__ . '/../../vendor/autoload.php';
// POST { desde, hasta, graficos: { gasto } (PNG en base64) } -> PDF del informe de la bitácora de la flota (A4 vertical).
// Las cifras se recalculan en el servidor. Privilegio: el del tablero (ADM_BITACORA_VEHICULOS).
apiMetodo(['POST']);
$p = apiCuerpoJson();
$graficos = [];
try {
    $db = new Database();
    requirePermiso($db, 'ADM_BITACORA_VEHICULOS');
    [$desde, $hasta] = informeRango($p);
    $graficos = informeGraficos(prop($p, 'graficos'), INFORME_FLOTA_GRAFICOS);
    $html = informeFlotaHtml($db, $desde, $hasta, $graficos, informeAutor($db, (int) authUsuarioId()));
    reporteSalida($html, 'Bitácora de vehículos — flota', "Bitacora_flota_{$desde}_{$hasta}.pdf");
} catch (Throwable $e) {
    apiError($e, 'No se pudo generar el informe de la flota');
} finally {
    informeLimpiar($graficos);
}
