<?php
/*
 * Datos y bloques HTML compartidos por los reportes de mantenimiento vehicular.
 */
require_once __DIR__ . '/reporte.php';

/** Orden con vehículo, personas (nombre, C.I., puesto), bitácora y detalles. */
function mantDatosOrden(Database $db, int $id): ?array
{
    $db->query("SELECT o.*, v.vehiculo_sigla, v.vehiculo_placa, v.vehiculo_marca, v.vehiculo_modelo, v.vehiculo_motor, v.vehiculo_chasis,
                       concat(s.persona_apellidos, ' ', s.persona_nombres) AS s_nombre, s.persona_doc_identidad AS s_cc, s.puesto_nombre AS s_puesto,
                       concat(da.persona_apellidos, ' ', da.persona_nombres) AS da_nombre, da.persona_doc_identidad AS da_cc, da.puesto_nombre AS da_puesto,
                       concat(t.persona_apellidos, ' ', t.persona_nombres) AS t_nombre, t.persona_doc_identidad AS t_cc, t.puesto_nombre AS t_puesto,
                       inf.informe_numero AS bitacora_numero, inf.informe_taller AS bitacora_taller
                  FROM logistica.tb_ordenesmantenimiento o
                  JOIN administrativo.tb_vehiculos v ON v.vehiculo_id = o.fk_vehiculo_id
                  LEFT JOIN tthh.vw_personal_simple s ON s.ppersonal_id = o.personal_solicita
                  LEFT JOIN tthh.vw_personal_simple da ON da.ppersonal_id = o.director_administrativo
                  LEFT JOIN tthh.vw_personal_simple t ON t.ppersonal_id = o.tecnico_servicios
                  LEFT JOIN LATERAL (
                      SELECT im.informe_numero, im.informe_taller FROM logistica.tb_informe_ordenesmantenimiento io
                        JOIN logistica.tb_informemantenimiento im ON im.informe_id = io.fk_informe_id AND im.informe_estado <> 'ANULADO'
                       WHERE io.fk_orden_id = o.orden_id ORDER BY im.informe_id DESC LIMIT 1) inf ON true
                 WHERE o.orden_id = :id");
    $db->bind(':id', $id);
    $orden = $db->single();
    if (!$orden) {
        return null;
    }
    foreach (['trabajos' => 'tb_mantenimiento_trabajos ORDER BY trabajo_id', 'sugeridos' => 'tb_mantenimiento_sugeridos ORDER BY trabajo_id',
              'facturas' => "tb_mantenimiento_facturas WHERE factura_estado = 'ACTIVO' ORDER BY factura_id", 'anexos' => 'tb_mantenimiento_anexos ORDER BY anexo_id'] as $clave => $resto) {
        [$tabla, $cola] = explode(' ', $resto, 2);
        $condicion = str_starts_with($cola, 'WHERE') ? 'AND ' . substr($cola, 6) : $cola;
        $db->query("SELECT * FROM logistica.$tabla WHERE fk_orden_id = :id $condicion");
        $db->bind(':id', $id);
        $orden[$clave] = $db->resultset();
    }
    $orden['taller'] = $orden['orden_taller'] ?: $orden['bitacora_taller'];
    return $orden;
}

function mantNumero($serie): string
{
    return str_pad((string) (int) $serie, 3, '0', STR_PAD_LEFT);
}

function mantTablaLista(string $titulo, array $items, string $campo): string
{
    $filas = '';
    foreach (array_values($items) as $i => $item) {
        $filas .= '<tr><td style="width:15%;text-align:center;">' . ($i + 1) . '</td><td style="width:85%;">' . e($item[$campo]) . '</td></tr>';
    }
    return '<table class="t" style="margin-top:4mm;">'
        . '<tr><th colspan="2" style="padding:8px;">' . e($titulo) . '</th></tr>'
        . '<tr><th style="width:15%;">ITEM</th><th style="width:85%;">DETALLE</th></tr>'
        . ($filas ?: '<tr><td colspan="2" style="text-align:center;">—</td></tr>') . '</table>';
}

/** Lista de trabajos: a realizar + sugeridos por el contratista. */
function mantTrabajosRealizados(array $orden): array
{
    return array_merge(array_column($orden['trabajos'], 'trabajo_descripcion'), array_column($orden['sugeridos'], 'trabajo_descripcion'));
}

function mantFecha(?string $fechaHora): string
{
    return $fechaHora ? substr($fechaHora, 0, 10) : '';
}
