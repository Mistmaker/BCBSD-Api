<?php
require_once __DIR__ . '/../../../classes/auth.php';
$auth = requireAuth();
require_once __DIR__ . '/../../../classes/api.php';
require_once __DIR__ . '/../../../classes/mantenimiento.php';
// GET          -> estado de mantenimiento de todos los vehículos activos (alertas)
// GET ?id=N    -> estado de un vehículo (para precargar una orden nueva)
// Respuesta por vehículo: km actual, plan, último mantenimiento, último preventivo y la regla más urgente.
apiMetodo(['GET']);
try {
    $db = new Database();
    $tolerancia = (int) parametro($db, 'MANT_TOLERANCIA_KM', 1000);
    $id = apiParamId();

    $vehiculos = mantEstadoVehiculos($db, $tolerancia, $id);
    if ($id !== null && !$vehiculos) {
        jsonResponse(['error' => 'Vehículo no encontrado'], 404);
    }
    jsonResponse($id !== null ? $vehiculos[0] : $vehiculos);
} catch (Throwable $e) {
    apiError($e, 'Error al calcular el estado de los vehículos');
}
