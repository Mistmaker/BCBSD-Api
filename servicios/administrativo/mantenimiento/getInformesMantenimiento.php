<?php
require_once __DIR__ . '/../../../classes/auth.php';
$auth = requireAuth();
require_once __DIR__ . '/../../../classes/api.php';
require_once __DIR__ . '/../../../classes/mantenimiento.php';
// GET          -> listado de informes
// GET ?id=N    -> informe con sus órdenes (incluye trabajos de cada orden)
apiMetodo(['GET']);
try {
    $db = new Database();
    $id = apiParamId();
    if ($id === null) {
        $db->query('SELECT * FROM logistica.vw_informemantenimiento ORDER BY informe_id DESC');
        jsonResponse($db->resultset());
    }
    $db->query('SELECT * FROM logistica.vw_informemantenimiento WHERE informe_id = :id');
    $db->bind(':id', $id);
    $informe = $db->single();
    if (!$informe) {
        jsonResponse(['error' => 'Informe no encontrado'], 404);
    }
    $db->query('SELECT o.* FROM logistica.vw_ordenesmantenimiento o
                  JOIN logistica.tb_informe_ordenesmantenimiento io ON io.fk_orden_id = o.orden_id
                 WHERE io.fk_informe_id = :id ORDER BY o.orden_fecha_mantenimiento');
    $db->bind(':id', $id);
    $ordenes = $db->resultset();
    if ($ordenes) {
        $db->query('SELECT fk_orden_id, trabajo_descripcion FROM logistica.tb_mantenimiento_trabajos
                     WHERE fk_orden_id IN (SELECT fk_orden_id FROM logistica.tb_informe_ordenesmantenimiento WHERE fk_informe_id = :id) ORDER BY trabajo_id');
        $db->bind(':id', $id);
        $trabajos = $db->resultset();
        foreach ($ordenes as &$orden) {
            $orden['trabajos'] = array_values(array_filter($trabajos, fn($t) => $t['fk_orden_id'] == $orden['orden_id']));
        }
    }
    $informe['ordenes_detalle'] = $ordenes;
    jsonResponse($informe);
} catch (Throwable $e) {
    apiError($e, 'Error al obtener informes de mantenimiento');
}
