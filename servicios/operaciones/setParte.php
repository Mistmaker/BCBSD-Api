<?php
require_once __DIR__ . '/../../classes/auth.php';
$auth = requireAuth();
require_once __DIR__ . '/../../classes/partes.php';
// POST -> registra un parte de servicio (número automático {SIGLAS}-{PA|PI}-{ESTACIÓN}-{AAAA}-{NNNN}) -> { id, parte_numero }
// PUT  -> edita (con parte_id); reemplaza los detalles. Un parte FINALIZADO solo lo corrige quien tiene OPE_PARTE_ANULAR.
//         Anular: { parte_id, parte_estado: 'ANULADO', parte_anulado_motivo }  (OPE_PARTE_ANULAR)
// Privilegio: OPE_PARTE_REGISTRAR.
$metodo = apiMetodo(['POST', 'PUT']);
$p = apiCuerpoJson();
$db = null;
try {
    $usuario = authUsuarioId();
    if ($usuario === null) {
        jsonResponse(['error' => 'No autorizado'], 403);
    }
    $db = new Database();
    $siglas = institucion($db)['sistema_siglas'];
    $permisos = permisosUsuario($db, $usuario);
    $id = (int) prop($p, 'parte_id', 0);

    if ($metodo === 'PUT' && strtoupper((string) prop($p, 'parte_estado')) === 'ANULADO') {
        requirePermiso($db, 'OPE_PARTE_ANULAR');
        $motivo = parteTexto(prop($p, 'parte_anulado_motivo'));
        if ($motivo === null) {
            throw new ValidacionException('Indique el motivo de la anulación');
        }
        $db->query("UPDATE operaciones.tb_partes SET parte_estado = 'ANULADO', parte_anulado_motivo = :m, parte_actualizado = now(), fk_usuario_actualiza = :u
                     WHERE parte_id = :id AND parte_estado <> 'ANULADO' RETURNING parte_numero");
        $db->bind(':m', $motivo);
        $db->bind(':u', $usuario);
        $db->bind(':id', $id);
        $fila = $db->single();
        $fila ? jsonResponse(['msg' => 'Parte anulado', 'id' => $id, 'parte_numero' => $fila['parte_numero']])
              : jsonResponse(['error' => 'No encontrado', 'msg' => 'El parte no existe o ya está anulado'], 404);
    }

    requirePermiso($db, 'OPE_PARTE_REGISTRAR');
    $d = parteValidar($p);
    $cab = $d['cab'];
    $mapaCambio = true;
    $db->beginTransaction();

    if ($metodo === 'PUT') {
        $db->query('SELECT parte_estado, parte_numero, parte_tipo, fk_estacion_id, parte_anio, parte_latitud, parte_longitud, parte_mapa_tipo, parte_mapa_archivo
                      FROM operaciones.tb_partes WHERE parte_id = :id FOR UPDATE');
        $db->bind(':id', $id);
        $actual = $db->single();
        if (!$actual) {
            $db->cancelTransaction();
            jsonResponse(['error' => 'Parte no encontrado'], 404);
        }
        if ($actual['parte_estado'] === 'ANULADO') {
            throw new ValidacionException('Un parte anulado no se puede editar');
        }
        if ($actual['parte_estado'] === 'FINALIZADO' && !in_array('OPE_PARTE_ANULAR', $permisos, true)) {
            throw new ValidacionException('El parte está finalizado: solo la supervisión puede corregirlo');
        }
        // El número no cambia: tipo, estación y año del número se conservan
        if ($actual['parte_tipo'] !== $cab['parte_tipo'] || (int) $actual['fk_estacion_id'] !== $cab['fk_estacion_id']
            || ($actual['parte_anio'] && (int) $actual['parte_anio'] !== (int) substr($cab['parte_fecha'], 0, 4))) {
            throw new ValidacionException('No se puede cambiar el tipo, la estación ni el año de un parte ya numerado; anúlelo y registre uno nuevo');
        }
        $numero = $actual['parte_numero'];
        // La imagen del mapa se rehace solo si cambió la ubicación o el tipo de mapa (o si aún no existe)
        $mapaCambio = !mapaExiste($actual['parte_mapa_archivo']) || $actual['parte_mapa_tipo'] !== $cab['parte_mapa_tipo']
            || (float) $actual['parte_latitud'] !== (float) $cab['parte_latitud'] || (float) $actual['parte_longitud'] !== (float) $cab['parte_longitud']
            || ($actual['parte_latitud'] === null) !== ($cab['parte_latitud'] === null);
        $sets = implode(', ', array_map(fn($c) => "$c = :$c", array_keys($cab)));
        $db->query("UPDATE operaciones.tb_partes SET $sets, parte_actualizado = now(), fk_usuario_actualiza = :usuario_actualiza WHERE parte_id = :parte_id");
        foreach ($cab as $c => $v) {
            $db->bind(":$c", is_bool($v) ? ($v ? 'true' : 'false') : $v);
        }
        $db->bind(':usuario_actualiza', $usuario);
        $db->bind(':parte_id', $id);
        $db->execute();
    } else {
        $anio = (int) substr($cab['parte_fecha'], 0, 4);
        $n = parteSiguienteNumero($db, $siglas, $cab['parte_tipo'], $cab['fk_estacion_id'], $anio);
        $numero = $n['numero'];
        $fila = $cab + ['parte_numero' => $numero, 'parte_anio' => $anio, 'parte_serie' => $n['serie'], 'fk_usuario_id' => $usuario];
        $cols = array_keys($fila);
        $db->query('INSERT INTO operaciones.tb_partes (' . implode(', ', $cols) . ') VALUES (:' . implode(', :', $cols) . ') RETURNING parte_id');
        foreach ($fila as $c => $v) {
            $db->bind(":$c", is_bool($v) ? ($v ? 'true' : 'false') : $v);
        }
        $id = (int) $db->single()['parte_id'];
    }
    parteGuardarDetalles($db, $id, $d);
    $db->endTransaction();
    // Imagen de ubicación (mapa con el marcador): fuera de la transacción; si el servidor de mapas no responde,
    // el parte queda guardado y la imagen se puede regenerar desde el parte.
    $mapa = ($metodo === 'POST' || $mapaCambio) ? parteActualizarMapa($db, $id) : null;
    $msg = ($metodo === 'PUT' ? 'Parte actualizado' : "Parte registrado con el número $numero")
        . ($mapa === false ? '. No se pudo generar la imagen del mapa (servidor de mapas no disponible): use "Regenerar imagen" en el parte.' : '');
    jsonResponse(['msg' => $msg, 'id' => $id, 'parte_numero' => $numero, 'mapa' => $mapa], $metodo === 'PUT' ? 200 : 201);
} catch (Throwable $e) {
    $db?->cancelTransaction();
    apiError($e, 'Error al guardar el parte de servicio');
}
