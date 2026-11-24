<?php
require_once __DIR__ . '/../../../classes/auth.php';
$auth = requireAuth();
require_once __DIR__ . '/../../../classes/bitacoraDatos.php';
// GET ?id=N&desde=Y-m-d&hasta=Y-m-d (por defecto últimos 12 meses)
// -> vehículo, historial (combustible, mantenimiento, movilización, partes) ordenado por fecha y km, indicadores,
//    tramos de rendimiento, gasto mensual, trabajos repetidos, comparación con vehículos iguales y alertas.
apiMetodo(['GET']);
try {
    [$desde, $hasta] = bitRango();
    $id = apiParamId();
    if ($id === null) {
        jsonResponse(['error' => 'Falta el vehículo (?id=)'], 400);
    }
    $db = new Database();
    requirePermiso($db, 'ADM_BITACORA_VEHICULOS');
    $r = bitVehiculo($db, $id, $desde, $hasta);
    if ($r === null) {
        jsonResponse(['error' => 'Vehículo no encontrado'], 404);
    }
    jsonResponse($r);
} catch (Throwable $e) {
    apiError($e, 'Error al calcular la bitácora del vehículo');
}
