<?php
require_once __DIR__ . '/../../../classes/auth.php';
$auth = requireAuth();
require_once __DIR__ . '/../../../classes/api.php';
require_once __DIR__ . '/../../../classes/mantenimiento.php';
// POST -> crea un informe; PUT (con informe_id) -> lo actualiza. Para anular: informe_estado = 'ANULADO'.
// Cuerpo: { tecnico_servicios, director_administrativo, tecnico_cargo, informe_fecha, informe_taller,
//           informe_detalle, informe_numero (opcional, se genera si falta), fk_contrato_id, ordenes: [orden_id, ...] }
// Las órdenes deben estar RECIBIDO o ENTREGADO y, si hay contrato, pertenecer a él (el taller se toma del contrato).
$metodo = apiMetodo(['POST', 'PUT']);
$i = apiCuerpoJson();
$db = null;
try {
    $usuario = authUsuarioId();
    if ($usuario === null) {
        jsonResponse(['error' => 'No autorizado', 'msg' => 'Solo usuarios administrativos pueden registrar informes'], 403);
    }
    foreach (['tecnico_servicios' => 'técnico de servicios', 'director_administrativo' => 'director administrativo'] as $campo => $nombre) {
        if (empty($i->$campo)) {
            throw new ValidacionException("Falta el campo: $nombre");
        }
    }
    $estado = prop($i, 'informe_estado', 'GENERADO');
    if (!in_array($estado, ['GENERADO', 'ANULADO'], true)) {
        throw new ValidacionException('Estado de informe inválido');
    }
    $ordenes = array_values(array_unique(array_map('intval', (array) prop($i, 'ordenes', []))));
    if ($estado !== 'ANULADO' && count($ordenes) === 0) {
        throw new ValidacionException('El informe debe incluir al menos una orden de mantenimiento');
    }

    $contratoInforme = prop($i, 'fk_contrato_id') ? (int) $i->fk_contrato_id : null;
    $db = new Database();
    if ($contratoInforme && trim((string) prop($i, 'informe_taller', '')) === '') {
        $db->query('SELECT contrato_taller FROM logistica.tb_contratosmantenimiento WHERE contrato_id = :c');
        $db->bind(':c', $contratoInforme);
        $i->informe_taller = $db->single()['contrato_taller'] ?? null;
    }
    // Parámetros e institución se leen antes de preparar las sentencias (comparten la conexión)
    $tecnicoCargo = prop($i, 'tecnico_cargo') ?: parametro($db, 'MANT_INFORME_CARGO', 'ADMINISTRADOR DE CONTRATO');
    $siglas = institucion($db)['sistema_siglas'];
    $db->beginTransaction();
    $informeId = (int) prop($i, 'informe_id', 0);

    if ($estado !== 'ANULADO' && $ordenes) {
        // Las órdenes deben existir, no estar anuladas y no pertenecer a otro informe vigente
        $lista = implode(',', $ordenes); // enteros validados con intval
        $db->query("SELECT o.orden_id, o.orden_codigo, o.orden_estado, o.fk_contrato_id,
                           (SELECT im.informe_numero FROM logistica.tb_informe_ordenesmantenimiento io
                              JOIN logistica.tb_informemantenimiento im ON im.informe_id = io.fk_informe_id
                             WHERE io.fk_orden_id = o.orden_id AND im.informe_estado <> 'ANULADO' AND im.informe_id <> :inf LIMIT 1) AS otro_informe
                      FROM logistica.tb_ordenesmantenimiento o WHERE o.orden_id IN ($lista)");
        $db->bind(':inf', $informeId);
        $encontradas = $db->resultset();
        if (count($encontradas) !== count($ordenes)) {
            throw new ValidacionException('Alguna de las órdenes seleccionadas no existe');
        }
        foreach ($encontradas as $f) {
            if (!in_array($f['orden_estado'], ['RECIBIDO', 'ENTREGADO'], true)) {
                throw new ValidacionException("La orden {$f['orden_codigo']} está en estado {$f['orden_estado']}; solo se incluyen órdenes RECIBIDO o ENTREGADO");
            }
            if ($contratoInforme && (int) $f['fk_contrato_id'] !== $contratoInforme) {
                throw new ValidacionException("La orden {$f['orden_codigo']} pertenece a otro contrato");
            }
            if ($f['otro_informe']) {
                throw new ValidacionException("La orden {$f['orden_codigo']} ya está en el informe {$f['otro_informe']}");
            }
        }
    }

    if ($metodo === 'POST') {
        $db->query("SELECT pg_advisory_xact_lock(hashtext('logistica.tb_informemantenimiento.serie'))");
        $db->execute();
        $db->query("SELECT COALESCE(MAX(informe_serie), 0) + 1 AS serie FROM logistica.tb_informemantenimiento
                     WHERE date_part('year', informe_registro) = date_part('year', CURRENT_DATE)");
        $serie = (int) $db->single()['serie'];
        $numero = trim((string) prop($i, 'informe_numero', '')) ?: mantCodigo($siglas, 'INF', $serie);
        $db->query('INSERT INTO logistica.tb_informemantenimiento (fk_usuario_id, tecnico_servicios, tecnico_cargo, director_administrativo,
                        informe_numero, informe_serie, informe_fecha, informe_taller, informe_detalle, fk_contrato_id)
                    VALUES (:u, :t, :tc, :da, :num, :serie, :fecha, :taller, :detalle, :contrato) RETURNING informe_id');
        $db->bind(':u', $usuario);
        $db->bind(':num', $numero);
        $db->bind(':serie', $serie);
    } else {
        if (!$informeId) {
            throw new ValidacionException('Falta informe_id');
        }
        $db->query('UPDATE logistica.tb_informemantenimiento SET tecnico_servicios = :t, tecnico_cargo = :tc, director_administrativo = :da,
                        informe_fecha = :fecha, informe_taller = :taller, informe_detalle = :detalle, informe_estado = :estado, fk_contrato_id = :contrato
                    WHERE informe_id = :id RETURNING informe_id');
        $db->bind(':id', $informeId);
        $db->bind(':estado', $estado);
    }
    $db->bind(':t', (int) $i->tecnico_servicios);
    $db->bind(':tc', $tecnicoCargo);
    $db->bind(':da', (int) $i->director_administrativo);
    $db->bind(':fecha', prop($i, 'informe_fecha') ?: date('Y-m-d'));
    $db->bind(':taller', prop($i, 'informe_taller'));
    $db->bind(':detalle', prop($i, 'informe_detalle'));
    $db->bind(':contrato', $contratoInforme);
    $fila = $db->single();
    if (!$fila) {
        $db->cancelTransaction();
        jsonResponse(['error' => 'Informe no encontrado'], 404);
    }
    $informeId = (int) $fila['informe_id'];

    if ($estado !== 'ANULADO') {
        $db->query('DELETE FROM logistica.tb_informe_ordenesmantenimiento WHERE fk_informe_id = :id');
        $db->bind(':id', $informeId);
        $db->execute();
        foreach ($ordenes as $ordenId) {
            $db->query('INSERT INTO logistica.tb_informe_ordenesmantenimiento (fk_informe_id, fk_orden_id) VALUES (:i, :o)');
            $db->bind(':i', $informeId);
            $db->bind(':o', $ordenId);
            $db->execute();
        }
    }
    $db->endTransaction();
    jsonResponse(['msg' => 'Informe guardado', 'id' => $informeId, 'informe_numero' => $numero ?? null], $metodo === 'POST' ? 201 : 200);
} catch (Throwable $e) {
    $db?->cancelTransaction();
    apiError($e, 'No se pudo guardar el informe');
}
