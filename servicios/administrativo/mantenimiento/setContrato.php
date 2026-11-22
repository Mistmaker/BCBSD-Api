<?php
require_once __DIR__ . '/../../../classes/auth.php';
$auth = requireAuth();
require_once __DIR__ . '/../../../classes/api.php';
require_once __DIR__ . '/../../../classes/mantenimiento.php';
// POST -> crea un contrato; PUT (con contrato_id) -> lo actualiza.
// Cuerpo: { contrato_codigo, contrato_nombre_corto, contrato_tipo, contrato_objeto, contrato_fecha_inicio, contrato_fecha_fin, contrato_taller, contrato_ruc,
//           contrato_representante_legal, administrador_contrato, contrato_monto, contrato_estado,
//           partidas: [{ partida_rubro, partida_codigo, partida_monto }], vehiculos: [vehiculo_id, ...] }
// Reglas: la suma de partidas no supera el monto; una partida no puede quedar por debajo de lo ya consumido.
$metodo = apiMetodo(['POST', 'PUT']);
$c = apiCuerpoJson();
$db = null;
try {
    $usuario = authUsuarioId();
    if ($usuario === null) {
        jsonResponse(['error' => 'No autorizado', 'msg' => 'Solo usuarios administrativos pueden registrar contratos'], 403);
    }
    foreach (['contrato_codigo' => 'código del contrato', 'contrato_taller' => 'taller / contratista'] as $campo => $nombre) {
        if (trim((string) prop($c, $campo, '')) === '') {
            throw new ValidacionException("Falta el campo: $nombre");
        }
    }
    $monto = prop($c, 'contrato_monto', 0);
    if (!is_numeric($monto) || $monto < 0) {
        throw new ValidacionException('El monto del contrato debe ser un número mayor o igual a 0');
    }
    $estado = prop($c, 'contrato_estado', 'VIGENTE');
    if (!in_array($estado, ['VIGENTE', 'FINALIZADO', 'ANULADO'], true)) {
        throw new ValidacionException('Estado de contrato inválido');
    }
    $inicio = prop($c, 'contrato_fecha_inicio') ?: null;
    $fin = prop($c, 'contrato_fecha_fin') ?: null;
    if ($inicio && $fin && $fin < $inicio) {
        throw new ValidacionException('La fecha de fin no puede ser anterior a la de inicio');
    }
    $partidas = [];
    foreach ((array) prop($c, 'partidas', []) as $p) {
        $rubro = trim((string) prop($p, 'partida_rubro', ''));
        $valor = prop($p, 'partida_monto');
        if ($rubro === '' || !is_numeric($valor) || $valor < 0) {
            throw new ValidacionException('Cada partida necesita un rubro y un monto mayor o igual a 0');
        }
        if (isset($partidas[$rubro])) {
            throw new ValidacionException("El rubro $rubro está repetido");
        }
        $partidas[$rubro] = ['codigo' => trim((string) prop($p, 'partida_codigo', '')) ?: null, 'monto' => round((float) $valor, 2)];
    }
    if (round(array_sum(array_column($partidas, 'monto')), 2) > round((float) $monto, 2)) {
        throw new ValidacionException('La suma de las partidas supera el monto del contrato');
    }

    $db = new Database();
    requirePermiso($db, 'MANT_CONTRATO_GESTIONAR');
    $tipos = mantLista(parametro($db, 'MANT_TIPOS_CONTRATO', 'GENERAL|VIGENCIA TECNOLÓGICA'));
    $tipo = prop($c, 'contrato_tipo', 'GENERAL');
    if (!in_array($tipo, $tipos, true)) {
        throw new ValidacionException('Tipo de contrato inválido');
    }
    $db->beginTransaction();
    if ($metodo === 'POST') {
        $db->query('INSERT INTO logistica.tb_contratosmantenimiento (fk_usuario_id, contrato_codigo, contrato_tipo, contrato_objeto, contrato_fecha_inicio,
                        contrato_fecha_fin, contrato_taller, contrato_ruc, contrato_representante_legal, administrador_contrato, contrato_monto, contrato_estado, contrato_nombre_corto)
                    VALUES (:u, :codigo, :tipo, :objeto, :inicio, :fin, :taller, :ruc, :rep, :adm, :monto, :estado, :corto) RETURNING contrato_id');
        $db->bind(':u', $usuario);
    } else {
        if (!prop($c, 'contrato_id')) {
            throw new ValidacionException('Falta contrato_id');
        }
        $db->query('UPDATE logistica.tb_contratosmantenimiento SET contrato_codigo = :codigo, contrato_tipo = :tipo, contrato_objeto = :objeto,
                        contrato_fecha_inicio = :inicio, contrato_fecha_fin = :fin, contrato_taller = :taller, contrato_ruc = :ruc,
                        contrato_representante_legal = :rep, administrador_contrato = :adm, contrato_monto = :monto, contrato_estado = :estado,
                        contrato_nombre_corto = :corto
                    WHERE contrato_id = :id RETURNING contrato_id');
        $db->bind(':id', (int) $c->contrato_id);
    }
    $db->bind(':codigo', mb_strtoupper(trim($c->contrato_codigo)));
    $db->bind(':tipo', $tipo);
    $db->bind(':objeto', prop($c, 'contrato_objeto'));
    $db->bind(':inicio', $inicio);
    $db->bind(':fin', $fin);
    $db->bind(':taller', mb_strtoupper(trim($c->contrato_taller)));
    $db->bind(':ruc', prop($c, 'contrato_ruc'));
    $db->bind(':rep', prop($c, 'contrato_representante_legal') ? mb_strtoupper(trim($c->contrato_representante_legal)) : null);
    $db->bind(':adm', prop($c, 'administrador_contrato') ? (int) $c->administrador_contrato : null);
    $db->bind(':monto', (string) $monto);
    $db->bind(':estado', $estado);
    $db->bind(':corto', trim((string) prop($c, 'contrato_nombre_corto', '')) !== '' ? mb_strtoupper(trim($c->contrato_nombre_corto)) : null);
    $fila = $db->single();
    if (!$fila) {
        $db->cancelTransaction();
        jsonResponse(['error' => 'Contrato no encontrado'], 404);
    }
    $contratoId = (int) $fila['contrato_id'];

    // Partidas: no se puede quitar ni reducir por debajo de lo consumido
    $db->query('SELECT partida_rubro, consumido FROM logistica.vw_contratosmantenimiento_saldo WHERE contrato_id = :id');
    $db->bind(':id', $contratoId);
    foreach ($db->resultset() as $actual) {
        $nuevo = $partidas[$actual['partida_rubro']]['monto'] ?? null;
        if ((float) $actual['consumido'] > 0 && ($nuevo === null || $nuevo < (float) $actual['consumido'])) {
            throw new ValidacionException(sprintf('La partida %s ya tiene consumidos $%s; no puede quedar por debajo de ese valor',
                $actual['partida_rubro'], number_format((float) $actual['consumido'], 2)));
        }
    }
    $db->query('DELETE FROM logistica.tb_contratosmantenimiento_partidas WHERE fk_contrato_id = :id');
    $db->bind(':id', $contratoId);
    $db->execute();
    foreach ($partidas as $rubro => $p) {
        $db->query('INSERT INTO logistica.tb_contratosmantenimiento_partidas (fk_contrato_id, partida_rubro, partida_codigo, partida_monto) VALUES (:c, :r, :cod, :m)');
        $db->bind(':c', $contratoId);
        $db->bind(':r', $rubro);
        $db->bind(':cod', $p['codigo']);
        $db->bind(':m', (string) $p['monto']);
        $db->execute();
    }

    if (property_exists($c, 'vehiculos')) {
        $db->query('DELETE FROM logistica.tb_contratosmantenimiento_vehiculos WHERE fk_contrato_id = :id');
        $db->bind(':id', $contratoId);
        $db->execute();
        foreach (array_unique(array_map('intval', (array) $c->vehiculos)) as $v) {
            $db->query('INSERT INTO logistica.tb_contratosmantenimiento_vehiculos (fk_contrato_id, fk_vehiculo_id) VALUES (:c, :v)');
            $db->bind(':c', $contratoId);
            $db->bind(':v', $v);
            $db->execute();
        }
    }
    $db->endTransaction();
    jsonResponse(['msg' => 'Contrato guardado', 'id' => $contratoId], $metodo === 'POST' ? 201 : 200);
} catch (Throwable $e) {
    $db?->cancelTransaction();
    apiError($e, 'No se pudo guardar el contrato');
}
