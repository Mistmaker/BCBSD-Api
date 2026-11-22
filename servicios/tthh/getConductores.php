<?php
require_once __DIR__ . '/../../classes/auth.php';
$auth = requireAuth();
require_once __DIR__ . '/../../classes/operadores.php';
// GET -> operadores ACTIVOS y EN FUNCIONES para los selectores de movilización y combustible, con su licencia.
// Los que tienen la licencia vencida (o sin PDF, si OPER_BLOQUEAR_SIN_SUSTENTO = SI) vienen con disabled = true (no se pueden elegir) si OPER_BLOQUEAR_LICENCIA_VENCIDA = SI.
// ?id=N -> un operador (cualquier estado), para mostrar el de una orden ya emitida.
apiMetodo(['GET']);
try {
    $db = new Database();
    $dias = (int) parametro($db, 'OPER_DIAS_AVISO_LICENCIA', 30);
    $bloquear = strtoupper((string) parametro($db, 'OPER_BLOQUEAR_LICENCIA_VENCIDA', 'SI')) === 'SI';
    $exigirSustento = strtoupper((string) parametro($db, 'OPER_BLOQUEAR_SIN_SUSTENTO', 'NO')) === 'SI';
    $id = apiParamId();
    $filas = $id === null
        ? operListar($db, "AND c.conductor_estado = 'ACTIVO' AND pp.ppersonal_estado = 'EN FUNCIONES'")
        : operListar($db, 'AND c.conductor_id = :id', [':id' => $id]);
    $filas = array_map(function ($o) use ($dias, $bloquear, $exigirSustento) {
        $o = operCompletar($o, $dias, null, $exigirSustento);
        $licencia = trim('Lic. ' . ($o['licencia_categoria'] ?? '?'));
        $aviso = $o['licencia_vigencia'] === 'VENCIDA' ? ' (LICENCIA VENCIDA)'
            : ($exigirSustento && !$o['tiene_sustento'] ? ' (SIN PDF DE LICENCIA)' : ($o['licencia_vigencia'] === 'POR VENCER' ? ' (licencia por vencer)' : ''));
        $o['nombre_completo'] = trim("{$o['persona_apellidos']} {$o['persona_nombres']} - {$o['puesto_nombre']} · $licencia$aviso", ' -');
        $o['disabled'] = $bloquear && !$o['habilitado'];
        return $o;
    }, $filas);
    if ($id !== null) {
        $filas ? jsonResponse($filas[0]) : jsonResponse(['error' => 'Operador no encontrado'], 404);
    }
    jsonResponse($filas);
} catch (Throwable $e) {
    apiError($e, 'Error al obtener los conductores');
}
