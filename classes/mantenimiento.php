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

const MANT_ESTADOS_ORDEN = ['MANTENIMIENTO', 'FINALIZADA', 'ANULADA'];
const MANT_TIPOS_ORDEN = ['CORRECTIVO', 'PREVENTIVO'];

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
            throw new ValidacionException('Cada factura debe tener un tipo');
        }
        if (isset($f->factura_valor) && $f->factura_valor !== '' && (!is_numeric($f->factura_valor) || $f->factura_valor < 0)) {
            throw new ValidacionException('El valor de la factura debe ser un número mayor o igual a 0');
        }
    }
}
