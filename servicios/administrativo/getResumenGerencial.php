<?php
require_once __DIR__ . '/../../classes/auth.php';
$auth = requireAuth();
require_once __DIR__ . '/../../classes/resumenGerencial.php';
// GET ?mes=AAAA-MM (por defecto el mes actual) -> resumen gerencial de la Dirección Administrativa (servicios generales):
//   flota, gasto del mes y del año (combustible y mantenimiento), tendencia de 12 meses, contratos vigentes,
//   vehículos con alertas (mismos criterios de la bitácora), licencias de operadores y peticiones de materiales.
// Pensado para el director: cifras resumidas; el detalle está en la bitácora y en cada módulo. Privilegio: ADM_DASHBOARD.
apiMetodo(['GET']);
try {
    $mes = (string) ($_GET['mes'] ?? date('Y-m'));
    if (!preg_match('/^\d{4}-(0[1-9]|1[0-2])$/', $mes)) {
        jsonResponse(['error' => 'Mes inválido (AAAA-MM)'], 400);
    }
    $db = new Database();
    requirePermiso($db, 'ADM_DASHBOARD');
    jsonResponse(resumenGerencial($db, $mes));
} catch (Throwable $e) {
    apiError($e, 'Error al calcular el resumen gerencial');
}
