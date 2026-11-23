<?php
require_once __DIR__ . '/../../classes/auth.php';
$auth = requireAuth();
require_once __DIR__ . '/../../classes/partes.php';
// GET ?id=N -> imagen PNG de la ubicación del parte (mapa con el marcador). Privilegio: OPE_PARTES.
apiMetodo(['GET']);
try {
    $db = new Database();
    requirePermiso($db, 'OPE_PARTES', 'OPE_PARTES_ESTADISTICAS');
    $id = apiParamId();
    $db->query('SELECT parte_mapa_archivo FROM operaciones.tb_partes WHERE parte_id = :id');
    $db->bind(':id', (int) $id);
    $ruta = $db->single()['parte_mapa_archivo'] ?? null;
    if (!$id || !mapaExiste($ruta)) {
        jsonResponse(['error' => 'El parte no tiene imagen del mapa'], 404);
    }
    mapaEnviar($ruta);
} catch (Throwable $e) {
    apiError($e, 'No se pudo obtener la imagen del mapa');
}
