<?php
require_once __DIR__ . '/../../classes/auth.php';
$auth = requireAuth();
require_once __DIR__ . '/../../classes/informeBitacora.php';
require_once __DIR__ . '/../../vendor/autoload.php';
// POST { id, desde, hasta, graficos: { rendimiento, gasto } (PNG en base64) } -> PDF del informe de la bitácora del vehículo
// (A4 vertical). Las cifras se recalculan en el servidor. Privilegio: el del tablero (ADM_BITACORA_VEHICULOS).
apiMetodo(['POST']);
$p = apiCuerpoJson();
$graficos = [];
try {
    $db = new Database();
    requirePermiso($db, 'ADM_BITACORA_VEHICULOS');
    $id = (int) prop($p, 'id', 0);
    if ($id <= 0) {
        throw new ValidacionException('Falta el vehículo');
    }
    [$desde, $hasta] = informeRango($p);
    $graficos = informeGraficos(prop($p, 'graficos'), INFORME_VEHICULO_GRAFICOS);
    $html = informeVehiculoHtml($db, $id, $desde, $hasta, $graficos, informeAutor($db, (int) authUsuarioId()));
    if ($html === null) {
        jsonResponse(['error' => 'Vehículo no encontrado'], 404);
    }
    reporteSalida($html, 'Bitácora del vehículo', "Bitacora_vehiculo_{$id}_{$desde}_{$hasta}.pdf");
} catch (Throwable $e) {
    apiError($e, 'No se pudo generar el informe del vehículo');
} finally {
    informeLimpiar($graficos);
}
