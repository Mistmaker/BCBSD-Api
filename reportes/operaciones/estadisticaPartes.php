<?php
require_once __DIR__ . '/../../classes/auth.php';
$auth = requireAuth();
require_once __DIR__ . '/../../classes/informePartes.php';
require_once __DIR__ . '/../../vendor/autoload.php';
// POST { desde, hasta, estacion, tipo, graficos: { mes, vehiculo, bombero, recurso, auxilio, hora } (PNG en base64) }
// -> PDF del informe estadístico de partes (A4 vertical). Las cifras se recalculan en el servidor.
// Privilegio: el mismo del tablero (OPE_PARTES_ESTADISTICAS).
apiMetodo(['POST']);
$p = apiCuerpoJson();
$graficos = [];
try {
    $db = new Database();
    requirePermiso($db, 'OPE_PARTES_ESTADISTICAS');
    $f = informePartesFiltros($p);
    $graficos = informeGraficos(prop($p, 'graficos'), INFORME_PARTES_GRAFICOS);
    $html = informePartesHtml($db, $f, $graficos, informeAutor($db, (int) authUsuarioId()));
    reporteSalida($html, 'Estadística de partes de servicio', 'Estadistica_partes_' . $f['desde'] . '_' . $f['hasta'] . '.pdf');
} catch (Throwable $e) {
    apiError($e, 'No se pudo generar el informe estadístico');
} finally {
    informeLimpiar($graficos);
}
