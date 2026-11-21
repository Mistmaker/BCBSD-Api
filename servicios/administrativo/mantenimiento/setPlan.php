<?php
require_once __DIR__ . '/../../../classes/auth.php';
$auth = requireAuth();
require_once __DIR__ . '/../../../classes/api.php';
require_once __DIR__ . '/../../../classes/mantenimiento.php';
// POST -> crea un plan; PUT (con plan_id) -> lo actualiza.
// Cuerpo: { plan_modelo, plan_observaciones, plan_estado,
//           reglas: [{ mantenimiento_km_inicio, mantenimiento_km_intervalo, recursos: [recurso_id, ...] }],
//           vehiculos: [vehiculo_id, ...] }   (opcional: vehículos que usan este plan)
$metodo = apiMetodo(['POST', 'PUT']);
$p = apiCuerpoJson();
$db = null;
try {
    if (trim((string) prop($p, 'plan_modelo', '')) === '') {
        throw new ValidacionException('El modelo es obligatorio');
    }
    $reglas = (array) prop($p, 'reglas', []);
    if (count($reglas) === 0) {
        throw new ValidacionException('El plan debe tener al menos una regla de kilometraje');
    }
    foreach ($reglas as $regla) {
        $inicio = prop($regla, 'mantenimiento_km_inicio', 0);
        $intervalo = prop($regla, 'mantenimiento_km_intervalo');
        if (!is_numeric($intervalo) || $intervalo <= 0 || !is_numeric($inicio) || $inicio < 0) {
            throw new ValidacionException('Cada regla necesita un intervalo mayor a 0 y un km inicial mayor o igual a 0');
        }
    }
    $usuario = authUsuarioId();
    $db = new Database();
    $db->beginTransaction();
    if ($metodo === 'POST') {
        $db->query('INSERT INTO logistica.tb_planesmantenimiento (fk_usuario_id, plan_modelo, plan_observaciones) VALUES (:u, :m, :o) RETURNING plan_id');
        $db->bind(':u', $usuario);
    } else {
        if (!prop($p, 'plan_id')) {
            throw new ValidacionException('Falta plan_id');
        }
        $db->query('UPDATE logistica.tb_planesmantenimiento SET plan_modelo = :m, plan_observaciones = :o, plan_estado = :e WHERE plan_id = :id RETURNING plan_id');
        $db->bind(':id', (int) $p->plan_id);
        $db->bind(':e', prop($p, 'plan_estado', 'ACTIVO'));
    }
    $db->bind(':m', mb_strtoupper(trim($p->plan_modelo)));
    $db->bind(':o', prop($p, 'plan_observaciones'));
    $fila = $db->single();
    if (!$fila) {
        $db->cancelTransaction();
        jsonResponse(['error' => 'Plan no encontrado'], 404);
    }
    $planId = (int) $fila['plan_id'];

    // Las reglas se reemplazan completas (sus recursos se borran en cascada)
    $db->query('DELETE FROM logistica.tb_reglasmantenimiento WHERE fk_plan_id = :id');
    $db->bind(':id', $planId);
    $db->execute();
    foreach ($reglas as $regla) {
        $db->query('INSERT INTO logistica.tb_reglasmantenimiento (fk_usuario_id, fk_plan_id, mantenimiento_km_inicio, mantenimiento_km_intervalo)
                    VALUES (:u, :p, :i, :n) RETURNING mantenimiento_id');
        $db->bind(':u', $usuario);
        $db->bind(':p', $planId);
        $db->bind(':i', (int) prop($regla, 'mantenimiento_km_inicio', 0));
        $db->bind(':n', (int) $regla->mantenimiento_km_intervalo);
        $reglaId = (int) $db->single()['mantenimiento_id'];
        foreach (array_unique(array_map('intval', (array) prop($regla, 'recursos', []))) as $recursoId) {
            $db->query('INSERT INTO logistica.tb_mantenimiento_recursos (fk_mantenimiento_id, fk_recurso_id) VALUES (:r, :rec)');
            $db->bind(':r', $reglaId);
            $db->bind(':rec', $recursoId);
            $db->execute();
        }
    }

    if (property_exists($p, 'vehiculos')) {
        $ids = array_map('intval', (array) $p->vehiculos);
        $db->query('UPDATE administrativo.tb_vehiculos SET fk_plan_id = NULL WHERE fk_plan_id = :p');
        $db->bind(':p', $planId);
        $db->execute();
        foreach ($ids as $vehiculoId) {
            $db->query('UPDATE administrativo.tb_vehiculos SET fk_plan_id = :p WHERE vehiculo_id = :v');
            $db->bind(':p', $planId);
            $db->bind(':v', $vehiculoId);
            $db->execute();
        }
    }
    $db->endTransaction();
    jsonResponse(['msg' => 'Plan guardado', 'id' => $planId], $metodo === 'POST' ? 201 : 200);
} catch (Throwable $e) {
    $db?->cancelTransaction();
    apiError($e, 'No se pudo guardar el plan');
}
