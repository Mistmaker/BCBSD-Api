<?php
require_once __DIR__ . '/../../../classes/auth.php';
$auth = requireAuth();
require_once __DIR__ . '/../../../classes/api.php';
require_once __DIR__ . '/../../../classes/mantenimiento.php';
// GET                              -> contratos con totales (asignado, consumido, saldo)
// GET ?id=N                        -> contrato con partidas (saldo por rubro) y vehículos cubiertos
// GET ?vehiculo_id=N&vigentes=1    -> contratos vigentes que cubren al vehículo, con su saldo por rubro
apiMetodo(['GET']);
try {
    $db = new Database();
    $sqlLista = "SELECT c.*, concat(a.persona_apellidos, ' ', a.persona_nombres) AS administrador_nombre,
                        COALESCE((SELECT sum(asignado) FROM logistica.vw_contratosmantenimiento_saldo s WHERE s.contrato_id = c.contrato_id), 0) AS asignado,
                        COALESCE((SELECT sum(consumido) FROM logistica.vw_contratosmantenimiento_saldo s WHERE s.contrato_id = c.contrato_id), 0) AS consumido,
                        COALESCE((SELECT sum(saldo) FROM logistica.vw_contratosmantenimiento_saldo s WHERE s.contrato_id = c.contrato_id), 0) AS saldo,
                        (SELECT count(*) FROM logistica.tb_contratosmantenimiento_vehiculos cv WHERE cv.fk_contrato_id = c.contrato_id) AS vehiculos,
                        (SELECT count(*) FROM logistica.tb_ordenesmantenimiento o WHERE o.fk_contrato_id = c.contrato_id AND o.orden_estado <> 'ANULADA') AS ordenes
                   FROM logistica.tb_contratosmantenimiento c
                   LEFT JOIN tthh.vw_personal_simple a ON a.ppersonal_id = c.administrador_contrato";

    $id = apiParamId();
    if ($id !== null) {
        $db->query($sqlLista . ' WHERE c.contrato_id = :id');
        $db->bind(':id', $id);
        $contrato = $db->single();
        if (!$contrato) {
            jsonResponse(['error' => 'Contrato no encontrado'], 404);
        }
        $db->query('SELECT * FROM logistica.vw_contratosmantenimiento_saldo WHERE contrato_id = :id ORDER BY partida_id');
        $db->bind(':id', $id);
        $contrato['partidas'] = $db->resultset();
        $db->query('SELECT v.vehiculo_id, v.vehiculo_sigla, v.vehiculo_placa FROM logistica.tb_contratosmantenimiento_vehiculos cv
                      JOIN administrativo.tb_vehiculos v ON v.vehiculo_id = cv.fk_vehiculo_id WHERE cv.fk_contrato_id = :id ORDER BY v.vehiculo_sigla');
        $db->bind(':id', $id);
        $contrato['vehiculos'] = $db->resultset();
        jsonResponse($contrato);
    }

    $vehiculo = apiParamId('vehiculo_id');
    $where = [];
    if (!empty($_GET['vigentes'])) {
        $where[] = "c.contrato_estado = 'VIGENTE'";
    }
    if ($vehiculo !== null) {
        $where[] = '(NOT EXISTS (SELECT 1 FROM logistica.tb_contratosmantenimiento_vehiculos cv WHERE cv.fk_contrato_id = c.contrato_id)
                     OR EXISTS (SELECT 1 FROM logistica.tb_contratosmantenimiento_vehiculos cv WHERE cv.fk_contrato_id = c.contrato_id AND cv.fk_vehiculo_id = :v))';
    }
    // Primero los contratos específicos (vigencia tecnológica) del vehículo, luego los generales
    $db->query($sqlLista . ($where ? ' WHERE ' . implode(' AND ', $where) : '') . ' ORDER BY c.contrato_estado DESC, vehiculos DESC, c.contrato_fecha_inicio DESC NULLS LAST, c.contrato_id DESC');
    if ($vehiculo !== null) {
        $db->bind(':v', $vehiculo);
    }
    $contratos = $db->resultset();
    if ($contratos) {
        $db->query('SELECT * FROM logistica.vw_contratosmantenimiento_saldo ORDER BY partida_id');
        $partidas = $db->resultset();
        foreach ($contratos as &$c) {
            $c['partidas'] = array_values(array_filter($partidas, fn($p) => $p['contrato_id'] == $c['contrato_id']));
        }
    }
    jsonResponse($contratos);
} catch (Throwable $e) {
    apiError($e, 'Error al obtener contratos');
}
