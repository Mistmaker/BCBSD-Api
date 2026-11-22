<?php
require_once __DIR__ . '/../../../classes/auth.php';
$auth = requireAuth();
require_once __DIR__ . '/../../../classes/api.php';
require_once __DIR__ . '/../../../classes/mantenimiento.php';
// GET                    -> listado de órdenes
// GET ?vehiculo_id=N     -> órdenes de un vehículo
// GET ?sin_informe=1     -> órdenes no anuladas que aún no están en un informe (para armar informes)
// GET ?id=N              -> orden con trabajos, sugeridos, facturas y anexos
// GET ?siguiente_serie=1 -> siguiente número de orden del año (botón +1)
// GET ?siguiente_informe=1 -> siguiente número de informe de pago según MANT_FORMATO_INFORME (botón +1)
// GET ?contrato_id=N     -> órdenes de un contrato
apiMetodo(['GET']);
try {
    $db = new Database();
    if (!empty($_GET['siguiente_serie'])) {
        $db->query("SELECT COALESCE(MAX(orden_serie), 0) + 1 AS serie FROM logistica.tb_ordenesmantenimiento
                     WHERE orden_estado <> 'ANULADA' AND date_part('year', orden_registro) = date_part('year', CURRENT_DATE)");
        jsonResponse(['orden_serie' => (int) $db->single()['serie']]);
    }
    if (!empty($_GET['siguiente_informe'])) {
        $formato = parametro($db, 'MANT_FORMATO_INFORME', '{SIGLAS}-{AA}-INF-{NNN}');
        $siglas = institucion($db)['sistema_siglas'];
        $db->query("SELECT COALESCE(MAX(orden_informe_serie), 0) + 1 AS serie FROM logistica.tb_ordenesmantenimiento
                     WHERE orden_estado <> 'ANULADA' AND date_part('year', orden_registro) = date_part('year', CURRENT_DATE)");
        $serie = (int) $db->single()['serie'];
        jsonResponse(['orden_informe_numero' => mantFormatoInforme($formato, $siglas, $serie), 'orden_informe_serie' => $serie]);
    }
    $id = apiParamId();
    if ($id !== null) {
        $db->query('SELECT * FROM logistica.vw_ordenesmantenimiento WHERE orden_id = :id');
        $db->bind(':id', $id);
        $orden = $db->single();
        if (!$orden) {
            jsonResponse(['error' => 'Orden no encontrada'], 404);
        }
        foreach (['trabajos' => 'tb_mantenimiento_trabajos ORDER BY trabajo_id', 'sugeridos' => 'tb_mantenimiento_sugeridos ORDER BY trabajo_id',
                  'facturas' => 'tb_mantenimiento_facturas ORDER BY factura_id', 'anexos' => 'tb_mantenimiento_anexos ORDER BY anexo_id'] as $clave => $tabla) {
            [$nombre, $orden_por] = explode(' ORDER BY ', $tabla);
            $db->query("SELECT * FROM logistica.$nombre WHERE fk_orden_id = :id ORDER BY $orden_por");
            $db->bind(':id', $id);
            $orden[$clave] = $db->resultset();
        }
        jsonResponse($orden);
    }

    $where = [];
    $vehiculo = apiParamId('vehiculo_id');
    if ($vehiculo !== null) {
        $where[] = 'fk_vehiculo_id = :v';
    }
    if (!empty($_GET['sin_informe'])) {
        // Para la bitácora: órdenes con valores registrados (RECIBIDO o ENTREGADO) que no están en otra bitácora
        $where[] = "orden_estado IN ('RECIBIDO', 'ENTREGADO') AND informe_id IS NULL";
    }
    $contrato = apiParamId('contrato_id');
    if ($contrato !== null) {
        $where[] = 'fk_contrato_id = :c';
    }
    $db->query('SELECT * FROM logistica.vw_ordenesmantenimiento' . ($where ? ' WHERE ' . implode(' AND ', $where) : '') . ' ORDER BY orden_id DESC');
    if ($vehiculo !== null) {
        $db->bind(':v', $vehiculo);
    }
    if ($contrato !== null) {
        $db->bind(':c', $contrato);
    }
    jsonResponse($db->resultset());
} catch (Throwable $e) {
    apiError($e, 'Error al obtener órdenes de mantenimiento');
}
