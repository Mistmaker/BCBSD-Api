<?php
/*
 * PDF del parte de servicio con las secciones y el orden del formato del área operativa (Excel CBSD-PA / CBSD-PI).
 * Plantilla editable: reportes/formatos/operaciones/parte.html (ver LEEME.md de esa carpeta).
 */
require_once __DIR__ . '/partes.php';
require_once __DIR__ . '/reporte.php';

const PARTE_DIAS = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];
const PARTE_MESES = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];

/** '2026-11-20' -> 'viernes, 20 de noviembre de 2026' */
function parteFechaTexto(?string $fecha): string
{
    if (!$fecha) {
        return '';
    }
    $t = strtotime($fecha);
    return PARTE_DIAS[(int) date('N', $t) - 1] . ', ' . (int) date('j', $t) . ' de ' . PARTE_MESES[(int) date('n', $t) - 1] . ' de ' . date('Y', $t);
}

/** '2026-11-20T22:14' -> '20/11 22:14' (el día solo si difiere de la fecha del parte) */
function parteHoraCorta(?string $fh, string $fechaParte): string
{
    if (!$fh) {
        return '';
    }
    $fh = str_replace('T', ' ', $fh);
    $fecha = substr($fh, 0, 10);
    $hora = substr($fh, 11, 5);
    return $fecha === $fechaParte ? $hora : date('d/m', strtotime($fecha)) . ' ' . $hora;
}

/** Número sin ceros a la derecha ('6.0000' -> '6') */
function parteCantidad($v): string
{
    if ($v === null || $v === '') {
        return '';
    }
    return rtrim(rtrim(number_format((float) $v, 2, '.', ''), '0'), '.');
}

/** Tabla con encabezados [[título, ancho%], ...] y filas ya escapadas; 'Ninguno' si no hay filas */
function parteTabla(array $columnas, array $filas, string $vacio = 'Ninguno'): string
{
    $h = '<table class="t"><tr>';
    foreach ($columnas as [$titulo, $ancho]) {
        $h .= '<th style="width:' . $ancho . '%;">' . $titulo . '</th>';
    }
    $h .= '</tr>';
    if (!$filas) {
        return $h . '<tr><td colspan="' . count($columnas) . '" style="text-align:center;color:#555;">' . $vacio . '</td></tr></table>';
    }
    foreach ($filas as $fila) {
        $h .= '<tr>';
        foreach (array_values($fila) as $i => $celda) {
            $h .= '<td style="width:' . $columnas[$i][1] . '%;">' . $celda . '</td>';
        }
        $h .= '</tr>';
    }
    return $h . '</table>';
}

/**
 * HTML completo del parte (cabecera institucional + cuerpo). null si no existe.
 * Devuelve ['html' => ..., 'titulo' => 'Parte de auxilio CBSD-PA-X1-2026-0001'].
 */
function parteReporteHtml(Database $db, int $id): ?array
{
    $inst = reporteInstitucion($db);
    $p = parteObtener($db, $id);
    if (!$p) {
        return null;
    }
    $valor = function (string $sql, array $params) use ($db) {
        $db->query($sql);
        foreach ($params as $k => $v) {
            $db->bind($k, $v);
        }
        return $db->single() ?: [];
    };
    $ubic = $valor('SELECT (SELECT state_name FROM resources.states WHERE state_id = :pr) AS provincia,
                           (SELECT town_name FROM resources.towns WHERE town_id = :ca) AS canton,
                           (SELECT parish_name FROM resources.parishes WHERE parish_id = :pa) AS parroquia',
        [':pr' => $p['parte_provincia'] ? (int) $p['parte_provincia'] : null, ':ca' => $p['parte_canton'] ? (int) $p['parte_canton'] : null,
            ':pa' => $p['parte_parroquia'] ? (int) $p['parte_parroquia'] : null]);
    $despacho = $p['fk_personal_despacho_id'] ? ($valor("SELECT concat_ws(' ', pe.persona_apellidos, pe.persona_nombres) AS n FROM tthh.tb_personal t
                                                         JOIN resources.tb_personas pe ON pe.persona_id = t.fk_persona_id WHERE t.personal_id = :id",
        [':id' => (int) $p['fk_personal_despacho_id']])['n'] ?? '') : '';
    $db->query('SELECT estacion_id, estacion_nombre FROM operaciones.tb_estaciones');
    $estaciones = array_column($db->resultset(), 'estacion_nombre', 'estacion_id');
    $est = fn($id) => e($estaciones[$id] ?? '');
    $fecha = $p['parte_fecha'];
    $incendio = $p['parte_tipo'] === 'INCENDIO';

    // Personal: por rol, como en el formato
    $roles = [PARTE_ROL_MANDO => 'Persona al mando de la emergencia', 'PERSONAL DE APH' => 'Personal de APH', 'PERSONAL OPERATIVO' => 'Personal operativo'];
    $personal = [];
    foreach ($roles as $rol => $texto) {
        foreach (array_values(array_filter($p['personal'], fn($x) => $x['parte_personal_rol'] === $rol)) as $i => $x) {
            $personal[] = [$i === 0 ? '<b>' . $texto . '</b>' : '', e($x['nombre']), e($x['parte_personal_rango']), e($x['parte_personal_grupo'])];
        }
    }
    $vehiculos = array_map(fn($v) => [$est($v['fk_estacion_id']), e($v['parte_vehiculo_placa']), e($v['parte_vehiculo_siglas']),
        e(parteCantidad($v['parte_vehiculo_km_salida'])), e(parteCantidad($v['parte_vehiculo_km_retorno'])),
        e(parteHoraCorta($v['parte_vehiculo_hora_despacho'], $fecha)), e(parteHoraCorta($v['parte_vehiculo_hora_salida'], $fecha)),
        e(parteHoraCorta($v['parte_vehiculo_hora_arribo'], $fecha)), e(parteHoraCorta($v['parte_vehiculo_hora_fin_operaciones'], $fecha)),
        e($v['parte_vehiculo_apoyo'])], $p['vehiculos']);
    $auxilio = array_map(fn($t) => [e($t['parte_auxilio_clave']), e($t['parte_auxilio_clasificacion']), e($t['parte_auxilio_subclasificacion']),
        e($t['parte_auxilio_uso_tipo']), e($t['parte_auxilio_especifique'])], $p['tipos_auxilio']);
    $causas = array_map(fn($c) => [e($c['parte_causa_clave']), e($c['parte_causa_clasificacion']), e($c['parte_causa_descripcion']),
        e($c['parte_causa_especifique'])], $p['causas']);
    $recursos = '';
    foreach (['equipos_herramientas' => 'EQUIPOS Y HERRAMIENTAS', 'materiales_descartables' => 'MATERIAL DESCARTABLE MATPEL', 'insumos' => 'INSUMOS'] as $k => $titulo) {
        $recursos .= '<nobreak><div class="seccion">' . $titulo . '</div>' . parteTabla([['Estación', 12], ['Descripción', 48], ['Cantidad', 12], ['Observaciones', 28]],
            array_map(fn($r) => [$est($r['fk_estacion_id']), e($r['parte_recurso_descripcion']), e(parteCantidad($r['parte_recurso_cantidad'])),
                e($r['parte_recurso_observaciones'])], $p[$k])) . '</nobreak>';
    }
    $institucion = trim(($p['parte_personas_institucion'] ?? '') === 'NINGUNA' ? '' : (string) $p['parte_personas_institucion']);
    $asistidas = ($institucion !== '' ? '<table class="t"><tr><td style="width:15%;"><b>Institución:</b></td><td style="width:55%;">' . e($institucion)
            . '</td><td style="width:10%;"><b>Tipo:</b></td><td style="width:20%;">' . e($p['parte_institucion_tipo']) . ' ' . e($p['parte_institucion_propiedad']) . '</td></tr></table>' : '')
        . parteTabla([['Nombres y apellidos', 40], ['Cédula', 18], ['Teléfono', 18], ['Propiedad', 24]],
            array_map(fn($a) => [e($a['parte_persona_nombre']), e($a['parte_persona_identificacion']), e($a['parte_persona_telefono']),
                e($a['parte_persona_propiedad'])], $p['personas_asistidas']), 'Ninguna')
        . ($p['parte_observacion_institucion'] ? '<div class="obs"><b>Observación:</b> ' . nl2br(e($p['parte_observacion_institucion'])) . '</div>' : '');
    $edad = fn($n, $t) => $n === null || $n === '' ? '' : e((int) $n . ' ' . $t);
    $victimas = parteTabla([['N.º hoja 002', 9], ['Identificación', 16], ['Apellidos y nombres', 24], ['Edad', 9], ['Sexo', 6], ['Signos / síntomas', 22], ['Traslado', 14]],
            array_map(fn($v) => [e($v['parte_victima_numero_hoja']), e(trim($v['parte_victima_tipo_identificacion'] . ' ' . $v['parte_victima_identificacion'])),
                e($v['parte_victima_nombres']), $edad($v['parte_victima_edad'], $v['parte_victima_tipo_edad']), e($v['parte_victima_sexo']),
                e($v['parte_victima_signos_sintomas']), e($v['parte_victima_traslado'])], $p['victimas']), 'Ninguna')
        . ($p['parte_observacion_victimas'] ? '<div class="obs"><b>Observación:</b> ' . nl2br(e($p['parte_observacion_victimas'])) . '</div>' : '');
    $fallecidos = parteTabla([['N.º', 7], ['Identificación', 18], ['Apellidos y nombres', 26], ['Edad', 9], ['Sexo', 6], ['Observaciones', 24], ['Traslado', 10]],
            array_map(fn($f) => [e($f['parte_fallecido_numero']), e(trim($f['parte_fallecido_tipo_identificacion'] . ' ' . $f['parte_fallecido_identificacion'])),
                e($f['parte_fallecido_nombres']), $edad($f['parte_fallecido_edad'], $f['parte_fallecido_tipo_edad']), e($f['parte_fallecido_sexo']),
                e($f['parte_fallecido_observaciones']), e($f['parte_fallecido_traslado'])], $p['fallecidos']))
        . ($p['parte_observacion_fallecidos'] ? '<div class="obs"><b>Observación:</b> ' . nl2br(e($p['parte_observacion_fallecidos'])) . '</div>' : '');

    $incendioHtml = '';
    if ($incendio) {
        $lista = function (string $tabla, string $col, string $fk) use ($db, $id): string {
            $db->query("SELECT string_agg($col, ', ') AS l FROM operaciones.$tabla WHERE fk_parte_id = :id");
            $db->bind(':id', $id);
            return (string) ($db->single()['l'] ?? '');
        };
        $sino = fn($b) => $b === null ? '' : ($b ? 'Sí' : 'No');
        $incendioHtml = '<nobreak><div class="seccion">DATOS DEL INCENDIO</div><table class="t">'
            . '<tr><td style="width:22%;"><b>Tipo de incendio:</b></td><td style="width:78%;" colspan="3">' . e($lista('tb_partes_tipos_incendio', 'parte_incendio_clasificacion', '')) . '</td></tr>'
            . '<tr><td><b>Naturaleza:</b></td><td colspan="3">' . e(trim($lista('tb_partes_naturalezas', 'parte_naturaleza_descripcion', '') . ' ' . ($p['parte_naturaleza_especifique'] ?? ''))) . '</td></tr>'
            . '<tr><td style="width:22%;"><b>Afectado:</b></td><td style="width:28%;">' . e($p['parte_tipo_afectado']) . '</td><td style="width:22%;"><b>Propietario / arrendatario:</b></td><td style="width:28%;">'
            . e(implode(' / ', array_filter([$p['parte_afectado_propietario'], $p['parte_afectado_arrendatario']]))) . '</td></tr>'
            . '<tr><td><b>Área destruida:</b></td><td>' . e(parteCantidad($p['parte_area_destruida_m2'])) . ' m²</td><td><b>Superficie quemada:</b></td><td>'
            . e(parteCantidad($p['parte_total_superficie_quemada_m2'])) . ($p['parte_total_superficie_quemada_m2'] !== null ? ' m²' : '') . '</td></tr>'
            . '<tr><td><b>Especies predominantes:</b></td><td>' . e($p['parte_especies_predominantes'] === 'NINGUNA' ? '' : $p['parte_especies_predominantes'])
            . '</td><td><b>Lugar de posible inicio:</b></td><td>' . e($p['parte_lugar_posible_inicio']) . '</td></tr>'
            . '<tr><td><b>Causante identificado:</b></td><td>' . $sino($p['parte_causante_identificado']) . '</td><td><b>Causante:</b></td><td>'
            . e(trim(($p['parte_nombre_causante'] ?? '') . ' ' . ($p['parte_otros_datos_causante'] ?? ''))) . '</td></tr></table></nobreak>';
    }

    $lat = $p['parte_latitud'] !== null ? rtrim(rtrim((string) $p['parte_latitud'], '0'), '.') : '';
    $lng = $p['parte_longitud'] !== null ? rtrim(rtrim((string) $p['parte_longitud'], '0'), '.') : '';
    $enlace = $p['parte_croquis_url'] ?: ($lat !== '' && $lng !== '' ? "https://www.openstreetmap.org/?mlat=$lat&mlon=$lng#map=18/$lat/$lng" : '');
    $mapa = $enlace !== ''
        ? '<div style="margin-top:2mm;"><qrcode value="' . e($enlace) . '" ec="M" style="width:26mm;border:none;"></qrcode></div>'
            . '<div style="font-size:7px;">Escanee el código para ver la ubicación en el mapa.</div>'
        : '<div style="height:25mm;"></div>';
    $sino = fn($b) => $b === null ? '' : ($b ? 'Sí' : 'No');
    $minutos = minutosTexto(parteMinutos(($p['parte_fecha_aviso'] ?: $fecha) . ' ' . ($p['parte_hora_aviso'] ?? ''),
        ($arr = array_filter(array_column($p['vehiculos'], 'parte_vehiculo_hora_arribo'))) ? str_replace('T', ' ', min($arr)) : null));
    $apoyo = $p['parte_apoyo_requerido'] === 'SI' ? trim('Sí. ' . ($p['parte_apoyo'] ?? '') . ' ' . ($p['parte_apoyo_otros'] ?? '')) : ($p['parte_apoyo_requerido'] === 'NO' ? 'No' : '');
    $titulo = $incendio ? 'PARTE DE INCENDIO' : 'PARTE DE AUXILIO';
    $nada = fn($v) => in_array(strtoupper(trim((string) $v)), ['', 'NINGUNA', 'NINGUNO'], true);

    $cuerpo = reportePlantilla('operaciones/parte.html', [
        'anulado_html' => $p['parte_estado'] === 'ANULADO'
            ? '<div style="text-align:center;color:#bf0411;font-size:14px;font-weight:bold;margin-bottom:3mm;">ANULADO: ' . e($p['parte_anulado_motivo']) . '</div>' : '',
        'titulo' => $titulo, 'numero' => e($p['parte_numero']), 'estado' => e($p['parte_estado']),
        'estacion' => 'Estación ' . e($p['estacion_nombre']),
        'fecha_texto' => e(parteFechaTexto($fecha)), 'tipo_dia' => e($p['parte_tipo_dia']), 'codigo_salida' => e($p['parte_codigo_salida']),
        'grupo' => e($p['parte_grupo_asiste']), 'forma_aviso' => e($p['parte_forma_aviso']), 'despacho' => e($despacho),
        'aviso' => e(trim(($p['parte_fecha_aviso'] && $p['parte_fecha_aviso'] !== $fecha ? date('d/m/Y', strtotime($p['parte_fecha_aviso'])) . ' ' : '') . ($p['parte_hora_aviso'] ?? ''))),
        'transferencia' => $p['parte_hora_transferencia_ecu'] !== null
            ? e(sprintf('%02d:%02d', (int) $p['parte_hora_transferencia_ecu'], (int) $p['parte_minuto_transferencia_ecu'])) : '',
        'alertante' => e($p['parte_informacion_alertante']), 'apoyo' => e($apoyo), 'respuesta' => e($minutos),
        'provincia' => e($ubic['provincia'] ?? ''), 'canton' => e($ubic['canton'] ?? ''), 'parroquia' => e($ubic['parroquia'] ?? ''),
        'zona' => e(ucfirst(strtolower((string) $p['parte_tipo_sector']))),
        'calle_principal' => e($p['parte_calle_principal'] ?? $p['parte_direccion']), 'calle_secundaria' => e($p['parte_calle_secundaria']),
        'numero_sector' => e(implode(' / ', array_filter([$p['parte_numero_domicilio'], $p['parte_sector']]))), 'referencia' => e($p['parte_referencia']),
        'personal_html' => parteTabla([['Rol', 30], ['Apellidos y nombres', 40], ['Rango', 15], ['Pelotón', 15]], $personal),
        'vehiculos_html' => parteTabla([['Estación', 8], ['Placa', 11], ['Siglas', 8], ['Km salida', 9], ['Km ingreso', 9], ['Despacho', 10],
            ['Salida', 10], ['Arribo', 10], ['Fin oper.', 10], ['Apoyo int/ext', 15]], $vehiculos),
        'auxilio_html' => parteTabla([['Clave', 8], ['Clasificación', 22], ['Subclasificación y niveles', 25], ['Usos y tipos', 22], ['Especifique', 23]], $auxilio),
        'causas_html' => parteTabla([['Clave', 8], ['Clasificación', 27], ['Posibles causas', 30], ['Especifique', 35]], $causas, 'Ninguna'),
        'recursos_html' => $recursos, 'asistidas_html' => $asistidas, 'victimas_html' => $victimas, 'fallecidos_html' => $fallecidos,
        'incendio_html' => $incendioHtml,
        'danios' => $nada($p['parte_danios_materiales']) ? 'Ninguno' : nl2br(e($p['parte_danios_materiales'])),
        'descripcion' => nl2br(e($p['parte_descripcion_operaciones'])),
        'latitud' => e($lat), 'longitud' => e($lng), 'mapa_html' => $mapa,
        'novedades' => $p['parte_novedades'] ? nl2br(e($p['parte_novedades'])) : 'Ninguna',
        'inspectores' => e(trim($sino($p['parte_visita_inspectores']) . ($p['parte_visita_inspectores'] && $p['parte_visita_inspectores_motivo'] ? ': ' . $p['parte_visita_inspectores_motivo'] : ''))),
        'elaborado' => nl2br(e($p['parte_elaborado_por'])), 'revisado' => nl2br(e($p['parte_revisado_por'])), 'aprobado' => nl2br(e($p['parte_aprobado_por'])),
        'entregado_a' => e($p['parte_entregado_a']), 'entregado_cedula' => e($p['parte_entregado_identificacion']),
        'entregado_fecha' => $p['parte_fecha_entrega'] ? e(date('d/m/Y', strtotime($p['parte_fecha_entrega']))) : '',
    ]);
    $estilos = '<style>
        .seccion{background:#9dc3e6;font-size:9px;font-weight:bold;padding:3px 4px;margin-top:3mm;}
        .t td,.t th{padding:3px 4px;font-size:8px;}
        .caja{border:1px solid #222d32;padding:4px;font-size:9px;min-height:10mm;}
        .obs{font-size:8px;margin-top:1mm;}
    </style>';
    $html = reporteHtml($inst, ['UNIDAD DE OPERACIONES', $titulo, 'Estación ' . ($p['estacion_nombre'] ?? ''), $p['parte_numero']], $estilos . $cuerpo);
    // Número de página en el pie (como el formato impreso: "1 de 3")
    $html = str_replace('</page_footer>', '<div style="position:absolute;right:20mm;bottom:2mm;font-size:7px;">Página [[page_cu]] de [[page_nb]]</div></page_footer>', $html);
    return ['html' => $html, 'titulo' => ($incendio ? 'Parte de incendio ' : 'Parte de auxilio ') . $p['parte_numero']];
}

function minutosTexto(?int $m): string
{
    if ($m === null) {
        return '';
    }
    return $m < 60 ? "$m min" : intdiv($m, 60) . ' h ' . str_pad((string) ($m % 60), 2, '0', STR_PAD_LEFT) . ' min';
}
