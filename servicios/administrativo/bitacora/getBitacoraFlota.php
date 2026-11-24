<?php
require_once __DIR__ . '/../../../classes/auth.php';
$auth = requireAuth();
require_once __DIR__ . '/../../../classes/bitacoraDatos.php';
// GET ?desde=Y-m-d&hasta=Y-m-d (por defecto últimos 12 meses)
// -> indicadores por vehículo activo: km recorridos, rendimiento y costo de combustible, gasto y frecuencia de mantenimiento,
//    costo total por km, comparación con vehículos de la misma marca/modelo/año y número de alertas.
apiMetodo(['GET']);
try {
    [$desde, $hasta] = bitRango();
    $db = new Database();
    requirePermiso($db, 'ADM_BITACORA_VEHICULOS');
    jsonResponse(bitFlota($db, $desde, $hasta));
} catch (Throwable $e) {
    apiError($e, 'Error al calcular la bitácora de la flota');
}
