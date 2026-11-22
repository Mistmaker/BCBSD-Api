<?php
require_once __DIR__ . '/../../classes/auth.php';
$auth = requireAuth();
require_once __DIR__ . '/../../classes/partes.php';
// GET ?id=N -> parte completo con detalles.
// GET [?desde=AAAA-MM-DD&hasta=AAAA-MM-DD&estacion=N&tipo=AUXILIO|INCENDIO&estado=...&q=texto] -> listado (máx. 500, más recientes primero).
// Privilegio: OPE_PARTES.
apiMetodo(['GET']);
try {
    $db = new Database();
    requirePermiso($db, 'OPE_PARTES', 'OPE_PARTES_ESTADISTICAS');
    $id = apiParamId();
    if ($id !== null) {
        $parte = parteObtener($db, $id);
        $parte ? jsonResponse($parte) : jsonResponse(['error' => 'Parte no encontrado'], 404);
    }
    $donde = [];
    $params = [];
    foreach (['desde' => '>=', 'hasta' => '<='] as $k => $op) {
        if (!empty($_GET[$k])) {
            $donde[] = "p.parte_fecha $op :$k";
            $params[":$k"] = parteFecha($_GET[$k], $k);
        }
    }
    if ($e = apiParamId('estacion')) {
        $donde[] = 'p.fk_estacion_id = :e';
        $params[':e'] = $e;
    }
    if (!empty($_GET['tipo'])) {
        $donde[] = 'p.parte_tipo = :t';
        $params[':t'] = strtoupper($_GET['tipo']);
    }
    if (!empty($_GET['estado'])) {
        $donde[] = 'p.parte_estado = :s';
        $params[':s'] = strtoupper($_GET['estado']);
    }
    if (!empty($_GET['q'])) {
        $donde[] = "(p.parte_numero ILIKE :q OR p.parte_direccion ILIKE :q OR p.parte_sector ILIKE :q OR p.parte_codigo_salida ILIKE :q
                     OR EXISTS (SELECT 1 FROM operaciones.tb_partes_tipos_auxilio ta WHERE ta.fk_parte_id = p.parte_id
                                AND concat_ws(' ', ta.parte_auxilio_clasificacion, ta.parte_auxilio_subclasificacion) ILIKE :q))";
        $params[':q'] = '%' . trim($_GET['q']) . '%';
    }
    $db->query("SELECT p.parte_id, p.parte_numero, p.parte_tipo, p.parte_estado, p.parte_fecha::text AS parte_fecha,
                       to_char(p.parte_hora_aviso, 'HH24:MI') AS parte_hora_aviso, p.fk_estacion_id, e.estacion_nombre,
                       COALESCE(p.parte_direccion, p.parte_sector) AS parte_direccion, p.parte_sector, p.parte_total_heridos, p.parte_total_muertos,
                       (SELECT string_agg(DISTINCT concat_ws(' / ', ta.parte_auxilio_clasificacion, ta.parte_auxilio_subclasificacion), ', ')
                          FROM operaciones.tb_partes_tipos_auxilio ta WHERE ta.fk_parte_id = p.parte_id) AS tipos_auxilio,
                       (SELECT string_agg(COALESCE(pv.parte_vehiculo_siglas, pv.parte_vehiculo_placa), ', ' ORDER BY pv.parte_vehiculo_id)
                          FROM operaciones.tb_partes_vehiculos pv WHERE pv.fk_parte_id = p.parte_id) AS vehiculos,
                       concat_ws(' ', pe.persona_apellidos, pe.persona_nombres) AS al_mando
                  FROM operaciones.tb_partes p
                  LEFT JOIN operaciones.tb_estaciones e ON e.estacion_id = p.fk_estacion_id
                  LEFT JOIN tthh.tb_personal t ON t.personal_id = p.fk_personal_id
                  LEFT JOIN resources.tb_personas pe ON pe.persona_id = t.fk_persona_id"
        . ($donde ? ' WHERE ' . implode(' AND ', $donde) : '') . '
                 ORDER BY p.parte_fecha DESC, p.parte_id DESC LIMIT 500');
    foreach ($params as $k => $v) {
        $db->bind($k, $v);
    }
    jsonResponse($db->resultset());
} catch (Throwable $e) {
    apiError($e, 'Error al consultar los partes de servicio');
}
