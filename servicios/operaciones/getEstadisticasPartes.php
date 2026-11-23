<?php
require_once __DIR__ . '/../../classes/auth.php';
$auth = requireAuth();
require_once __DIR__ . '/../../classes/partes.php';
// GET ?desde=AAAA-MM-DD&hasta=AAAA-MM-DD[&estacion=N&tipo=AUXILIO|INCENDIO]  (por defecto: el año en curso)
// -> resumen, por mes, estación, vehículo, bombero, recurso (equipos/herramientas, material, insumos), tipo de auxilio,
//    causa, día de la semana y hora del aviso. Partes anulados excluidos. Privilegio: OPE_PARTES_ESTADISTICAS.
apiMetodo(['GET']);
try {
    $db = new Database();
    requirePermiso($db, 'OPE_PARTES_ESTADISTICAS');
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
    $tipo = strtoupper(trim($_GET['tipo'] ?? '')) ?: null;
    if ($tipo !== null && !in_array($tipo, PARTE_TIPOS, true)) {
        jsonResponse(['error' => 'Tipo inválido'], 400);
    }
    jsonResponse(parteEstadisticas($db, $desde, $hasta, apiParamId('estacion'), $tipo));
} catch (Throwable $e) {
    apiError($e, 'Error al calcular la estadística de partes');
}
