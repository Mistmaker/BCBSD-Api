<?php
/*
 * Petición de materiales (servicios generales): validación, numeración y consulta.
 * Código {SIGLAS}{AA}PDM{NNNNN} (mantCodigo), secuencia por año.
 */
require_once __DIR__ . '/api.php';
require_once __DIR__ . '/mantenimiento.php'; // mantCodigo, mantDirectorAdministrativo

const PDM_TIPO = 'PDM';
const PDM_AUTORIZADO_PARA = ['ADQUISICION', 'BODEGA'];

/**
 * Valida y normaliza los datos (lanza ValidacionException). Devuelve los ítems limpios:
 * [['detalle_cantidad' => float, 'detalle_unidad' => 'CAJA', 'detalle_descripcion' => '...'], ...] (se omiten filas vacías).
 */
function pdmValidar(object $p): array
{
    $texto = fn($v) => trim(preg_replace('/\s+/', ' ', (string) $v));
    if ($texto(prop($p, 'peticion_destino', '')) === '') {
        throw new ValidacionException('Indique en qué se utilizarán los materiales');
    }
    if (!prop($p, 'solicitante_id')) {
        throw new ValidacionException('Seleccione al solicitante');
    }
    $fecha = (string) prop($p, 'peticion_fecha', date('Y-m-d'));
    if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $fecha) || strtotime($fecha) === false) {
        throw new ValidacionException('Fecha inválida');
    }
    $para = prop($p, 'peticion_autorizado_para');
    if ($para !== null && $para !== '' && !in_array($para, PDM_AUTORIZADO_PARA, true)) {
        throw new ValidacionException('"Autorizado para" debe ser Adquisición o Bodega');
    }
    $items = [];
    foreach ((array) prop($p, 'detalle', []) as $i => $d) {
        $d = (object) $d;
        $cantidad = prop($d, 'detalle_cantidad');
        $unidad = mb_strtoupper($texto(prop($d, 'detalle_unidad', '')));
        $descripcion = $texto(prop($d, 'detalle_descripcion', ''));
        if (($cantidad === null || $cantidad === '') && $unidad === '' && $descripcion === '') {
            continue; // fila vacía
        }
        $n = $i + 1;
        if (!is_numeric($cantidad) || (float) $cantidad <= 0) {
            throw new ValidacionException("Ítem $n: la cantidad debe ser mayor a 0");
        }
        if ($unidad === '' || $descripcion === '') {
            throw new ValidacionException("Ítem $n: ingrese la unidad y la descripción");
        }
        $items[] = ['detalle_cantidad' => round((float) $cantidad, 2), 'detalle_unidad' => $unidad, 'detalle_descripcion' => $descripcion];
    }
    if (!$items) {
        throw new ValidacionException('Agregue al menos un material');
    }
    return $items;
}

/** Peticiones con solicitante y autorizado. $donde / $params filtran (alias p). */
function pdmListar(Database $db, string $donde = '', array $params = []): array
{
    $db->query("SELECT p.*, p.peticion_fecha::text AS peticion_fecha,
                       -- solo apellidos y nombres (nombre_completo de la vista incluye el puesto); el cargo se imprime aparte
                       NULLIF(trim(concat_ws(' ', s.persona_apellidos, s.persona_nombres)), '') AS solicitante_nombre,
                       s.persona_doc_identidad AS solicitante_cc, s.puesto_nombre AS solicitante_puesto,
                       NULLIF(trim(concat_ws(' ', a.persona_apellidos, a.persona_nombres)), '') AS autoriza_nombre,
                       a.persona_doc_identidad AS autoriza_cc, a.puesto_nombre AS autoriza_puesto,
                       u.usuario_login AS usuario,
                       (SELECT count(*) FROM logistica.tb_peticionesmateriales_detalle d WHERE d.fk_peticion_id = p.peticion_id)::int AS items
                  FROM logistica.tb_peticionesmateriales p
                  LEFT JOIN tthh.vw_personal_simple s ON s.ppersonal_id = p.solicitante_id
                  LEFT JOIN tthh.vw_personal_simple a ON a.ppersonal_id = p.autoriza_id
                  LEFT JOIN admin.tb_usuarios u ON u.usuario_id = p.fk_usuario_id
                 WHERE TRUE $donde
                 ORDER BY p.peticion_anio DESC, p.peticion_serie DESC");
    foreach ($params as $k => $v) {
        $db->bind($k, $v);
    }
    return $db->resultset();
}

function pdmDetalle(Database $db, int $id): array
{
    $db->query('SELECT detalle_id, detalle_orden, detalle_cantidad::float AS detalle_cantidad, detalle_unidad, detalle_descripcion
                  FROM logistica.tb_peticionesmateriales_detalle WHERE fk_peticion_id = :id ORDER BY detalle_orden, detalle_id');
    $db->bind(':id', $id);
    return $db->resultset();
}

/** Quien autoriza por defecto: el puesto PDM_AUTORIZA_PUESTO_ID EN FUNCIONES. Leer antes de preparar otras sentencias. */
function pdmAutorizaPorDefecto(Database $db): ?array
{
    $puesto = (int) parametro($db, 'PDM_AUTORIZA_PUESTO_ID', 4);
    $db->query("SELECT pp.ppersonal_id, vps.nombre_completo, vps.puesto_nombre
                  FROM tthh.tb_personal_puestos pp JOIN tthh.vw_personal_simple vps USING (ppersonal_id)
                 WHERE pp.fk_puesto_id = :p AND pp.ppersonal_estado = 'EN FUNCIONES' ORDER BY pp.ppersonal_id DESC LIMIT 1");
    $db->bind(':p', $puesto);
    $f = $db->single();
    return $f ? ['ppersonal_id' => (int) $f['ppersonal_id'], 'nombre_completo' => $f['nombre_completo'], 'puesto_nombre' => $f['puesto_nombre']] : null;
}

/** Cantidad para el PDF: 3 -> "3", 2.5 -> "2,50" */
function pdmCantidad($c): string
{
    $c = (float) $c;
    return floor($c) == $c ? (string) (int) $c : number_format($c, 2, ',', '.');
}

/** "Santo Domingo, 22 de noviembre de 2026" */
function pdmLugarFecha(?string $lugar, string $fecha): string
{
    $t = strtotime($fecha);
    $meses = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];
    $texto = (int) date('j', $t) . ' de ' . $meses[(int) date('n', $t) - 1] . ' de ' . date('Y', $t);
    return trim((string) $lugar) !== '' ? trim($lugar) . ', ' . $texto : $texto;
}
