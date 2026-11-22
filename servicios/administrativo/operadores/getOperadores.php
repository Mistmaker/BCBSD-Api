<?php
require_once __DIR__ . '/../../../classes/auth.php';
$auth = requireAuth();
require_once __DIR__ . '/../../../classes/operadores.php';
// GET -> operadores con su licencia y vigencia (VIGENTE | POR VENCER | VENCIDA); ?id=N -> uno
apiMetodo(['GET']);
try {
    $db = new Database();
    requirePermiso($db, 'ADM_OPERADORES', 'ADM_OPERADOR_GESTIONAR');
    $dias = (int) parametro($db, 'OPER_DIAS_AVISO_LICENCIA', 30);
    $id = apiParamId();
    $filas = $id === null ? operListar($db) : operListar($db, 'AND c.conductor_id = :id', [':id' => $id]);
    $filas = array_map(fn($o) => operCompletar($o, $dias), $filas);
    if ($id !== null) {
        if (!$filas) {
            jsonResponse(['error' => 'Operador no encontrado'], 404);
        }
        jsonResponse($filas[0]);
    }
    jsonResponse($filas);
} catch (Throwable $e) {
    apiError($e, 'Error al obtener los operadores');
}
