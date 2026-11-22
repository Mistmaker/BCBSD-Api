<?php
require_once __DIR__ . '/../../../classes/auth.php';
$auth = requireAuth();
require_once __DIR__ . '/../../../classes/operadores.php';
require_once __DIR__ . '/../../../classes/documentos.php';
// GET ?id=N -> PDF de la licencia del operador (sustento). Los documentos nunca se sirven directamente desde la carpeta.
apiMetodo(['GET']);
try {
    $id = apiParamId();
    if ($id === null) {
        jsonResponse(['error' => 'Falta el operador (?id=)'], 400);
    }
    $db = new Database();
    requirePermiso($db, 'ADM_OPERADORES', 'ADM_OPERADOR_GESTIONAR');
    $db->query('SELECT conductor_pdf FROM tthh.tb_conductores WHERE conductor_id = :id');
    $db->bind(':id', $id);
    $fila = $db->single();
    if (!$fila) {
        jsonResponse(['error' => 'Operador no encontrado'], 404);
    }
    docEnviarPdf((string) $fila['conductor_pdf'], basename((string) $fila['conductor_pdf']) ?: 'licencia.pdf');
} catch (Throwable $e) {
    apiError($e, 'Error al obtener la licencia');
}
