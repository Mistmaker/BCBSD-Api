<?php
require_once __DIR__ . '/../../classes/auth.php';
$auth = requireAuth();
require_once __DIR__ . '/../../classes/usuarios.php';
// GET ?doc=X -> persona con ese documento (si existe), si es funcionario y si ya tiene usuario.
// Para crear el usuario de un funcionario o de una persona externa (p. ej. delegada de otra institución).
apiMetodo(['GET']);
try {
    $doc = trim((string) ($_GET['doc'] ?? ''));
    if ($doc === '') {
        jsonResponse(['error' => 'Falta el documento (?doc=)'], 400);
    }
    $db = new Database();
    requirePermiso($db, 'SIS_USUARIO_GESTIONAR');
    $db->query("SELECT pe.persona_id, pe.persona_tipo_doc, pe.persona_doc_identidad, pe.persona_nombres, pe.persona_apellidos,
                       pe.persona_correo, pe.persona_celular, f.ppersonal_id, f.puesto_nombre, f.puesto_modalidad
                  FROM resources.tb_personas pe
                  LEFT JOIN LATERAL (
                      SELECT pp.ppersonal_id, pu.puesto_nombre, pu.puesto_modalidad
                        FROM tthh.tb_personal p JOIN tthh.tb_personal_puestos pp ON pp.fk_personal_id = p.personal_id
                        LEFT JOIN tthh.tb_puestos pu ON pu.puesto_id = pp.fk_puesto_id
                       WHERE p.fk_persona_id = pe.persona_id AND pp.ppersonal_estado = 'EN FUNCIONES'
                       ORDER BY pp.ppersonal_id DESC LIMIT 1) f ON TRUE
                 WHERE pe.persona_doc_identidad = :d ORDER BY pe.persona_id LIMIT 1");
    $db->bind(':d', $doc);
    $persona = $db->single() ?: null;
    $usuario = $persona ? (usrListar($db, 'AND u.fk_persona_id = :p', [':p' => (int) $persona['persona_id']])[0] ?? null) : null;
    jsonResponse(['persona' => $persona, 'usuario' => $usuario]);
} catch (Throwable $e) {
    apiError($e, 'Error al buscar la persona');
}
