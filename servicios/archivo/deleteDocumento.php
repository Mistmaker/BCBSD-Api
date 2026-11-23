<?php
require_once __DIR__ . '/../../classes/auth.php';
$auth = requireAuth();
require_once __DIR__ . '/../../classes/borrado.php';
// DELETE ?id=N -> borrado lógico del documento (documento_estado = ELIMINADO, con quién y cuándo). Solo usuarios administrativos.
apiMetodo(['DELETE']);
try {
    $id = apiParamId() ?? jsonResponse(['error' => 'Falta el id'], 400);
    $usuario = authUsuarioId() ?? jsonResponse(['error' => 'No autorizado'], 403);
    $db = new Database();
    borrarLogico($db, 'archivo.documentos', 'documento_id', $id, 'documento_estado', 'ELIMINADO', '', [],
        ['documento_eliminado_por' => $usuario, 'documento_eliminado_en' => date('Y-m-d H:i:s')]);
} catch (Throwable $e) {
    apiError($e, 'Error al eliminar el documento');
}
