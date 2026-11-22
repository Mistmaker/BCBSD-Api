<?php
/*
 * Reglas de negocio del mantenimiento vehicular (funciones puras, sin base de datos).
 *
 * Un plan preventivo tiene reglas "cada X km a partir del km Y": los puntos de
 * mantenimiento son Y, Y+X, Y+2X, ...
 */

const MANT_ESTADO_VENCIDO = 'VENCIDO';
const MANT_ESTADO_PROXIMO = 'PROXIMO';
const MANT_ESTADO_AL_DIA = 'AL DIA';

/**
 * Siguiente punto de mantenimiento de una regla.
 *
 * - Si hubo un mantenimiento preventivo previo, este cubre los puntos que estén
 *   hasta "tolerancia" km por delante (un preventivo adelantado cuenta). El siguiente
 *   es el primer punto posterior; así un mantenimiento no realizado queda VENCIDO.
 * - Si nunca hubo uno (p. ej. vehículos migrados), se toma el primer punto que
 *   no esté más atrás que la tolerancia, para no marcar vencidos todos los puntos
 *   históricos.
 */
function mantProximoKm(float $kmActual, int $kmInicio, int $kmIntervalo, ?float $kmUltimoMantenimiento, int $tolerancia): int
{
    if ($kmIntervalo <= 0) {
        throw new InvalidArgumentException('El intervalo debe ser mayor a 0');
    }
    $base = $kmUltimoMantenimiento !== null ? $kmUltimoMantenimiento + $tolerancia + 1 : $kmActual - $tolerancia;
    if ($base <= $kmInicio) {
        return $kmInicio;
    }
    $n = (int) ceil(($base - $kmInicio) / $kmIntervalo);
    return $kmInicio + $n * $kmIntervalo;
}

function mantEstado(float $kmActual, int $kmProximo, int $tolerancia): string
{
    if ($kmActual >= $kmProximo) {
        return MANT_ESTADO_VENCIDO;
    }
    return ($kmProximo - $kmActual) <= $tolerancia ? MANT_ESTADO_PROXIMO : MANT_ESTADO_AL_DIA;
}

/**
 * Evalúa todas las reglas de un plan y devuelve la más urgente:
 * ['km_proximo', 'km_restante', 'estado', 'mantenimiento_id', 'km_intervalo'] o null si no hay reglas.
 * $reglas: lista de ['mantenimiento_id', 'mantenimiento_km_inicio', 'mantenimiento_km_intervalo'].
 */
function mantEvaluarPlan(float $kmActual, array $reglas, ?float $kmUltimoMantenimiento, int $tolerancia): ?array
{
    $masUrgente = null;
    foreach ($reglas as $regla) {
        $proximo = mantProximoKm($kmActual, (int) $regla['mantenimiento_km_inicio'], (int) $regla['mantenimiento_km_intervalo'], $kmUltimoMantenimiento, $tolerancia);
        $restante = $proximo - $kmActual;
        if ($masUrgente === null || $restante < $masUrgente['km_restante']) {
            $masUrgente = [
                'mantenimiento_id' => (int) $regla['mantenimiento_id'],
                'km_intervalo' => (int) $regla['mantenimiento_km_intervalo'],
                'km_proximo' => $proximo,
                'km_restante' => $restante,
                'estado' => mantEstado($kmActual, $proximo, $tolerancia),
            ];
        }
    }
    return $masUrgente;
}

/** Código de documento: SIGLAS + año (2 dígitos) + tipo + serie de 5 dígitos. Ej.: CBSD26MAN00012 */
function mantCodigo(string $siglas, string $tipo, int $serie, ?int $anio = null): string
{
    $anio = $anio ?? (int) date('Y');
    return strtoupper($siglas) . substr((string) $anio, -2) . strtoupper($tipo) . str_pad((string) $serie, 5, '0', STR_PAD_LEFT);
}

/** Serie de un código generado con mantCodigo() para el año en curso; null si el código tiene otro formato. */
function mantSerieDeCodigo(string $codigo, string $siglas, string $tipo, ?int $anio = null): ?int
{
    $anio = $anio ?? (int) date('Y');
    $patron = '/^' . preg_quote(strtoupper($siglas), '/') . substr((string) $anio, -2) . preg_quote(strtoupper($tipo), '/') . '(\d{5})$/';
    return preg_match($patron, strtoupper(trim($codigo)), $m) ? (int) $m[1] : null;
}

/** Valores de un parámetro tipo lista ("A|B|C"). */
function mantLista(?string $valor): array
{
    return array_values(array_filter(array_map('trim', explode('|', (string) $valor)), fn($x) => $x !== ''));
}

/**
 * Flujo de la orden:
 *   MANTENIMIENTO -> el vehículo se envía al taller
 *   RECIBIDO      -> el taller devuelve el vehículo con la documentación; se registran valores y facturas
 *   ENTREGADO     -> se generó el acta entrega-recepción
 *   ANULADA
 */
const MANT_ESTADOS_ORDEN = ['MANTENIMIENTO', 'RECIBIDO', 'ENTREGADO', 'ANULADA'];
const MANT_TRANSICIONES = [
    'MANTENIMIENTO' => ['RECIBIDO', 'ANULADA'],
    'RECIBIDO' => ['ENTREGADO', 'MANTENIMIENTO', 'ANULADA'],
    'ENTREGADO' => ['RECIBIDO'],
    'ANULADA' => [],
];

/**
 * Privilegio necesario para guardar una orden (ver 04-privilegios.sql):
 *   crear o editar en MANTENIMIENTO -> MANT_ORDEN_CREAR; pasar a/editar en RECIBIDO -> MANT_ORDEN_RECIBIR;
 *   generar el acta o reabrir (ENTREGADO <-> RECIBIDO) -> MANT_ORDEN_ACTA; anular -> MANT_ORDEN_ANULAR.
 */
function mantPermisoOrden(?string $estadoActual, string $estadoNuevo): string
{
    if ($estadoNuevo === 'ANULADA') {
        return 'MANT_ORDEN_ANULAR';
    }
    if ($estadoNuevo === 'ENTREGADO' || $estadoActual === 'ENTREGADO') {
        return 'MANT_ORDEN_ACTA';
    }
    if ($estadoNuevo === 'RECIBIDO') {
        return 'MANT_ORDEN_RECIBIR';
    }
    return 'MANT_ORDEN_CREAR';
}

/** Lanza ValidacionException si no se puede pasar de $actual a $nuevo. */
function mantValidarTransicion(string $actual, string $nuevo, object $orden): void
{
    if ($actual === $nuevo) {
        if ($actual === 'ANULADA') {
            throw new ValidacionException('Una orden anulada no se puede modificar');
        }
        return;
    }
    if (!in_array($nuevo, MANT_TRANSICIONES[$actual] ?? MANT_ESTADOS_ORDEN, true)) {
        throw new ValidacionException("No se puede pasar una orden de $actual a $nuevo");
    }
    if ($nuevo === 'ENTREGADO' && empty($orden->orden_fecha_recepcion)) {
        throw new ValidacionException('Para generar el acta (ENTREGADO) registre la fecha de entrega del acta');
    }
}

/**
 * Verifica que los valores de la orden no superen el saldo del contrato.
 * $saldoSinEstaOrden: [rubro => saldo disponible sin contar esta orden]; $totalesOrden: [rubro => total de esta orden].
 * Devuelve el mensaje de error o null.
 */
function mantExcesoContrato(array $saldoSinEstaOrden, array $totalesOrden): ?string
{
    foreach ($totalesOrden as $rubro => $total) {
        if ($total <= 0) {
            continue;
        }
        if (!array_key_exists($rubro, $saldoSinEstaOrden)) {
            return "El contrato no tiene partida para el rubro $rubro";
        }
        if (round($total, 2) > round((float) $saldoSinEstaOrden[$rubro], 2)) {
            return sprintf('El rubro %s supera el saldo del contrato: disponible $%s, registrado $%s',
                $rubro, number_format((float) $saldoSinEstaOrden[$rubro], 2), number_format($total, 2));
        }
    }
    return null;
}

/** Totales por rubro de una lista de facturas (objetos o arreglos). */
function mantTotalesRubro(array $facturas): array
{
    $totales = [];
    foreach ($facturas as $f) {
        $f = (array) $f;
        $valor = $f['factura_valor'] ?? null;
        if ($valor === null || $valor === '' || !is_numeric($valor)) {
            continue;
        }
        $totales[$f['factura_tipo']] = ($totales[$f['factura_tipo']] ?? 0) + (float) $valor;
    }
    return $totales;
}

/** Número sugerido de bitácora: {NN} correlativo del contrato, {NOMBRE} nombre corto, {CONTRATO} código. */
function mantFormatoBitacora(string $formato, int $n, ?string $nombreCorto, string $codigoContrato): string
{
    $texto = strtr($formato, ['{NN}' => str_pad((string) $n, 2, '0', STR_PAD_LEFT), '{N}' => (string) $n,
        '{NOMBRE}' => mb_strtoupper(trim((string) $nombreCorto)), '{CONTRATO}' => mb_strtoupper($codigoContrato)]);
    // sin nombre corto: "BITÁCORA 12- CB-..." -> "BITÁCORA 12 CB-..."
    $texto = preg_replace('/-\s+/', ' ', $texto);
    return trim(preg_replace('/\s{2,}/', ' ', $texto));
}

/** Número de informe de pago según el formato configurado: {SIGLAS} {AA} {AAAA} {N} {NNN} {NNNN} */
function mantFormatoInforme(string $formato, string $siglas, int $n, ?int $anio = null): string
{
    $anio = $anio ?? (int) date('Y');
    return strtr($formato, ['{SIGLAS}' => strtoupper($siglas), '{AAAA}' => (string) $anio, '{AA}' => substr((string) $anio, -2),
        '{NNNN}' => str_pad((string) $n, 4, '0', STR_PAD_LEFT), '{NNN}' => str_pad((string) $n, 3, '0', STR_PAD_LEFT), '{N}' => (string) $n]);
}
const MANT_TIPOS_ORDEN = ['CORRECTIVO', 'PREVENTIVO', 'PREVENTIVO Y CORRECTIVO'];
/** Tipos que cuentan como mantenimiento preventivo para el plan por kilometraje. */
const MANT_TIPOS_PREVENTIVOS = ['PREVENTIVO', 'PREVENTIVO Y CORRECTIVO'];

function mantEsPreventivo(?string $tipo): bool
{
    return in_array(strtoupper((string) $tipo), MANT_TIPOS_PREVENTIVOS, true);
}

/** Valida y normaliza los datos de una orden. Lanza ValidacionException con un mensaje para el usuario. */
function mantValidarOrden(object $o): void
{
    foreach (['fk_vehiculo_id' => 'vehículo', 'personal_solicita' => 'quien solicita', 'director_administrativo' => 'director administrativo',
              'tecnico_servicios' => 'técnico de servicios', 'orden_fecha_mantenimiento' => 'fecha de mantenimiento'] as $campo => $nombre) {
        if (empty($o->$campo)) {
            throw new ValidacionException("Falta el campo: $nombre");
        }
    }
    if (!isset($o->orden_km_mantenimiento) || !is_numeric($o->orden_km_mantenimiento) || $o->orden_km_mantenimiento < 0) {
        throw new ValidacionException('El kilometraje debe ser un número mayor o igual a 0');
    }
    $o->orden_tipomantenimiento = strtoupper($o->orden_tipomantenimiento ?? 'CORRECTIVO');
    if (!in_array($o->orden_tipomantenimiento, MANT_TIPOS_ORDEN, true)) {
        throw new ValidacionException('Tipo de mantenimiento inválido');
    }
    if (isset($o->orden_serie) && $o->orden_serie !== '' && $o->orden_serie !== null
        && (filter_var($o->orden_serie, FILTER_VALIDATE_INT) === false || (int) $o->orden_serie < 0)) {
        throw new ValidacionException('El número de orden debe ser un número entero');
    }
    if (isset($o->orden_estado) && !in_array($o->orden_estado, MANT_ESTADOS_ORDEN, true)) {
        throw new ValidacionException('Estado de orden inválido');
    }
    foreach (['trabajos', 'sugeridos', 'anexos'] as $lista) {
        foreach ((array) ($o->$lista ?? []) as $item) {
            $campo = $lista === 'anexos' ? 'anexo_descripcion' : 'trabajo_descripcion';
            if (trim((string) ($item->$campo ?? '')) === '') {
                throw new ValidacionException("Hay un elemento vacío en $lista");
            }
        }
    }
    foreach ((array) ($o->facturas ?? []) as $f) {
        if (trim((string) ($f->factura_tipo ?? '')) === '') {
            throw new ValidacionException('Cada valor del desglose debe tener un rubro');
        }
        if (isset($f->factura_valor) && $f->factura_valor !== '' && (!is_numeric($f->factura_valor) || $f->factura_valor < 0)) {
            throw new ValidacionException('El valor de cada rubro debe ser un número mayor o igual a 0');
        }
    }
}
