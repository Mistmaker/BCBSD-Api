<?php
require_once __DIR__ . '/../../classes/auth.php';
$auth = requireAuth();
require_once __DIR__ . '/../../classes/partes.php';
// POST { parte_id } -> vuelve a generar la imagen de ubicación del parte (p. ej. si el servidor de mapas no respondió
// al guardar, o para partes anteriores). Privilegio: OPE_PARTE_REGISTRAR.
apiMetodo(['POST']);
$p = apiCuerpoJson();
try {
    $db = new Database();
    requirePermiso($db, 'OPE_PARTE_REGISTRAR');
    $id = (int) prop($p, 'parte_id', 0);
    $db->query('SELECT parte_estado FROM operaciones.tb_partes WHERE parte_id = :id');
    $db->bind(':id', $id);
    $estado = $db->single()['parte_estado'] ?? null;
    if ($estado === null) {
        jsonResponse(['error' => 'Parte no encontrado'], 404);
    }
    if ($estado === 'ANULADO') {
        throw new ValidacionException('El parte está anulado');
    }
    $r = parteActualizarMapa($db, $id);
    if ($r === null) {
        throw new ValidacionException('El parte no tiene coordenadas: marque la ubicación en el mapa y guarde el parte');
    }
    $r ? jsonResponse(['msg' => 'Imagen del mapa generada', 'mapa' => true])
       : jsonResponse(['error' => 'Servidor de mapas no disponible', 'msg' => 'No se pudo descargar el mapa; intente más tarde'], 503);
} catch (Throwable $e) {
    apiError($e, 'No se pudo generar la imagen del mapa');
}
