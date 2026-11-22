<?php
require_once __DIR__ . '/../../../classes/auth.php';
$auth = requireAuth();
require_once __DIR__ . '/../../../classes/operadores.php';
// GET ?cedula=X -> si la persona ya existe: sus datos, si ya es funcionario (puesto EN FUNCIONES) y si ya es operador.
// Sirve para el ingreso rápido: si ya es funcionario solo falta la licencia; si ya es operador se edita el existente.
apiMetodo(['GET']);
try {
    $cedula = trim((string) ($_GET['cedula'] ?? ''));
    if ($cedula === '') {
        jsonResponse(['error' => 'Falta la cédula (?cedula=)'], 400);
    }
    $db = new Database();
    requirePermiso($db, 'ADM_OPERADORES', 'ADM_OPERADOR_GESTIONAR');
    $dias = (int) parametro($db, 'OPER_DIAS_AVISO_LICENCIA', 30);
    $db->query("SELECT pe.persona_id, pe.persona_doc_identidad, pe.persona_nombres, pe.persona_apellidos, p.personal_id, p.personal_estado,
                       pp.ppersonal_id, pu.puesto_nombre, pu.puesto_modalidad
                  FROM resources.tb_personas pe
                  LEFT JOIN tthh.tb_personal p ON p.fk_persona_id = pe.persona_id
                  LEFT JOIN tthh.tb_personal_puestos pp ON pp.fk_personal_id = p.personal_id AND pp.ppersonal_estado = 'EN FUNCIONES'
                  LEFT JOIN tthh.tb_puestos pu ON pu.puesto_id = pp.fk_puesto_id
                 WHERE pe.persona_doc_identidad = :c
                 ORDER BY (pp.ppersonal_id IS NOT NULL) DESC, p.personal_id DESC NULLS LAST, pp.ppersonal_id DESC NULLS LAST LIMIT 1");
    $db->bind(':c', $cedula);
    $persona = $db->single() ?: null;
    $operador = null;
    if ($persona && $persona['personal_id']) {
        $operador = operListar($db, 'AND p.fk_persona_id = :p', [':p' => (int) $persona['persona_id']])[0] ?? null;
        $operador = $operador ? operCompletar($operador, $dias) : null;
    }
    jsonResponse(['cedula_valida' => operCedulaValida($cedula), 'persona' => $persona, 'operador' => $operador]);
} catch (Throwable $e) {
    apiError($e, 'Error al buscar la persona');
}
