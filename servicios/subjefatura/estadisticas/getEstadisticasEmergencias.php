<?php
require_once __DIR__ . '/../../../classes/auth.php';
$auth = requireAuth();
require_once __DIR__ . '/../../../classes/partes.php';
// GET ?desde=AAAA-MM-DD&hasta=AAAA-MM-DD[&estacion=N]  (por defecto el año en curso)
// -> panel de la Subjefatura: emergencias de los partes de servicio, por mes y por tipo (incendio y auxilio por separado:
//    lugar, hora y día, causas, tipos de incendio / naturaleza / área / causante, clasificación del auxilio) y puntos del mapa.
// Privilegio: SBJ_ESTADISTICAS.
apiMetodo(['GET']);
try {
    $db = new Database();
    requirePermiso($db, 'SBJ_ESTADISTICAS');
    try {
        $desde = parteFecha($_GET['desde'] ?? date('Y') . '-01-01', 'desde', true);
        $hasta = parteFecha($_GET['hasta'] ?? date('Y-m-d'), 'hasta', true);
    } catch (ValidacionException $e) {
        jsonResponse(['error' => $e->getMessage()], 400);
    }
    if ($desde > $hasta) {
        jsonResponse(['error' => 'La fecha inicial es posterior a la final'], 400);
    }
    if ((new DateTime($desde))->diff(new DateTime($hasta))->days > 366 * 5) {
        jsonResponse(['error' => 'El período no puede superar 5 años'], 400);
    }
    jsonResponse(parteEstadisticasEmergencias($db, $desde, $hasta, apiParamId('estacion')));
} catch (Throwable $e) {
    apiError($e, 'Error al calcular la estadística de emergencias');
}
