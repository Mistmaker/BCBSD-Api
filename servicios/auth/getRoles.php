<?php
require_once __DIR__ . '/../../classes/auth.php';
$auth = requireAuth();
require_once __DIR__ . '/../../classes/api.php';
// GET -> rol_id de los privilegios efectivos (perfil + adicionales) del usuario CONECTADO.
// Ya no acepta ?id de otro usuario (exponía los privilegios de cualquiera).
apiMetodo(['GET']);
try {
    $usuario = authUsuarioId();
    if ($usuario === null) {
        jsonResponse([]);
    }
    $db = new Database();
    jsonResponse(array_map('intval', array_column(privilegiosUsuario($db, $usuario), 'rol_id')));
} catch (Throwable $e) {
    apiError($e, 'Error al obtener los privilegios');
}
