<?php
require_once __DIR__ . '/../../../classes/auth.php';
$auth = requireAuth();
require_once __DIR__ . '/../../../classes/api.php';
require_once __DIR__ . '/../../../classes/mantenimiento.php';
// GET          -> listado de informes
// GET ?id=N    -> informe con sus órdenes (incluye trabajos de cada orden)
// GET ?siguiente=1 -> siguiente número de informe sugerido (botón +1)
// GET ?siguiente=1&contrato_id=N -> "BITÁCORA NN - CODIGO DEL CONTRATO" (NN = bitácoras del contrato + 1)
apiMetodo(['GET']);
try {
    $db = new Database();
    $contrato = apiParamId('contrato_id');
    if (!empty($_GET['siguiente']) && $contrato !== null) {
        $db->query("SELECT c.contrato_codigo, (SELECT count(*) FROM logistica.tb_informemantenimiento i
                       WHERE i.fk_contrato_id = c.contrato_id AND i.informe_estado <> 'ANULADO') + 1 AS n
                      FROM logistica.tb_contratosmantenimiento c WHERE c.contrato_id = :c");
        $db->bind(':c', $contrato);
        $f = $db->single();
        if ($f) {
            jsonResponse(['informe_numero' => sprintf('BITÁCORA %02d - %s', $f['n'], $f['contrato_codigo']), 'informe_serie' => 0]);
        }
    }
    if (!empty($_GET['siguiente'])) {
        $siglas = institucion($db)['sistema_siglas'];
        $db->query("SELECT COALESCE(MAX(informe_serie), 0) + 1 AS serie FROM logistica.tb_informemantenimiento
                     WHERE date_part('year', informe_registro) = date_part('year', CURRENT_DATE)");
        $serie = (int) $db->single()['serie'];
        jsonResponse(['informe_numero' => mantCodigo($siglas, 'INF', $serie), 'informe_serie' => $serie]);
    }
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
