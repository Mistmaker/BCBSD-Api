<?php
/*
 * Partes de servicio (Operaciones): numeración, validación, guardado y estadística.
 * Esquema: operaciones.tb_partes + detalles (personal, vehículos, tipos de auxilio, causas, recursos, personas asistidas,
 * víctimas, fallecidos, tipos de incendio, naturalezas). Ver migrations/operaciones/01-partes-servicio.sql.
 * Número como en el formato del área operativa: {SIGLAS}-{PA|PI}-{ESTACIÓN}-{AAAA}-{NNNN}, secuencia por año, estación y tipo.
 */
require_once __DIR__ . '/api.php';
require_once __DIR__ . '/mapaUbicacion.php';

const PARTE_TIPOS = ['AUXILIO', 'INCENDIO'];
const PARTE_ESTADOS = ['REGISTRADO', 'FINALIZADO', 'ANULADO'];
const PARTE_ROL_MANDO = 'PERSONA AL MANDO DE LA EMERGENCIA';
const PARTE_ROLES = [PARTE_ROL_MANDO, 'PERSONAL DE APH', 'PERSONAL OPERATIVO'];
/** Clave del JSON => [tabla de detalle, tipo en el catálogo de recursos] */
const PARTE_RECURSOS = [
    'equipos_herramientas' => ['operaciones.tb_partes_equipos_herramientas', 'EQUIPO'],
    'materiales_descartables' => ['operaciones.tb_partes_materiales_descartables', 'MATERIAL'],
    'insumos' => ['operaciones.tb_partes_insumos', 'INSUMO'],
];

/** PI para incendio, PA para auxilio */
function partePrefijo(string $tipo): string
{
    return strtoupper($tipo) === 'INCENDIO' ? 'PI' : 'PA';
}

/** Sigla de la estación para el número: solo letras y números ('X-1' -> 'X1') */
function parteSiglaEstacion(string $nombre): string
{
    $sigla = strtoupper(preg_replace('/[^A-Za-z0-9]/', '', $nombre));
    return $sigla !== '' ? $sigla : 'EST';
}

/** CBSD-PA-X1-2026-0001 */
function parteCodigo(string $siglas, string $tipo, string $estacion, int $anio, int $serie): string
{
    return strtoupper(preg_replace('/[^A-Za-z0-9]/', '', $siglas)) . '-' . partePrefijo($tipo) . '-' . parteSiglaEstacion($estacion)
        . '-' . $anio . '-' . str_pad((string) $serie, 4, '0', STR_PAD_LEFT);
}

/** Lista de un parámetro separado por | (rangos, pelotones, claves) */
function parteLista(?string $valor): array
{
    return array_values(array_filter(array_map('trim', explode('|', (string) $valor)), fn($v) => $v !== ''));
}

function parteTexto($v): ?string
{
    $t = trim(preg_replace('/\s+/u', ' ', (string) $v));
    return $t === '' ? null : $t;
}

/** Texto largo (descripción, novedades): conserva los saltos de línea */
function parteTextoLargo($v): ?string
{
    $t = trim(str_replace("\r\n", "\n", (string) $v));
    return $t === '' ? null : $t;
}

function parteFecha($v, string $campo, bool $obligatoria = false): ?string
{
    $v = trim((string) $v);
    if ($v === '') {
        if ($obligatoria) {
            throw new ValidacionException("Indique $campo");
        }
        return null;
    }
    $d = DateTime::createFromFormat('!Y-m-d', substr($v, 0, 10));
    if (!$d || $d->format('Y-m-d') !== substr($v, 0, 10)) {
        throw new ValidacionException("Fecha inválida en $campo");
    }
    return $d->format('Y-m-d');
}

function parteHora($v, string $campo, bool $obligatoria = false): ?string
{
    $v = trim((string) $v);
    if ($v === '') {
        if ($obligatoria) {
            throw new ValidacionException("Indique $campo");
        }
        return null;
    }
    if (!preg_match('/^([01]\d|2[0-3]):([0-5]\d)(:[0-5]\d)?$/', $v)) {
        throw new ValidacionException("Hora inválida en $campo");
    }
    return substr($v, 0, 5);
}

/** Fecha y hora ('2026-11-22T14:05' o '2026-11-22 14:05:00') -> 'Y-m-d H:i:s' */
function parteFechaHora($v, string $campo): ?string
{
    $v = trim(str_replace('T', ' ', (string) $v));
    if ($v === '') {
        return null;
    }
    foreach (['Y-m-d H:i', 'Y-m-d H:i:s'] as $formato) {
        $d = DateTime::createFromFormat('!' . $formato, $v);
        if ($d && $d->format($formato) === $v) {
            return $d->format('Y-m-d H:i:s');
        }
    }
    throw new ValidacionException("Fecha y hora inválidas en $campo");
}

function parteEntero($v, string $campo, int $min = 0, ?int $max = null): ?int
{
    if ($v === null || $v === '') {
        return null;
    }
    $n = filter_var($v, FILTER_VALIDATE_INT);
    if ($n === false || $n < $min || ($max !== null && $n > $max)) {
        throw new ValidacionException("Valor inválido en $campo");
    }
    return $n;
}

function parteNumero($v, string $campo, float $min = 0): ?float
{
    if ($v === null || $v === '') {
        return null;
    }
    $v = str_replace(',', '.', (string) $v);
    if (!is_numeric($v) || (float) $v < $min) {
        throw new ValidacionException("Valor inválido en $campo");
    }
    return (float) $v;
}

function parteBool($v): ?bool
{
    if ($v === null || $v === '') {
        return null;
    }
    if (is_bool($v)) {
        return $v;
    }
    return in_array(strtoupper((string) $v), ['1', 'SI', 'SÍ', 'TRUE', 'S'], true);
}

/** Filas no vacías de un detalle: alguna de las columnas tiene dato */
function parteFilas(object $p, string $clave): array
{
    $filas = [];
    foreach ((array) prop($p, $clave, []) as $fila) {
        $fila = (array) $fila;
        $conDato = array_filter($fila, fn($v) => $v !== null && $v !== '' && !(is_string($v) && trim($v) === '')
            && !in_array($v, ['años', 'meses', 'días'], true));
        if ($conDato) {
            $filas[] = $fila;
        }
    }
    return $filas;
}

/**
 * Valida y normaliza un parte (lanza ValidacionException). $hoy para pruebas.
 * Devuelve ['cab' => columnas de tb_partes, 'personal' => [...], 'vehiculos' => [...], 'tipos_auxilio' => [...], 'causas' => [...],
 *           'recursos' => [clave => [...]], 'personas_asistidas' => [...], 'victimas' => [...], 'fallecidos' => [...],
 *           'tipos_incendio' => [ids], 'naturalezas' => [ids]].
 */
function parteValidar(object $p, ?string $hoy = null): array
{
    $hoy ??= date('Y-m-d');
    $tipo = strtoupper(trim((string) prop($p, 'parte_tipo', '')));
    if (!in_array($tipo, PARTE_TIPOS, true)) {
        throw new ValidacionException('El tipo de parte debe ser AUXILIO o INCENDIO');
    }
    $fecha = parteFecha(prop($p, 'parte_fecha'), 'la fecha del parte', true);
    if ($fecha > $hoy) {
        throw new ValidacionException('La fecha del parte no puede ser futura');
    }
    $estacion = parteEntero(prop($p, 'fk_estacion_id'), 'la estación', 1);
    if (!$estacion) {
        throw new ValidacionException('Seleccione la estación');
    }
    $estado = strtoupper(trim((string) prop($p, 'parte_estado', 'REGISTRADO'))) ?: 'REGISTRADO';
    if (!in_array($estado, ['REGISTRADO', 'FINALIZADO'], true)) {
        throw new ValidacionException('Estado inválido (para anular use la opción Anular)');
    }
    $fechaAviso = parteFecha(prop($p, 'parte_fecha_aviso'), 'la fecha del aviso') ?? $fecha;
    if ($fechaAviso > $fecha) {
        throw new ValidacionException('La fecha del aviso no puede ser posterior a la fecha del parte');
    }
    $descripcion = parteTextoLargo(prop($p, 'parte_descripcion_operaciones'));
    if ($descripcion === null) {
        throw new ValidacionException('Describa las operaciones realizadas');
    }
    $lat = parteNumero(prop($p, 'parte_latitud'), 'la latitud', -90);
    $lng = parteNumero(prop($p, 'parte_longitud'), 'la longitud', -180);
    if (($lat !== null && $lat > 90) || ($lng !== null && $lng > 180)) {
        throw new ValidacionException('Coordenadas fuera de rango');
    }
    $apoyoRequerido = strtoupper((string) prop($p, 'parte_apoyo_requerido', ''));
    if ($apoyoRequerido !== '' && !in_array($apoyoRequerido, ['SI', 'NO'], true)) {
        throw new ValidacionException('Apoyo requerido debe ser SI o NO');
    }

    // Personal
    $personal = [];
    $vistos = [];
    foreach (parteFilas($p, 'personal') as $i => $f) {
        $n = $i + 1;
        $id = parteEntero($f['fk_personal_id'] ?? null, "el personal (fila $n)", 1);
        if (!$id) {
            throw new ValidacionException("Personal fila $n: seleccione a la persona");
        }
        if (isset($vistos[$id])) {
            throw new ValidacionException("Personal fila $n: la persona ya está registrada en el parte");
        }
        $vistos[$id] = true;
        $rol = strtoupper(parteTexto($f['parte_personal_rol'] ?? '') ?? 'PERSONAL OPERATIVO');
        if (!in_array($rol, PARTE_ROLES, true)) {
            throw new ValidacionException("Personal fila $n: rol inválido");
        }
        $personal[] = ['fk_personal_id' => $id, 'parte_personal_rol' => $rol,
            'parte_personal_rango' => parteTexto($f['parte_personal_rango'] ?? null), 'parte_personal_grupo' => parteTexto($f['parte_personal_grupo'] ?? null)];
    }
    $mando = array_values(array_filter($personal, fn($x) => $x['parte_personal_rol'] === PARTE_ROL_MANDO));
    if (!$personal) {
        throw new ValidacionException('Registre al personal que atendió la emergencia');
    }
    if (count($mando) !== 1) {
        throw new ValidacionException('Indique una (y solo una) persona al mando de la emergencia');
    }

    // Vehículos
    $vehiculos = [];
    $vistos = [];
    foreach (parteFilas($p, 'vehiculos') as $i => $f) {
        $n = $i + 1;
        $vid = parteEntero($f['fk_vehiculo_id'] ?? null, "el vehículo (fila $n)", 1);
        $placa = parteTexto($f['parte_vehiculo_placa'] ?? null);
        if (!$vid && $placa === null) {
            throw new ValidacionException("Vehículo fila $n: seleccione el vehículo o ingrese la placa (apoyo externo)");
        }
        $clave = $vid ? "id$vid" : 'p' . strtoupper($placa);
        if (isset($vistos[$clave])) {
            throw new ValidacionException("Vehículo fila $n: el vehículo ya está registrado en el parte");
        }
        $vistos[$clave] = true;
        $kmS = parteNumero($f['parte_vehiculo_km_salida'] ?? null, "km de salida (fila $n)");
        $kmR = parteNumero($f['parte_vehiculo_km_retorno'] ?? null, "km de ingreso (fila $n)");
        if ($kmS !== null && $kmR !== null && $kmR < $kmS) {
            throw new ValidacionException("Vehículo fila $n: el km de ingreso no puede ser menor que el de salida");
        }
        $horas = [];
        foreach (['despacho' => 'despacho', 'salida' => 'salida', 'arribo' => 'arribo', 'fin_operaciones' => 'fin de operaciones'] as $k => $nombre) {
            $horas[$k] = parteFechaHora($f["parte_vehiculo_hora_$k"] ?? null, "la hora de $nombre (vehículo fila $n)");
        }
        $previa = null;
        foreach ($horas as $k => $h) {
            if ($h !== null) {
                if ($previa !== null && $h < $previa) {
                    throw new ValidacionException("Vehículo fila $n: las horas deben ir en orden (despacho, salida, arribo, fin de operaciones)");
                }
                $previa = $h;
            }
        }
        $vehiculos[] = ['fk_vehiculo_id' => $vid, 'fk_estacion_id' => parteEntero($f['fk_estacion_id'] ?? null, "la estación (vehículo fila $n)", 1),
            'parte_vehiculo_placa' => $placa ? strtoupper($placa) : null, 'parte_vehiculo_siglas' => parteTexto($f['parte_vehiculo_siglas'] ?? null),
            'parte_vehiculo_km_salida' => $kmS, 'parte_vehiculo_km_retorno' => $kmR,
            'parte_vehiculo_hora_despacho' => $horas['despacho'], 'parte_vehiculo_hora_salida' => $horas['salida'],
            'parte_vehiculo_hora_arribo' => $horas['arribo'], 'parte_vehiculo_hora_fin_operaciones' => $horas['fin_operaciones'],
            'parte_vehiculo_apoyo' => parteTexto($f['parte_vehiculo_apoyo'] ?? null)];
    }
    if (!$vehiculos) {
        throw new ValidacionException('Registre al menos un vehículo');
    }
    $tiempos = parteTiempos($vehiculos);

    $tiposAuxilio = [];
    foreach (parteFilas($p, 'tipos_auxilio') as $i => $f) {
        $fila = ['fk_tipo_auxilio_id' => parteEntero($f['fk_tipo_auxilio_id'] ?? null, 'el tipo de auxilio', 1),
            'parte_auxilio_clave' => parteTexto($f['parte_auxilio_clave'] ?? null), 'parte_auxilio_clasificacion' => parteTexto($f['parte_auxilio_clasificacion'] ?? null),
            'parte_auxilio_subclasificacion' => parteTexto($f['parte_auxilio_subclasificacion'] ?? null), 'parte_auxilio_uso_tipo' => parteTexto($f['parte_auxilio_uso_tipo'] ?? null),
            'parte_auxilio_especifique' => parteTexto($f['parte_auxilio_especifique'] ?? null)];
        if ($fila['parte_auxilio_clasificacion'] === null) {
            throw new ValidacionException('Tipo de auxilio fila ' . ($i + 1) . ': seleccione la clasificación');
        }
        $tiposAuxilio[] = $fila;
    }
    $causas = [];
    foreach (parteFilas($p, 'causas') as $i => $f) {
        $fila = ['fk_causa_id' => parteEntero($f['fk_causa_id'] ?? null, 'la causa', 1),
            'parte_causa_clave' => parteTexto($f['parte_causa_clave'] ?? null), 'parte_causa_clasificacion' => parteTexto($f['parte_causa_clasificacion'] ?? null),
            'parte_causa_descripcion' => parteTexto($f['parte_causa_descripcion'] ?? null), 'parte_causa_especifique' => parteTexto($f['parte_causa_especifique'] ?? null)];
        if ($fila['parte_causa_descripcion'] === null) {
            throw new ValidacionException('Posible causa fila ' . ($i + 1) . ': seleccione la causa');
        }
        $causas[] = $fila;
    }
    $recursos = [];
    foreach (PARTE_RECURSOS as $clave => [, $tipoRecurso]) {
        $recursos[$clave] = [];
        foreach (parteFilas($p, $clave) as $i => $f) {
            $n = $i + 1;
            $desc = parteTexto($f['parte_recurso_descripcion'] ?? null);
            $cant = parteNumero($f['parte_recurso_cantidad'] ?? null, "la cantidad ($clave fila $n)");
            if ($desc === null && !($f['fk_recurso_id'] ?? null)) {
                throw new ValidacionException(ucfirst(str_replace('_', ' ', $clave)) . " fila $n: indique la descripción");
            }
            if ($cant === null || $cant <= 0) {
                throw new ValidacionException(ucfirst(str_replace('_', ' ', $clave)) . " fila $n: la cantidad debe ser mayor a 0");
            }
            $recursos[$clave][] = ['fk_recurso_id' => parteEntero($f['fk_recurso_id'] ?? null, 'el recurso', 1),
                'fk_estacion_id' => parteEntero($f['fk_estacion_id'] ?? null, "la estación ($clave fila $n)", 1),
                'parte_recurso_descripcion' => $desc ? mb_strtoupper($desc) : null, 'parte_recurso_cantidad' => $cant,
                'parte_recurso_observaciones' => parteTexto($f['parte_recurso_observaciones'] ?? null)];
        }
    }
    $asistidas = array_map(fn($f) => [
        'parte_persona_institucion' => parteTexto($f['parte_persona_institucion'] ?? null), 'parte_persona_tipo_institucion' => parteTexto($f['parte_persona_tipo_institucion'] ?? null),
        'parte_persona_nombre' => parteTexto($f['parte_persona_nombre'] ?? null), 'parte_persona_identificacion' => parteTexto($f['parte_persona_identificacion'] ?? null),
        'parte_persona_telefono' => parteTexto($f['parte_persona_telefono'] ?? null), 'parte_persona_propiedad' => parteTexto($f['parte_persona_propiedad'] ?? null),
    ], parteFilas($p, 'personas_asistidas'));
    $victimas = [];
    foreach (parteFilas($p, 'victimas') as $i => $f) {
        $victimas[] = ['parte_victima_numero_hoja' => parteTexto($f['parte_victima_numero_hoja'] ?? null),
            'parte_victima_tipo_identificacion' => parteTexto($f['parte_victima_tipo_identificacion'] ?? null),
            'parte_victima_identificacion' => parteTexto($f['parte_victima_identificacion'] ?? null), 'parte_victima_nombres' => parteTexto($f['parte_victima_nombres'] ?? null),
            'parte_victima_edad' => parteEntero($f['parte_victima_edad'] ?? null, 'la edad (víctima fila ' . ($i + 1) . ')', 0, 130),
            'parte_victima_tipo_edad' => parteTexto($f['parte_victima_tipo_edad'] ?? null), 'parte_victima_sexo' => parteTexto($f['parte_victima_sexo'] ?? null),
            'parte_victima_signos_sintomas' => parteTexto($f['parte_victima_signos_sintomas'] ?? null), 'parte_victima_traslado' => parteTexto($f['parte_victima_traslado'] ?? null)];
    }
    $fallecidos = [];
    foreach (parteFilas($p, 'fallecidos') as $i => $f) {
        $fallecidos[] = ['parte_fallecido_numero' => parteTexto($f['parte_fallecido_numero'] ?? null),
            'parte_fallecido_tipo_identificacion' => parteTexto($f['parte_fallecido_tipo_identificacion'] ?? null),
            'parte_fallecido_identificacion' => parteTexto($f['parte_fallecido_identificacion'] ?? null), 'parte_fallecido_nombres' => parteTexto($f['parte_fallecido_nombres'] ?? null),
            'parte_fallecido_edad' => parteEntero($f['parte_fallecido_edad'] ?? null, 'la edad (fallecido fila ' . ($i + 1) . ')', 0, 130),
            'parte_fallecido_tipo_edad' => parteTexto($f['parte_fallecido_tipo_edad'] ?? null), 'parte_fallecido_sexo' => parteTexto($f['parte_fallecido_sexo'] ?? null),
            'parte_fallecido_observaciones' => parteTexto($f['parte_fallecido_observaciones'] ?? null), 'parte_fallecido_traslado' => parteTexto($f['parte_fallecido_traslado'] ?? null)];
    }
    $ids = fn(string $k) => array_values(array_unique(array_filter(array_map(fn($v) => parteEntero(is_object($v) ? null : $v, $k, 1), (array) prop($p, $k, [])))));

    $texto = fn(string $c) => parteTexto(prop($p, $c));
    $calle = $texto('parte_calle_principal');
    $direccion = $texto('parte_direccion') ?? (implode(' y ', array_filter([$calle, $texto('parte_calle_secundaria')])) ?: null);
    $parroquia = parteEntero(prop($p, 'parte_parroquia'), 'la parroquia', 1);
    $cab = [
        'parte_tipo' => $tipo, 'parte_estado' => $estado, 'fk_estacion_id' => $estacion, 'parte_fecha' => $fecha, 'parte_fecha_aviso' => $fechaAviso,
        'parte_hora_aviso' => parteHora(prop($p, 'parte_hora_aviso'), 'la hora del aviso', true),
        'parte_hora_transferencia_ecu' => parteEntero(prop($p, 'parte_hora_transferencia_ecu'), 'la hora de transferencia del ECU', 0, 23),
        'parte_minuto_transferencia_ecu' => parteEntero(prop($p, 'parte_minuto_transferencia_ecu'), 'los minutos de transferencia del ECU', 0, 59),
        'parte_hora_salida' => $tiempos['salida'], 'parte_hora_arribo' => $tiempos['arribo'], 'parte_hora_finalizacion' => $tiempos['fin'],
        'parte_hora_retorno' => parteHora(prop($p, 'parte_hora_retorno'), 'la hora de retorno'),
        'fk_personal_id' => $mando[0]['fk_personal_id'],
        'fk_personal_despacho_id' => parteEntero(prop($p, 'fk_personal_despacho_id'), 'el responsable de despacho', 1),
        'parte_provincia' => parteEntero(prop($p, 'parte_provincia'), 'la provincia', 1),
        'parte_canton' => parteEntero(prop($p, 'parte_canton'), 'el cantón', 1),
        'parte_parroquia' => $parroquia, 'fk_parroquia_id' => $parroquia,
        'parte_direccion' => $direccion, 'parte_apoyo_requerido' => $apoyoRequerido ?: null,
        'parte_area_destruida_m2' => parteNumero(prop($p, 'parte_area_destruida_m2'), 'el área destruida') ?? 0,
        'parte_total_superficie_quemada_m2' => parteNumero(prop($p, 'parte_total_superficie_quemada_m2'), 'la superficie quemada'),
        'parte_especies_predominantes' => $texto('parte_especies_predominantes') ?? 'NINGUNA',
        'parte_total_superficie_quemada' => $texto('parte_total_superficie_quemada') ?? 'NINGUNA',
        'parte_danios_materiales' => parteTextoLargo(prop($p, 'parte_danios_materiales')) ?? 'NINGUNO',
        'parte_descripcion_operaciones' => $descripcion,
        'parte_novedades' => parteTextoLargo(prop($p, 'parte_novedades')),
        'parte_latitud' => $lat, 'parte_longitud' => $lng,
        'parte_causante_identificado' => parteBool(prop($p, 'parte_causante_identificado')),
        'parte_anexo_requerido' => parteBool(prop($p, 'parte_anexo_requerido')),
        'parte_visita_inspectores' => parteBool(prop($p, 'parte_visita_inspectores')),
        'parte_fecha_entrega' => parteFecha(prop($p, 'parte_fecha_entrega'), 'la fecha de entrega'),
        'parte_total_muertos' => count($fallecidos), 'parte_total_heridos' => count($victimas),
        'parte_mapa_tipo' => in_array(strtoupper((string) prop($p, 'parte_mapa_tipo', 'CALLES')), MAPA_TIPOS, true)
            ? strtoupper((string) prop($p, 'parte_mapa_tipo', 'CALLES')) : 'CALLES',
    ];
    foreach (['parte_tipo_dia', 'parte_forma_aviso', 'parte_codigo_salida', 'parte_grupo_asiste', 'parte_apoyo', 'parte_apoyo_otros',
                 'parte_calle_principal', 'parte_calle_secundaria', 'parte_numero_domicilio', 'parte_telefono', 'parte_sector', 'parte_tipo_sector',
                 'parte_referencia', 'parte_informacion_alertante', 'parte_institucion_tipo', 'parte_institucion_propiedad', 'parte_observacion_institucion',
                 'parte_observacion_victimas', 'parte_observacion_fallecidos', 'parte_tipo_afectado', 'parte_afectado_propietario',
                 'parte_afectado_arrendatario', 'parte_afectado_otros', 'parte_lugar_posible_inicio', 'parte_personas_institucion',
                 'parte_nombre_representante', 'parte_propietario_afectado', 'parte_datos_adicionales', 'parte_nombre_causante',
                 'parte_otros_datos_causante', 'parte_naturaleza_especifique', 'parte_visita_inspectores_motivo', 'parte_croquis_url',
                 'parte_elaborado_por', 'parte_revisado_por', 'parte_aprobado_por', 'parte_entregado_a', 'parte_entregado_identificacion'] as $c) {
        $cab[$c] = $texto($c);
    }
    if ($cab['parte_croquis_url'] !== null && !preg_match('#^https?://#i', $cab['parte_croquis_url'])) {
        throw new ValidacionException('El enlace del croquis debe empezar con http:// o https://');
    }
    return ['cab' => $cab, 'personal' => $personal, 'vehiculos' => $vehiculos, 'tipos_auxilio' => $tiposAuxilio, 'causas' => $causas,
        'recursos' => $recursos, 'personas_asistidas' => $asistidas, 'victimas' => $victimas, 'fallecidos' => $fallecidos,
        'tipos_incendio' => $tipo === 'INCENDIO' ? $ids('tipos_incendio') : [], 'naturalezas' => $tipo === 'INCENDIO' ? $ids('naturalezas') : []];
}

/** Horas de la cabecera a partir de los vehículos: primera salida, primer arribo, último fin de operaciones (HH:MM) */
function parteTiempos(array $vehiculos): array
{
    $hora = fn(?string $fh) => $fh ? substr($fh, 11, 5) : null;
    $col = fn(string $c) => array_values(array_filter(array_column($vehiculos, $c)));
    $salidas = $col('parte_vehiculo_hora_salida');
    $arribos = $col('parte_vehiculo_hora_arribo');
    $fines = $col('parte_vehiculo_hora_fin_operaciones');
    return ['salida' => $salidas ? $hora(min($salidas)) : null, 'arribo' => $arribos ? $hora(min($arribos)) : null,
        'fin' => $fines ? $hora(max($fines)) : null];
}

/** Minutos entre dos 'Y-m-d H:i[:s]' (null si falta alguno o el resultado es negativo) */
function parteMinutos(?string $desde, ?string $hasta): ?int
{
    if (!$desde || !$hasta) {
        return null;
    }
    $m = (int) round((strtotime($hasta) - strtotime($desde)) / 60);
    return $m >= 0 ? $m : null;
}

/** Siguiente número para un parte (dentro de la transacción) */
function parteSiguienteNumero(Database $db, string $siglas, string $tipo, int $estacionId, int $anio): array
{
    $db->query('SELECT estacion_nombre FROM operaciones.tb_estaciones WHERE estacion_id = :e');
    $db->bind(':e', $estacionId);
    $estacion = $db->single();
    if (!$estacion) {
        throw new ValidacionException('La estación no existe');
    }
    $db->query('SELECT pg_advisory_xact_lock(hashtext(:k))');
    $db->bind(':k', "operaciones.tb_partes.$anio.$estacionId." . partePrefijo($tipo));
    $db->execute();
    $db->query("SELECT COALESCE(MAX(parte_serie), 0) + 1 AS serie FROM operaciones.tb_partes
                 WHERE parte_anio = :a AND fk_estacion_id = :e AND (CASE WHEN parte_tipo = 'INCENDIO' THEN 'PI' ELSE 'PA' END) = :pr");
    $db->bind(':a', $anio);
    $db->bind(':e', $estacionId);
    $db->bind(':pr', partePrefijo($tipo));
    $serie = (int) $db->single()['serie'];
    return ['serie' => $serie, 'numero' => parteCodigo($siglas, $tipo, $estacion['estacion_nombre'], $anio, $serie)];
}

/** Id del recurso en el catálogo; lo crea si es nuevo (las descripciones se guardan en mayúsculas) */
function parteRecursoId(Database $db, string $tipo, string $descripcion): int
{
    $db->query('INSERT INTO operaciones.tb_partes_catalogo_recursos (recurso_tipo, recurso_descripcion) VALUES (:t, :d)
                ON CONFLICT (recurso_tipo, upper(recurso_descripcion)) DO NOTHING');
    $db->bind(':t', $tipo);
    $db->bind(':d', mb_strtoupper($descripcion));
    $db->execute();
    $db->query('SELECT recurso_id FROM operaciones.tb_partes_catalogo_recursos WHERE recurso_tipo = :t AND upper(recurso_descripcion) = upper(:d)');
    $db->bind(':t', $tipo);
    $db->bind(':d', $descripcion);
    return (int) $db->single()['recurso_id'];
}

/** Inserta una fila con las columnas del arreglo */
function parteInsertar(Database $db, string $tabla, array $fila): void
{
    $cols = array_keys($fila);
    $db->query("INSERT INTO $tabla (" . implode(', ', $cols) . ') VALUES (:' . implode(', :', $cols) . ')');
    foreach ($fila as $c => $v) {
        $db->bind(":$c", is_bool($v) ? ($v ? 'true' : 'false') : $v);
    }
    $db->execute();
}

/** Guarda los detalles (reemplaza los existentes del parte). Completa enlaces a catálogos y datos del vehículo. */
function parteGuardarDetalles(Database $db, int $id, array $d): void
{
    foreach (['tb_partes_personal', 'tb_partes_vehiculos', 'tb_partes_tipos_auxilio', 'tb_partes_causas', 'tb_partes_equipos_herramientas',
                 'tb_partes_materiales_descartables', 'tb_partes_insumos', 'tb_partes_personas_asistidas', 'tb_partes_victimas',
                 'tb_partes_fallecidos', 'tb_partes_tipos_incendio', 'tb_partes_naturalezas'] as $t) {
        $db->query("DELETE FROM operaciones.$t WHERE fk_parte_id = :id");
        $db->bind(':id', $id);
        $db->execute();
    }
    foreach ($d['personal'] as $f) {
        parteInsertar($db, 'operaciones.tb_partes_personal', ['fk_parte_id' => $id] + $f);
    }
    foreach ($d['vehiculos'] as $f) {
        if ($f['fk_vehiculo_id']) {
            // Placa, siglas y estación del registro del vehículo (la estadística agrupa por fk_vehiculo_id)
            $db->query('SELECT vehiculo_placa, vehiculo_sigla, fk_estacion_id FROM administrativo.tb_vehiculos WHERE vehiculo_id = :v');
            $db->bind(':v', $f['fk_vehiculo_id']);
            $v = $db->single();
            if (!$v) {
                throw new ValidacionException('Uno de los vehículos no existe');
            }
            $f['parte_vehiculo_placa'] = $v['vehiculo_placa'];
            $f['parte_vehiculo_siglas'] = $v['vehiculo_sigla'] ?: $f['parte_vehiculo_siglas'];
            $f['fk_estacion_id'] ??= $v['fk_estacion_id'] ? (int) $v['fk_estacion_id'] : null;
        }
        parteInsertar($db, 'operaciones.tb_partes_vehiculos', ['fk_parte_id' => $id] + $f);
    }
    foreach ($d['tipos_auxilio'] as $f) {
        if (!$f['fk_tipo_auxilio_id']) {
            $db->query("SELECT tipo_auxilio_id FROM operaciones.tb_partes_catalogo_tipos_auxilio
                         WHERE tipo_auxilio_clave = '' AND tipo_auxilio_clasificacion = :c AND tipo_auxilio_subclasificacion = :s AND tipo_auxilio_uso_tipo = :u");
            $db->bind(':c', $f['parte_auxilio_clasificacion']);
            $db->bind(':s', $f['parte_auxilio_subclasificacion'] ?? '');
            $db->bind(':u', $f['parte_auxilio_uso_tipo'] ?? '');
            $f['fk_tipo_auxilio_id'] = ($db->single()['tipo_auxilio_id'] ?? null) ?: null;
        }
        parteInsertar($db, 'operaciones.tb_partes_tipos_auxilio', ['fk_parte_id' => $id] + $f);
    }
    foreach ($d['causas'] as $f) {
        if (!$f['fk_causa_id'] && $f['parte_causa_clasificacion'] !== null) {
            $db->query('SELECT causa_id FROM operaciones.tb_partes_catalogo_causas WHERE causa_clasificacion = :c AND causa_descripcion = :d');
            $db->bind(':c', $f['parte_causa_clasificacion']);
            $db->bind(':d', $f['parte_causa_descripcion']);
            $f['fk_causa_id'] = ($db->single()['causa_id'] ?? null) ?: null;
        }
        parteInsertar($db, 'operaciones.tb_partes_causas', ['fk_parte_id' => $id] + $f);
    }
    foreach (PARTE_RECURSOS as $clave => [$tabla, $tipo]) {
        foreach ($d['recursos'][$clave] as $f) {
            if ($f['fk_recurso_id']) {
                $db->query('SELECT recurso_descripcion FROM operaciones.tb_partes_catalogo_recursos WHERE recurso_id = :r AND recurso_tipo = :t');
                $db->bind(':r', $f['fk_recurso_id']);
                $db->bind(':t', $tipo);
                $r = $db->single();
                if (!$r) {
                    throw new ValidacionException('Uno de los recursos no pertenece a la lista correspondiente');
                }
                $f['parte_recurso_descripcion'] = $r['recurso_descripcion'];
            } else {
                $f['fk_recurso_id'] = parteRecursoId($db, $tipo, $f['parte_recurso_descripcion']);
            }
            parteInsertar($db, $tabla, ['fk_parte_id' => $id] + $f);
        }
    }
    foreach (['personas_asistidas' => 'tb_partes_personas_asistidas', 'victimas' => 'tb_partes_victimas', 'fallecidos' => 'tb_partes_fallecidos'] as $k => $t) {
        foreach ($d[$k] as $f) {
            parteInsertar($db, "operaciones.$t", ['fk_parte_id' => $id] + $f);
        }
    }
    foreach ($d['tipos_incendio'] as $cat) {
        $db->query('INSERT INTO operaciones.tb_partes_tipos_incendio (fk_parte_id, fk_tipo_incendio_catalogo_id, parte_incendio_clave, parte_incendio_clasificacion)
                    SELECT :id, tipo_incendio_id, tipo_incendio_codigo, tipo_incendio_descripcion FROM operaciones.tb_partes_catalogo_tipos_incendio WHERE tipo_incendio_id = :c');
        $db->bind(':id', $id);
        $db->bind(':c', $cat);
        $db->execute();
    }
    foreach ($d['naturalezas'] as $cat) {
        $db->query('INSERT INTO operaciones.tb_partes_naturalezas (fk_parte_id, fk_naturaleza_catalogo_id, parte_naturaleza_clave, parte_naturaleza_descripcion)
                    SELECT :id, naturaleza_id, naturaleza_codigo, naturaleza_descripcion FROM operaciones.tb_partes_catalogo_naturalezas WHERE naturaleza_id = :c');
        $db->bind(':id', $id);
        $db->bind(':c', $cat);
        $db->execute();
    }
}

/** Parte completo con sus detalles (null si no existe) */
function parteObtener(Database $db, int $id): ?array
{
    $db->query("SELECT p.*, p.parte_fecha::text AS parte_fecha, p.parte_fecha_aviso::text AS parte_fecha_aviso, p.parte_fecha_entrega::text AS parte_fecha_entrega,
                       to_char(p.parte_hora_aviso, 'HH24:MI') AS parte_hora_aviso, to_char(p.parte_hora_retorno, 'HH24:MI') AS parte_hora_retorno,
                       e.estacion_nombre
                  FROM operaciones.tb_partes p LEFT JOIN operaciones.tb_estaciones e ON e.estacion_id = p.fk_estacion_id
                 WHERE p.parte_id = :id");
    $db->bind(':id', $id);
    $parte = $db->single();
    if (!$parte) {
        return null;
    }
    $detalle = function (string $sql) use ($db, $id): array {
        $db->query($sql);
        $db->bind(':id', $id);
        return $db->resultset();
    };
    $parte['personal'] = $detalle("SELECT d.*, concat_ws(' ', pe.persona_apellidos, pe.persona_nombres) AS nombre
                                     FROM operaciones.tb_partes_personal d
                                     LEFT JOIN tthh.tb_personal t ON t.personal_id = d.fk_personal_id
                                     LEFT JOIN resources.tb_personas pe ON pe.persona_id = t.fk_persona_id
                                    WHERE d.fk_parte_id = :id ORDER BY d.parte_personal_id");
    $parte['vehiculos'] = $detalle("SELECT d.*, to_char(d.parte_vehiculo_hora_despacho, 'YYYY-MM-DD\"T\"HH24:MI') AS parte_vehiculo_hora_despacho,
                                           to_char(d.parte_vehiculo_hora_salida, 'YYYY-MM-DD\"T\"HH24:MI') AS parte_vehiculo_hora_salida,
                                           to_char(d.parte_vehiculo_hora_arribo, 'YYYY-MM-DD\"T\"HH24:MI') AS parte_vehiculo_hora_arribo,
                                           to_char(d.parte_vehiculo_hora_fin_operaciones, 'YYYY-MM-DD\"T\"HH24:MI') AS parte_vehiculo_hora_fin_operaciones
                                      FROM operaciones.tb_partes_vehiculos d WHERE d.fk_parte_id = :id ORDER BY d.parte_vehiculo_id");
    $parte['tipos_auxilio'] = $detalle('SELECT * FROM operaciones.tb_partes_tipos_auxilio WHERE fk_parte_id = :id ORDER BY parte_tipo_auxilio_id');
    $parte['causas'] = $detalle('SELECT * FROM operaciones.tb_partes_causas WHERE fk_parte_id = :id ORDER BY parte_causa_id');
    foreach (PARTE_RECURSOS as $clave => [$tabla]) {
        $parte[$clave] = $detalle("SELECT * FROM $tabla WHERE fk_parte_id = :id ORDER BY 1");
    }
    $parte['personas_asistidas'] = $detalle('SELECT * FROM operaciones.tb_partes_personas_asistidas WHERE fk_parte_id = :id ORDER BY 1');
    $parte['victimas'] = $detalle('SELECT * FROM operaciones.tb_partes_victimas WHERE fk_parte_id = :id ORDER BY 1');
    $parte['fallecidos'] = $detalle('SELECT * FROM operaciones.tb_partes_fallecidos WHERE fk_parte_id = :id ORDER BY 1');
    $parte['tipos_incendio'] = array_map('intval', array_column($detalle('SELECT fk_tipo_incendio_catalogo_id AS c FROM operaciones.tb_partes_tipos_incendio WHERE fk_parte_id = :id'), 'c'));
    $parte['naturalezas'] = array_map('intval', array_column($detalle('SELECT fk_naturaleza_catalogo_id AS c FROM operaciones.tb_partes_naturalezas WHERE fk_parte_id = :id'), 'c'));
    foreach (['parte_causante_identificado', 'parte_anexo_requerido', 'parte_visita_inspectores'] as $b) {
        $parte[$b] = $parte[$b] === null ? null : in_array($parte[$b], [true, 't', 1, '1'], true);
    }
    return $parte;
}

/**
 * Estadística de partes no anulados del período: resumen, por mes, estación, vehículo, bombero, recurso, tipo de auxilio,
 * causa, día de la semana y hora del aviso. Tiempo de respuesta = aviso -> primer arribo (se descartan valores > 24 h).
 */
function parteEstadisticas(Database $db, string $desde, string $hasta, ?int $estacion = null, ?string $tipo = null): array
{
    $filtro = "p.parte_estado <> 'ANULADO' AND p.parte_fecha BETWEEN :d AND :h"
        . ($estacion ? ' AND p.fk_estacion_id = :e' : '') . ($tipo ? ' AND p.parte_tipo = :t' : '');
    $base = "WITH base AS (
                SELECT p.*, (COALESCE(p.parte_fecha_aviso, p.parte_fecha) + p.parte_hora_aviso) AS aviso_ts,
                       (SELECT MIN(v.parte_vehiculo_hora_arribo) FROM operaciones.tb_partes_vehiculos v WHERE v.fk_parte_id = p.parte_id) AS arribo_ts,
                       (SELECT MIN(v.parte_vehiculo_hora_salida) FROM operaciones.tb_partes_vehiculos v WHERE v.fk_parte_id = p.parte_id) AS salida_ts,
                       (SELECT MAX(v.parte_vehiculo_hora_fin_operaciones) FROM operaciones.tb_partes_vehiculos v WHERE v.fk_parte_id = p.parte_id) AS fin_ts
                  FROM operaciones.tb_partes p WHERE $filtro),
             b AS (SELECT base.*,
                          CASE WHEN arribo_ts >= aviso_ts AND arribo_ts - aviso_ts <= interval '24 hours'
                               THEN extract(epoch FROM arribo_ts - aviso_ts) / 60 END AS respuesta_min,
                          CASE WHEN fin_ts >= salida_ts AND fin_ts - salida_ts <= interval '48 hours'
                               THEN extract(epoch FROM fin_ts - salida_ts) / 3600 END AS duracion_h
                     FROM base) ";
    $consulta = function (string $sql) use ($db, $base, $desde, $hasta, $estacion, $tipo): array {
        $db->query($base . $sql);
        $db->bind(':d', $desde);
        $db->bind(':h', $hasta);
        if ($estacion) {
            $db->bind(':e', $estacion);
        }
        if ($tipo) {
            $db->bind(':t', $tipo);
        }
        return $db->resultset();
    };
    $num = fn($v, int $dec = 1) => $v === null ? null : round((float) $v, $dec);

    $r = $consulta("SELECT count(*) AS partes, count(*) FILTER (WHERE parte_tipo = 'AUXILIO') AS auxilio,
                           count(*) FILTER (WHERE parte_tipo = 'INCENDIO') AS incendio,
                           COALESCE(sum(parte_total_heridos), 0) AS victimas, COALESCE(sum(parte_total_muertos), 0) AS fallecidos,
                           (SELECT count(*) FROM operaciones.tb_partes_personas_asistidas a WHERE a.fk_parte_id IN (SELECT parte_id FROM b)) AS personas_asistidas,
                           avg(respuesta_min) AS respuesta_prom, percentile_cont(0.5) WITHIN GROUP (ORDER BY respuesta_min) AS respuesta_mediana,
                           COALESCE(sum(duracion_h), 0) AS horas_operacion,
                           (SELECT COALESCE(sum(v.parte_vehiculo_km_retorno - v.parte_vehiculo_km_salida), 0) FROM operaciones.tb_partes_vehiculos v
                             WHERE v.fk_parte_id IN (SELECT parte_id FROM b) AND v.parte_vehiculo_km_retorno >= v.parte_vehiculo_km_salida) AS km
                      FROM b")[0];
    $resumen = ['partes' => (int) $r['partes'], 'auxilio' => (int) $r['auxilio'], 'incendio' => (int) $r['incendio'],
        'victimas' => (int) $r['victimas'], 'fallecidos' => (int) $r['fallecidos'], 'personas_asistidas' => (int) $r['personas_asistidas'],
        'respuesta_prom_min' => $num($r['respuesta_prom']), 'respuesta_mediana_min' => $num($r['respuesta_mediana']),
        'horas_operacion' => $num($r['horas_operacion']), 'km' => $num($r['km'], 0)];

    $porMes = array_map(fn($x) => ['mes' => $x['mes'], 'auxilio' => (int) $x['auxilio'], 'incendio' => (int) $x['incendio']],
        $consulta("SELECT to_char(m, 'YYYY-MM') AS mes,
                          (SELECT count(*) FROM b WHERE date_trunc('month', parte_fecha) = m AND parte_tipo = 'AUXILIO') AS auxilio,
                          (SELECT count(*) FROM b WHERE date_trunc('month', parte_fecha) = m AND parte_tipo = 'INCENDIO') AS incendio
                     FROM generate_series(date_trunc('month', :d::date), date_trunc('month', :h::date), interval '1 month') AS m ORDER BY m"));

    $porEstacion = array_map(fn($x) => ['estacion_id' => (int) $x['estacion_id'], 'estacion' => $x['estacion'], 'partes' => (int) $x['partes'],
        'auxilio' => (int) $x['auxilio'], 'incendio' => (int) $x['incendio'], 'respuesta_prom_min' => $num($x['respuesta']),
        'salidas_vehiculos' => (int) $x['salidas'], 'participaciones' => (int) $x['participaciones']],
        $consulta("SELECT b.fk_estacion_id AS estacion_id, e.estacion_nombre AS estacion, count(*) AS partes,
                          count(*) FILTER (WHERE parte_tipo = 'AUXILIO') AS auxilio, count(*) FILTER (WHERE parte_tipo = 'INCENDIO') AS incendio,
                          avg(respuesta_min) AS respuesta,
                          (SELECT count(*) FROM operaciones.tb_partes_vehiculos v JOIN b b2 ON b2.parte_id = v.fk_parte_id WHERE b2.fk_estacion_id = b.fk_estacion_id) AS salidas,
                          (SELECT count(*) FROM operaciones.tb_partes_personal x JOIN b b2 ON b2.parte_id = x.fk_parte_id WHERE b2.fk_estacion_id = b.fk_estacion_id) AS participaciones
                     FROM b LEFT JOIN operaciones.tb_estaciones e ON e.estacion_id = b.fk_estacion_id
                    GROUP BY b.fk_estacion_id, e.estacion_nombre ORDER BY partes DESC, estacion"));

    $porVehiculo = array_map(fn($x) => ['vehiculo_id' => $x['vehiculo_id'] !== null ? (int) $x['vehiculo_id'] : null, 'siglas' => $x['siglas'],
        'placa' => $x['placa'], 'externo' => $x['vehiculo_id'] === null, 'salidas' => (int) $x['salidas'], 'km' => $num($x['km'], 0),
        'horas' => $num($x['horas']), 'respuesta_prom_min' => $num($x['respuesta']), 'ultima' => $x['ultima']],
        $consulta("SELECT v.fk_vehiculo_id AS vehiculo_id, COALESCE(tv.vehiculo_sigla, max(v.parte_vehiculo_siglas)) AS siglas,
                          COALESCE(tv.vehiculo_placa, v.parte_vehiculo_placa) AS placa, count(DISTINCT v.fk_parte_id) AS salidas,
                          sum(v.parte_vehiculo_km_retorno - v.parte_vehiculo_km_salida) FILTER (WHERE v.parte_vehiculo_km_retorno >= v.parte_vehiculo_km_salida) AS km,
                          sum(extract(epoch FROM v.parte_vehiculo_hora_fin_operaciones - v.parte_vehiculo_hora_salida) / 3600)
                              FILTER (WHERE v.parte_vehiculo_hora_fin_operaciones >= v.parte_vehiculo_hora_salida
                                        AND v.parte_vehiculo_hora_fin_operaciones - v.parte_vehiculo_hora_salida <= interval '48 hours') AS horas,
                          avg(extract(epoch FROM v.parte_vehiculo_hora_arribo - b.aviso_ts) / 60)
                              FILTER (WHERE v.parte_vehiculo_hora_arribo >= b.aviso_ts AND v.parte_vehiculo_hora_arribo - b.aviso_ts <= interval '24 hours') AS respuesta,
                          max(b.parte_fecha)::text AS ultima
                     FROM operaciones.tb_partes_vehiculos v JOIN b ON b.parte_id = v.fk_parte_id
                     LEFT JOIN administrativo.tb_vehiculos tv ON tv.vehiculo_id = v.fk_vehiculo_id
                    GROUP BY v.fk_vehiculo_id, tv.vehiculo_sigla, tv.vehiculo_placa, CASE WHEN v.fk_vehiculo_id IS NULL THEN v.parte_vehiculo_placa END,
                             COALESCE(tv.vehiculo_placa, v.parte_vehiculo_placa)
                    ORDER BY salidas DESC, siglas"));

    $porBombero = array_map(fn($x) => ['personal_id' => (int) $x['personal_id'], 'nombre' => $x['nombre'], 'rango' => $x['rango'],
        'participaciones' => (int) $x['participaciones'], 'al_mando' => (int) $x['al_mando'], 'aph' => (int) $x['aph'],
        'operativo' => (int) $x['operativo'], 'horas' => $num($x['horas']), 'ultima' => $x['ultima']],
        $consulta("SELECT x.fk_personal_id AS personal_id, concat_ws(' ', pe.persona_apellidos, pe.persona_nombres) AS nombre,
                          (array_agg(x.parte_personal_rango ORDER BY b.parte_fecha DESC) FILTER (WHERE x.parte_personal_rango IS NOT NULL))[1] AS rango,
                          count(DISTINCT x.fk_parte_id) AS participaciones,
                          count(*) FILTER (WHERE x.parte_personal_rol = 'PERSONA AL MANDO DE LA EMERGENCIA') AS al_mando,
                          count(*) FILTER (WHERE x.parte_personal_rol = 'PERSONAL DE APH') AS aph,
                          count(*) FILTER (WHERE x.parte_personal_rol = 'PERSONAL OPERATIVO') AS operativo,
                          sum(b.duracion_h) AS horas, max(b.parte_fecha)::text AS ultima
                     FROM operaciones.tb_partes_personal x JOIN b ON b.parte_id = x.fk_parte_id
                     LEFT JOIN tthh.tb_personal t ON t.personal_id = x.fk_personal_id
                     LEFT JOIN resources.tb_personas pe ON pe.persona_id = t.fk_persona_id
                    GROUP BY x.fk_personal_id, pe.persona_apellidos, pe.persona_nombres ORDER BY participaciones DESC, nombre"));

    $porRecurso = array_map(fn($x) => ['tipo' => $x['tipo'], 'recurso_id' => $x['recurso_id'] !== null ? (int) $x['recurso_id'] : null,
        'descripcion' => $x['descripcion'], 'partes' => (int) $x['partes'], 'cantidad' => $num($x['cantidad'], 2)],
        $consulta("SELECT tipo, fk_recurso_id AS recurso_id, max(descripcion) AS descripcion, count(DISTINCT fk_parte_id) AS partes, sum(cantidad) AS cantidad FROM (
                        SELECT 'EQUIPO' AS tipo, fk_recurso_id, upper(parte_recurso_descripcion) AS descripcion, fk_parte_id, parte_recurso_cantidad AS cantidad
                          FROM operaciones.tb_partes_equipos_herramientas
                        UNION ALL SELECT 'MATERIAL', fk_recurso_id, upper(parte_recurso_descripcion), fk_parte_id, parte_recurso_cantidad
                          FROM operaciones.tb_partes_materiales_descartables
                        UNION ALL SELECT 'INSUMO', fk_recurso_id, upper(parte_recurso_descripcion), fk_parte_id, parte_recurso_cantidad
                          FROM operaciones.tb_partes_insumos) r
                    WHERE fk_parte_id IN (SELECT parte_id FROM b)
                    GROUP BY tipo, fk_recurso_id, CASE WHEN fk_recurso_id IS NULL THEN descripcion END
                    ORDER BY partes DESC, cantidad DESC, descripcion"));

    $porTipoAuxilio = array_map(fn($x) => ['clasificacion' => $x['clasificacion'], 'subclasificacion' => $x['subclasificacion'], 'partes' => (int) $x['partes']],
        $consulta("SELECT COALESCE(ta.parte_auxilio_clasificacion, 'Sin clasificar') AS clasificacion, COALESCE(ta.parte_auxilio_subclasificacion, '') AS subclasificacion,
                          count(DISTINCT ta.fk_parte_id) AS partes
                     FROM operaciones.tb_partes_tipos_auxilio ta JOIN b ON b.parte_id = ta.fk_parte_id
                    GROUP BY 1, 2 ORDER BY partes DESC, 1, 2"));
    $porCausa = array_map(fn($x) => ['clasificacion' => $x['clasificacion'], 'descripcion' => $x['descripcion'], 'partes' => (int) $x['partes']],
        $consulta("SELECT COALESCE(c.parte_causa_clasificacion, '') AS clasificacion, c.parte_causa_descripcion AS descripcion, count(DISTINCT c.fk_parte_id) AS partes
                     FROM operaciones.tb_partes_causas c JOIN b ON b.parte_id = c.fk_parte_id
                    GROUP BY 1, 2 ORDER BY partes DESC, 1, 2"));
    $porDia = array_fill(1, 7, 0);
    foreach ($consulta('SELECT extract(isodow FROM aviso_ts)::int AS d, count(*) AS n FROM b WHERE aviso_ts IS NOT NULL GROUP BY 1') as $x) {
        $porDia[(int) $x['d']] = (int) $x['n'];
    }
    $porHora = array_fill(0, 24, 0);
    foreach ($consulta('SELECT extract(hour FROM parte_hora_aviso)::int AS h, count(*) AS n FROM b WHERE parte_hora_aviso IS NOT NULL GROUP BY 1') as $x) {
        $porHora[(int) $x['h']] = (int) $x['n'];
    }
    return ['desde' => $desde, 'hasta' => $hasta, 'resumen' => $resumen, 'por_mes' => $porMes, 'por_estacion' => $porEstacion,
        'por_vehiculo' => $porVehiculo, 'por_bombero' => $porBombero, 'por_recurso' => $porRecurso, 'por_tipo_auxilio' => $porTipoAuxilio,
        'por_causa' => $porCausa, 'por_dia_semana' => array_values($porDia), 'por_hora' => $porHora];
}

/**
 * Consultas sobre los partes NO anulados del período (CTE "b" con respuesta_min). $tipo: 'INCENDIO', 'AUXILIO' o null.
 * Devuelve una función ($sql) => filas.
 */
function parteConsultaPeriodo(Database $db, string $desde, string $hasta, ?int $estacion, ?string $tipo): callable
{
    $filtro = "p.parte_estado <> 'ANULADO' AND p.parte_fecha BETWEEN :d AND :h" . ($estacion ? ' AND p.fk_estacion_id = :e' : '') . ($tipo ? ' AND p.parte_tipo = :t' : '');
    $base = "WITH b AS (
                SELECT p.*, (COALESCE(p.parte_fecha_aviso, p.parte_fecha) + p.parte_hora_aviso) AS aviso_ts,
                       (SELECT extract(epoch FROM MIN(v.parte_vehiculo_hora_arribo) - (COALESCE(p.parte_fecha_aviso, p.parte_fecha) + p.parte_hora_aviso)) / 60
                          FROM operaciones.tb_partes_vehiculos v WHERE v.fk_parte_id = p.parte_id) AS respuesta_bruta
                  FROM operaciones.tb_partes p WHERE $filtro),
             c AS (SELECT b.*, CASE WHEN respuesta_bruta BETWEEN 0 AND 1440 THEN respuesta_bruta END AS respuesta_min FROM b) ";
    return function (string $sql) use ($db, $base, $desde, $hasta, $estacion, $tipo): array {
        $db->query($base . $sql);
        $db->bind(':d', $desde);
        $db->bind(':h', $hasta);
        if ($estacion) {
            $db->bind(':e', $estacion);
        }
        if ($tipo) {
            $db->bind(':t', $tipo);
        }
        return $db->resultset();
    };
}

/**
 * Estadística de EMERGENCIAS para la Subjefatura (panel por tipo): resumen, por mes, y para incendio y auxilio por
 * separado: lugar (parroquia, sector), hora y día del aviso, causas y lo propio de cada tipo (tipos de incendio,
 * naturaleza, área destruida, causante / clasificación y subclasificación del auxilio), más los puntos del mapa.
 */
function parteEstadisticasEmergencias(Database $db, string $desde, string $hasta, ?int $estacion = null): array
{
    $num = fn($v, int $dec = 1) => $v === null ? null : round((float) $v, $dec);
    $todos = parteConsultaPeriodo($db, $desde, $hasta, $estacion, null);
    $r = $todos("SELECT count(*) AS partes, count(*) FILTER (WHERE parte_tipo = 'INCENDIO') AS incendio, count(*) FILTER (WHERE parte_tipo = 'AUXILIO') AS auxilio,
                        COALESCE(sum(parte_total_heridos), 0) AS victimas, COALESCE(sum(parte_total_muertos), 0) AS fallecidos, avg(respuesta_min) AS respuesta FROM c")[0];
    $porMes = array_map(fn($x) => ['mes' => $x['mes'], 'incendio' => (int) $x['incendio'], 'auxilio' => (int) $x['auxilio']],
        $todos("SELECT to_char(m, 'YYYY-MM') AS mes,
                       (SELECT count(*) FROM c WHERE date_trunc('month', parte_fecha) = m AND parte_tipo = 'INCENDIO') AS incendio,
                       (SELECT count(*) FROM c WHERE date_trunc('month', parte_fecha) = m AND parte_tipo = 'AUXILIO') AS auxilio
                  FROM generate_series(date_trunc('month', :d::date), date_trunc('month', :h::date), interval '1 month') AS m ORDER BY m"));
    $puntos = array_map(fn($x) => ['parte_id' => (int) $x['parte_id'], 'numero' => $x['parte_numero'], 'tipo' => $x['parte_tipo'], 'fecha' => $x['parte_fecha'],
        'lat' => (float) $x['parte_latitud'], 'lng' => (float) $x['parte_longitud'], 'detalle' => $x['detalle']],
        $todos("SELECT parte_id, parte_numero, parte_tipo, parte_fecha::text AS parte_fecha, parte_latitud, parte_longitud,
                       COALESCE((SELECT string_agg(DISTINCT concat_ws(' / ', ta.parte_auxilio_clasificacion, ta.parte_auxilio_subclasificacion), ', ')
                                   FROM operaciones.tb_partes_tipos_auxilio ta WHERE ta.fk_parte_id = c.parte_id),
                                (SELECT string_agg(ti.parte_incendio_clasificacion, ', ') FROM operaciones.tb_partes_tipos_incendio ti WHERE ti.fk_parte_id = c.parte_id),
                                parte_sector) AS detalle
                  FROM c WHERE parte_latitud IS NOT NULL AND parte_longitud IS NOT NULL ORDER BY parte_fecha DESC LIMIT 2000"));

    $seccion = function (string $tipo) use ($db, $desde, $hasta, $estacion, $num): array {
        $q = parteConsultaPeriodo($db, $desde, $hasta, $estacion, $tipo);
        $r = $q("SELECT count(*) AS partes, COALESCE(sum(parte_total_heridos), 0) AS victimas, COALESCE(sum(parte_total_muertos), 0) AS fallecidos,
                        avg(respuesta_min) AS respuesta, COALESCE(sum(parte_area_destruida_m2), 0) AS area, COALESCE(sum(parte_total_superficie_quemada_m2), 0) AS superficie,
                        count(*) FILTER (WHERE parte_causante_identificado) AS causante_si, count(*) FILTER (WHERE parte_causante_identificado = false) AS causante_no
                   FROM c")[0];
        $conteo = fn(string $sql) => array_map(fn($x) => ['nombre' => $x['nombre'], 'detalle' => $x['detalle'] ?? null, 'partes' => (int) $x['partes']], $q($sql));
        $dia = array_fill(1, 7, 0);
        foreach ($q('SELECT extract(isodow FROM aviso_ts)::int AS d, count(*) AS n FROM c WHERE aviso_ts IS NOT NULL GROUP BY 1') as $x) {
            $dia[(int) $x['d']] = (int) $x['n'];
        }
        $hora = array_fill(0, 24, 0);
        foreach ($q('SELECT extract(hour FROM parte_hora_aviso)::int AS h, count(*) AS n FROM c WHERE parte_hora_aviso IS NOT NULL GROUP BY 1') as $x) {
            $hora[(int) $x['h']] = (int) $x['n'];
        }
        $s = [
            'resumen' => ['partes' => (int) $r['partes'], 'victimas' => (int) $r['victimas'], 'fallecidos' => (int) $r['fallecidos'],
                'respuesta_prom_min' => $num($r['respuesta'])],
            'por_parroquia' => $conteo("SELECT COALESCE(pa.parish_name, 'Sin parroquia') AS nombre, NULL AS detalle, count(*) AS partes
                                          FROM c LEFT JOIN resources.parishes pa ON pa.parish_id = c.parte_parroquia GROUP BY 1 ORDER BY partes DESC, 1"),
            'por_sector' => $conteo("SELECT initcap(trim(parte_sector)) AS nombre, NULL AS detalle, count(*) AS partes FROM c
                                       WHERE trim(COALESCE(parte_sector, '')) <> '' GROUP BY 1 ORDER BY partes DESC, 1 LIMIT 15"),
            'causas' => $conteo("SELECT ca.parte_causa_descripcion AS nombre, ca.parte_causa_clasificacion AS detalle, count(DISTINCT ca.fk_parte_id) AS partes
                                   FROM operaciones.tb_partes_causas ca JOIN c ON c.parte_id = ca.fk_parte_id GROUP BY 1, 2 ORDER BY partes DESC, 1"),
            'por_dia_semana' => array_values($dia), 'por_hora' => $hora,
        ];
        if ($tipo === 'INCENDIO') {
            $s['resumen'] += ['area_destruida_m2' => $num($r['area'], 2), 'superficie_quemada_m2' => $num($r['superficie'], 2),
                'causante_identificado' => (int) $r['causante_si'], 'causante_no_identificado' => (int) $r['causante_no']];
            $s['tipos_incendio'] = $conteo("SELECT ti.parte_incendio_clasificacion AS nombre, NULL AS detalle, count(DISTINCT ti.fk_parte_id) AS partes
                                              FROM operaciones.tb_partes_tipos_incendio ti JOIN c ON c.parte_id = ti.fk_parte_id GROUP BY 1 ORDER BY partes DESC, 1");
            $s['naturalezas'] = $conteo("SELECT na.parte_naturaleza_descripcion AS nombre, NULL AS detalle, count(DISTINCT na.fk_parte_id) AS partes
                                           FROM operaciones.tb_partes_naturalezas na JOIN c ON c.parte_id = na.fk_parte_id GROUP BY 1 ORDER BY partes DESC, 1");
        } else {
            $s['clasificaciones'] = $conteo("SELECT COALESCE(ta.parte_auxilio_clasificacion, 'Sin clasificar') AS nombre, NULL AS detalle, count(DISTINCT ta.fk_parte_id) AS partes
                                               FROM operaciones.tb_partes_tipos_auxilio ta JOIN c ON c.parte_id = ta.fk_parte_id GROUP BY 1 ORDER BY partes DESC, 1");
            $s['subclasificaciones'] = $conteo("SELECT concat_ws(' / ', ta.parte_auxilio_clasificacion, NULLIF(ta.parte_auxilio_subclasificacion, '')) AS nombre,
                                                       NULLIF(ta.parte_auxilio_uso_tipo, '') AS detalle, count(DISTINCT ta.fk_parte_id) AS partes
                                                  FROM operaciones.tb_partes_tipos_auxilio ta JOIN c ON c.parte_id = ta.fk_parte_id GROUP BY 1, 2 ORDER BY partes DESC, 1");
        }
        return $s;
    };
    return ['desde' => $desde, 'hasta' => $hasta,
        'resumen' => ['partes' => (int) $r['partes'], 'incendio' => (int) $r['incendio'], 'auxilio' => (int) $r['auxilio'], 'victimas' => (int) $r['victimas'],
            'fallecidos' => (int) $r['fallecidos'], 'respuesta_prom_min' => $num($r['respuesta'])],
        'por_mes' => $porMes, 'incendio' => $seccion('INCENDIO'), 'auxilio' => $seccion('AUXILIO'), 'puntos' => $puntos];
}

/**
 * Genera (o quita) la imagen de ubicación del parte: mapa del tipo elegido con el marcador en sus coordenadas.
 * Devuelve true si se generó, false si falló (el parte queda guardado sin imagen; se puede regenerar) y null si el
 * parte no tiene coordenadas. Se llama después de confirmar la transacción del parte.
 */
function parteActualizarMapa(Database $db, int $id, ?callable $tile = null): ?bool
{
    $db->query('SELECT parte_numero, parte_latitud, parte_longitud, parte_mapa_tipo, parte_mapa_archivo FROM operaciones.tb_partes WHERE parte_id = :id');
    $db->bind(':id', $id);
    $p = $db->single();
    if (!$p) {
        return null;
    }
    if ($p['parte_latitud'] === null || $p['parte_longitud'] === null) {
        if ($p['parte_mapa_archivo'] !== null) {
            $db->query('UPDATE operaciones.tb_partes SET parte_mapa_archivo = NULL, parte_mapa_generado = NULL WHERE parte_id = :id');
            $db->bind(':id', $id);
            $db->execute();
        }
        return null;
    }
    try {
        $cfg = mapaConfig($db, $p['parte_mapa_tipo'] ?: 'CALLES');
        $ruta = mapaGenerar($cfg, 'partes', $p['parte_numero'], (float) $p['parte_latitud'], (float) $p['parte_longitud'], $tile);
    } catch (Throwable $e) {
        error_log('Mapa del parte ' . $p['parte_numero'] . ': ' . $e->getMessage());
        return false;
    }
    $db->query('UPDATE operaciones.tb_partes SET parte_mapa_archivo = :a, parte_mapa_generado = now() WHERE parte_id = :id');
    $db->bind(':a', $ruta);
    $db->bind(':id', $id);
    $db->execute();
    return true;
}
