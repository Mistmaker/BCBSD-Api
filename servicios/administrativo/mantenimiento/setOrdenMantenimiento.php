<?php
require_once __DIR__ . '/../../../classes/auth.php';
$auth = requireAuth();
require_once __DIR__ . '/../../../classes/api.php';
require_once __DIR__ . '/../../../classes/mantenimiento.php';
// POST -> crea una orden (código, serie y último mantenimiento se calculan aquí)
// PUT  -> actualiza una orden (con orden_id). Para anular: orden_estado = 'ANULADA'.
// Cuerpo: campos de logistica.tb_ordenesmantenimiento más los arreglos
//   trabajos [{trabajo_descripcion}], sugeridos [{trabajo_descripcion}],
//   facturas [{factura_tipo, factura_numero, factura_valor, factura_descripcion}], anexos [{anexo_descripcion}]
// Los arreglos que se envían reemplazan a los existentes; los que no se envían no se tocan.
$metodo = apiMetodo(['POST', 'PUT']);
$o = apiCuerpoJson();
$db = null;
try {
    $usuario = authUsuarioId();
    if ($usuario === null) {
        jsonResponse(['error' => 'No autorizado', 'msg' => 'Solo usuarios administrativos pueden registrar órdenes de mantenimiento'], 403);
    }
    mantValidarOrden($o);
    $db = new Database();
    // Parámetros e institución se leen antes de preparar las sentencias (comparten la conexión)
    $tecnicoPuesto = prop($o, 'tecnico_puesto') ?: parametro($db, 'MANT_TECNICO_PUESTO', 'PROFESIONAL TÉCNICO EN SERVICIOS GENERALES');
    $tolerancia = (int) parametro($db, 'MANT_TOLERANCIA_KM', 1000);
    $siglas = institucion($db)['sistema_siglas'];
    $db->beginTransaction();

    if ($metodo === 'POST') {
        // Serie anual por institución; el bloqueo evita series repetidas con dos usuarios a la vez
        $db->query("SELECT pg_advisory_xact_lock(hashtext('logistica.tb_ordenesmantenimiento.serie'))");
        $db->execute();
        $db->query("SELECT COALESCE(MAX(orden_serie), 0) + 1 AS serie FROM logistica.tb_ordenesmantenimiento
                     WHERE date_part('year', orden_registro) = date_part('year', CURRENT_DATE)");
        $serie = (int) $db->single()['serie'];
        $codigo = mantCodigo($siglas, 'MAN', $serie);

        $db->query("SELECT orden_km_mantenimiento, orden_fecha_mantenimiento::date AS fecha FROM logistica.tb_ordenesmantenimiento
                     WHERE fk_vehiculo_id = :v AND orden_estado <> 'ANULADA' ORDER BY orden_fecha_mantenimiento DESC LIMIT 1");
        $db->bind(':v', (int) $o->fk_vehiculo_id);
        $ultimo = $db->single() ?: ['orden_km_mantenimiento' => null, 'fecha' => null];

        $db->query("INSERT INTO logistica.tb_ordenesmantenimiento (
                fk_usuario_id, fk_vehiculo_id, personal_solicita, director_administrativo, tecnico_servicios, tecnico_puesto,
                orden_codigo, orden_serie, orden_tipomantenimiento, orden_fecha_mantenimiento_tipo, orden_fecha_mantenimiento,
                orden_km_mantenimiento, ultimo_km_mantenimiento, ultimo_fecha_mantenimiento, orden_fecha_entrega, orden_observaciones)
            VALUES (:u, :v, :s, :da, :t, :tp, :codigo, :serie, :tipo, :ftipo, :fecha, :km, :ukm, :ufecha, :entrega, :obs)
            RETURNING orden_id");
        $db->bind(':u', $usuario);
        $db->bind(':v', (int) $o->fk_vehiculo_id);
        $db->bind(':codigo', $codigo);
        $db->bind(':serie', $serie);
        $db->bind(':ftipo', prop($o, 'orden_fecha_mantenimiento_tipo', 'SISTEMA'));
        $db->bind(':ukm', $ultimo['orden_km_mantenimiento']);
        $db->bind(':ufecha', $ultimo['fecha']);
    } else {
        if (!prop($o, 'orden_id')) {
            throw new ValidacionException('Falta orden_id');
        }
        $db->query('SELECT orden_estado, fk_vehiculo_id FROM logistica.tb_ordenesmantenimiento WHERE orden_id = :id FOR UPDATE');
        $db->bind(':id', (int) $o->orden_id);
        $actual = $db->single();
        if (!$actual) {
            $db->cancelTransaction();
            jsonResponse(['error' => 'Orden no encontrada'], 404);
        }
        if ($actual['orden_estado'] === 'ANULADA') {
            throw new ValidacionException('Una orden anulada no se puede modificar');
        }
        if (prop($o, 'orden_estado') === 'ANULADA') {
            $db->query("SELECT 1 FROM logistica.tb_informe_ordenesmantenimiento io JOIN logistica.tb_informemantenimiento i ON i.informe_id = io.fk_informe_id
                         WHERE io.fk_orden_id = :id AND i.informe_estado <> 'ANULADO'");
            $db->bind(':id', (int) $o->orden_id);
            if ($db->single()) {
                throw new ValidacionException('La orden está incluida en un informe; anule o modifique primero el informe');
            }
        }
        $db->query('UPDATE logistica.tb_ordenesmantenimiento SET
                personal_solicita = :s, director_administrativo = :da, tecnico_servicios = :t, tecnico_puesto = :tp,
                orden_tipomantenimiento = :tipo, orden_fecha_mantenimiento = :fecha, orden_km_mantenimiento = :km,
                orden_fecha_entrega = :entrega, orden_observaciones = :obs, orden_estado = :estado,
                orden_fecha_recepcion = :frec, orden_quien_recepcion = :qrec, orden_cargo_recepcion = :crec
            WHERE orden_id = :id RETURNING orden_id');
        $db->bind(':id', (int) $o->orden_id);
        $db->bind(':estado', prop($o, 'orden_estado', $actual['orden_estado']));
        $db->bind(':frec', prop($o, 'orden_fecha_recepcion') ?: null);
        $db->bind(':qrec', prop($o, 'orden_quien_recepcion'));
        $db->bind(':crec', prop($o, 'orden_cargo_recepcion'));
        $o->fk_vehiculo_id = $actual['fk_vehiculo_id']; // el vehículo no se cambia en una orden existente
    }
    $db->bind(':s', (int) $o->personal_solicita);
    $db->bind(':da', (int) $o->director_administrativo);
    $db->bind(':t', (int) $o->tecnico_servicios);
    $db->bind(':tp', $tecnicoPuesto);
    $db->bind(':tipo', $o->orden_tipomantenimiento);
    $db->bind(':fecha', $o->orden_fecha_mantenimiento);
    $db->bind(':km', (string) $o->orden_km_mantenimiento);
    $db->bind(':entrega', prop($o, 'orden_fecha_entrega') ?: null);
    $db->bind(':obs', prop($o, 'orden_observaciones'));
    $ordenId = (int) $db->single()['orden_id'];

    // Próximo mantenimiento según el plan del vehículo (si tiene)
    $db->query("SELECT r.mantenimiento_id, r.mantenimiento_km_inicio, r.mantenimiento_km_intervalo
                  FROM logistica.tb_reglasmantenimiento r JOIN administrativo.tb_vehiculos v ON v.fk_plan_id = r.fk_plan_id
                 WHERE v.vehiculo_id = :v AND r.mantenimiento_estado = 'ACTIVO'");
    $db->bind(':v', (int) $o->fk_vehiculo_id);
    $reglas = $db->resultset();
    $km = (float) $o->orden_km_mantenimiento;
    $proximo = $reglas ? mantEvaluarPlan($km, $reglas, $o->orden_tipomantenimiento === 'PREVENTIVO' ? $km : null, $tolerancia) : null;
    $db->query('UPDATE logistica.tb_ordenesmantenimiento SET orden_proximomantenimiento = :p WHERE orden_id = :id');
    $db->bind(':p', $proximo ? (string) $proximo['km_proximo'] : null);
    $db->bind(':id', $ordenId);
    $db->execute();

    // Detalles: cada arreglo enviado reemplaza al existente
    $detalles = [
        'trabajos' => ['tb_mantenimiento_trabajos', ['trabajo_descripcion']],
        'sugeridos' => ['tb_mantenimiento_sugeridos', ['trabajo_descripcion']],
        'anexos' => ['tb_mantenimiento_anexos', ['anexo_descripcion']],
        'facturas' => ['tb_mantenimiento_facturas', ['factura_tipo', 'factura_numero', 'factura_valor', 'factura_descripcion']],
    ];
    foreach ($detalles as $clave => [$tabla, $campos]) {
        if (!property_exists($o, $clave)) {
            continue;
        }
        $db->query("DELETE FROM logistica.$tabla WHERE fk_orden_id = :id");
        $db->bind(':id', $ordenId);
        $db->execute();
        foreach ((array) $o->$clave as $item) {
            $columnas = implode(', ', $campos);
            $marcadores = implode(', ', array_map(fn($c) => ":$c", $campos));
            $db->query("INSERT INTO logistica.$tabla (fk_usuario_id, fk_orden_id, $columnas) VALUES (:u, :id, $marcadores)");
            $db->bind(':u', $usuario);
            $db->bind(':id', $ordenId);
            foreach ($campos as $c) {
                $valor = prop($item, $c);
                $valor = is_string($valor) ? trim($valor) : $valor;
                $db->bind(":$c", ($valor === '' || $valor === null) ? null : (string) $valor);
            }
            $db->execute();
        }
    }

    $db->endTransaction();
    jsonResponse(['msg' => $metodo === 'POST' ? 'Orden de mantenimiento creada' : 'Orden de mantenimiento actualizada',
                  'id' => $ordenId, 'orden_codigo' => $codigo ?? null, 'proximo' => $proximo], $metodo === 'POST' ? 201 : 200);
} catch (Throwable $e) {
    $db?->cancelTransaction();
    apiError($e, 'No se pudo guardar la orden de mantenimiento');
}
