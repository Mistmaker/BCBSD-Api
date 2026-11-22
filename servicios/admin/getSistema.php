<?php
require_once __DIR__ . '/../../classes/auth.php';
$auth = requireAuth();
require_once __DIR__ . '/../../classes/api.php';
// GET -> datos de la institución (nombre, siglas, logo, contacto) y parámetros por módulo (?modulo=MANTENIMIENTO)
apiMetodo(['GET']);
try {
    $db = new Database();
    $respuesta = institucion($db);
    if (!empty($_GET['modulo'])) {
        $db->query('SELECT param_key, param_value, param_type, param_name FROM admin.tb_params WHERE param_modulo = :m ORDER BY param_key');
        $db->bind(':m', (string) $_GET['modulo']);
        $respuesta['parametros'] = $db->resultset();
        if ($_GET['modulo'] === 'MANTENIMIENTO') {
            $puesto = (int) parametro($db, 'MANT_DIRECTOR_PUESTO_ID', 4);
            $db->query("SELECT ppersonal_id, nombre_completo FROM tthh.vw_personal_simple vps
                          JOIN tthh.tb_personal_puestos pp USING (ppersonal_id)
                         WHERE pp.fk_puesto_id = :p AND pp.ppersonal_estado = 'EN FUNCIONES' ORDER BY pp.ppersonal_id DESC LIMIT 1");
            $db->bind(':p', $puesto);
            $respuesta['director_administrativo'] = $db->single() ?: null;
        }
    }
    jsonResponse($respuesta);
} catch (Throwable $e) {
    apiError($e, 'Error al obtener los datos de la institución');
}
