<?php
require_once __DIR__ . '/../../../classes/auth.php';
$auth = requireAuth();
require_once __DIR__ . '/../../../classes/peticionMateriales.php';
// POST -> crea: { peticion_fecha, peticion_lugar, peticion_destino, peticion_autorizado_para (ADQUISICION|BODEGA|null),
//                 solicitante_id, solicitante_cargo, autoriza_id, autoriza_cargo, peticion_observaciones,
//                 detalle: [{ detalle_cantidad, detalle_unidad, detalle_descripcion }] }  -> { id, peticion_codigo }
// PUT  -> edita (con peticion_id) mientras esté EMITIDA; reemplaza los ítems.
//         Anular: { peticion_id, peticion_estado: 'ANULADA', peticion_observaciones: motivo }.
// Privilegio: ADM_PETICION_MATERIALES_GESTIONAR.
$metodo = apiMetodo(['POST', 'PUT']);
$p = apiCuerpoJson();
$db = null;
try {
    $usuario = authUsuarioId();
    if ($usuario === null) {
        jsonResponse(['error' => 'No autorizado'], 403);
    }
    $db = new Database();
    requirePermiso($db, 'ADM_PETICION_MATERIALES_GESTIONAR');
    $siglas = institucion($db)['sistema_siglas'];
    $id = (int) prop($p, 'peticion_id', 0);

    // Anulación
    if ($metodo === 'PUT' && prop($p, 'peticion_estado') === 'ANULADA') {
        $motivo = trim((string) prop($p, 'peticion_observaciones', ''));
        if ($motivo === '') {
            throw new ValidacionException('Indique el motivo de la anulación');
        }
        $db->query("UPDATE logistica.tb_peticionesmateriales SET peticion_estado = 'ANULADA', peticion_observaciones = :m
                     WHERE peticion_id = :id AND peticion_estado = 'EMITIDA' RETURNING peticion_codigo");
        $db->bind(':m', $motivo);
        $db->bind(':id', $id);
        $fila = $db->single();
        $fila ? jsonResponse(['msg' => 'Petición anulada', 'id' => $id, 'peticion_codigo' => $fila['peticion_codigo']])
              : jsonResponse(['error' => 'No encontrada', 'msg' => 'La petición no existe o ya está anulada'], 404);
    }

    $items = pdmValidar($p);
    $para = prop($p, 'peticion_autorizado_para') ?: null;
    $fecha = (string) prop($p, 'peticion_fecha', date('Y-m-d'));
    $texto = fn($v) => trim(preg_replace('/\s+/', ' ', (string) $v)) ?: null;
    $db->beginTransaction();

    if ($metodo === 'PUT') {
        $db->query('SELECT peticion_estado, peticion_codigo FROM logistica.tb_peticionesmateriales WHERE peticion_id = :id FOR UPDATE');
        $db->bind(':id', $id);
        $actual = $db->single();
        if (!$actual) {
            $db->cancelTransaction();
            jsonResponse(['error' => 'Petición no encontrada'], 404);
        }
        if ($actual['peticion_estado'] !== 'EMITIDA') {
            throw new ValidacionException('Una petición anulada no se puede editar');
        }
        $codigo = $actual['peticion_codigo'];
        $db->query('UPDATE logistica.tb_peticionesmateriales SET peticion_fecha = :f, peticion_lugar = :l, peticion_destino = :d, peticion_autorizado_para = :ap,
                           solicitante_id = :s, solicitante_cargo = :sc, autoriza_id = :a, autoriza_cargo = :ac, peticion_observaciones = :o
                     WHERE peticion_id = :id');
        $db->bind(':id', $id);
    } else {
        // Numeración por año (bloqueo para que dos usuarios no obtengan el mismo número)
        $anio = (int) substr($fecha, 0, 4);
        $db->query("SELECT pg_advisory_xact_lock(hashtext('logistica.tb_peticionesmateriales.serie'))");
        $db->execute();
        $db->query('SELECT COALESCE(MAX(peticion_serie), 0) + 1 AS serie FROM logistica.tb_peticionesmateriales WHERE peticion_anio = :a');
        $db->bind(':a', $anio);
        $serie = (int) $db->single()['serie'];
        $codigo = mantCodigo($siglas, PDM_TIPO, $serie, $anio);
        $db->query('INSERT INTO logistica.tb_peticionesmateriales (fk_usuario_id, peticion_codigo, peticion_anio, peticion_serie, peticion_fecha, peticion_lugar,
                           peticion_destino, peticion_autorizado_para, solicitante_id, solicitante_cargo, autoriza_id, autoriza_cargo, peticion_observaciones)
                    VALUES (:u, :c, :an, :se, :f, :l, :d, :ap, :s, :sc, :a, :ac, :o) RETURNING peticion_id');
        $db->bind(':u', $usuario);
        $db->bind(':c', $codigo);
        $db->bind(':an', $anio);
        $db->bind(':se', $serie);
    }
    $db->bind(':f', $fecha);
    $db->bind(':l', $texto(prop($p, 'peticion_lugar')));
    $db->bind(':d', $texto(prop($p, 'peticion_destino')));
    $db->bind(':ap', $para);
    $db->bind(':s', (int) $p->solicitante_id);
    $db->bind(':sc', $texto(prop($p, 'solicitante_cargo')));
    $db->bind(':a', prop($p, 'autoriza_id') ? (int) $p->autoriza_id : null);
    $db->bind(':ac', $texto(prop($p, 'autoriza_cargo')));
    $db->bind(':o', $texto(prop($p, 'peticion_observaciones')));
    if ($metodo === 'PUT') {
        $db->execute();
    } else {
        $id = (int) $db->single()['peticion_id'];
    }

    $db->query('DELETE FROM logistica.tb_peticionesmateriales_detalle WHERE fk_peticion_id = :id');
    $db->bind(':id', $id);
    $db->execute();
    foreach ($items as $i => $item) {
        $db->query('INSERT INTO logistica.tb_peticionesmateriales_detalle (fk_peticion_id, detalle_orden, detalle_cantidad, detalle_unidad, detalle_descripcion)
                    VALUES (:id, :o, :c, :u, :d)');
        $db->bind(':id', $id);
        $db->bind(':o', $i + 1);
        $db->bind(':c', (string) $item['detalle_cantidad']);
        $db->bind(':u', $item['detalle_unidad']);
        $db->bind(':d', $item['detalle_descripcion']);
        $db->execute();
    }
    $db->endTransaction();
    jsonResponse(['msg' => $metodo === 'PUT' ? 'Petición actualizada' : 'Petición registrada', 'id' => $id, 'peticion_codigo' => $codigo], $metodo === 'PUT' ? 200 : 201);
} catch (Throwable $e) {
    $db?->cancelTransaction();
    apiError($e, 'Error al guardar la petición de materiales');
}
