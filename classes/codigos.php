<?php
/*
 * Códigos de órdenes con secuencia anual: {SIGLAS}{AA}{TIPO}{ORIGEN}{NNNNN}, p. ej. CBSD26MOVDA00012.
 * - SIGLAS: admin.tb_sistema.sistema_siglas (parametrizable por institución).
 * - La secuencia (NNNNN) es por año, tipo y origen y reinicia cada año.
 * - Se busca SIN importar el prefijo: si cambian las siglas a mitad de año, la numeración continúa.
 * - Llamar dentro de la transacción que inserta: el bloqueo evita números repetidos con dos usuarios a la vez y las
 *   filas insertadas en la misma transacción ya cuentan (varios vales seguidos).
 * Órdenes de mantenimiento, informes y peticiones de materiales usan mantCodigo() con la misma regla.
 */
require_once __DIR__ . '/api.php';

/** Siglas para los códigos: solo letras y números, en mayúsculas */
function codSiglas(Database $db): string
{
    $siglas = strtoupper(preg_replace('/[^A-Za-z0-9]/', '', (string) (institucion($db)['sistema_siglas'] ?? '')));
    return $siglas !== '' ? $siglas : 'CBSD';
}

/** Expresión regular (PostgreSQL) de los códigos de un año, tipo y origen con cualquier prefijo */
function codPatron(int $anio, string $tipo, string $origen): string
{
    $escapar = fn(string $s) => preg_replace('/[.^$*+?()\[\]{}|\\\\]/', '\\\\$0', $s);
    return '^[A-Z0-9]*' . substr((string) $anio, -2) . $escapar($tipo) . $escapar($origen) . '[0-9]{5}$';
}

/**
 * Siguiente código para tablas de órdenes con orden_codigo, orden_codigo_serie, orden_serie, orden_registro y orden_estado
 * (logistica.tb_ordenesmovilizacion, logistica.tb_ordenesabastecimiento).
 * Devuelve ['code' => código, 'orden_codigo_serie' => secuencia del código, 'serie' => número de orden sin contar anuladas].
 */
function codSiguienteOrden(Database $db, string $tabla, string $tipo, string $origen = '', ?int $anio = null): array
{
    if (!in_array($tabla, ['logistica.tb_ordenesmovilizacion', 'logistica.tb_ordenesabastecimiento'], true)) {
        throw new InvalidArgumentException("Tabla sin numeración anual: $tabla");
    }
    $anio ??= (int) date('Y');
    $siglas = codSiglas($db);
    $db->query('SELECT pg_advisory_xact_lock(hashtext(:k))');
    $db->bind(':k', "$tabla.codigo");
    $db->execute();
    $db->query("SELECT COALESCE(MAX(orden_codigo_serie), 0) AS codigo,
                       COALESCE(MAX(orden_serie) FILTER (WHERE orden_estado IS DISTINCT FROM 'ORDEN ANULADA'), 0) AS serie
                  FROM $tabla
                 WHERE date_part('year', orden_registro) = :anio AND orden_codigo ~ :patron");
    $db->bind(':anio', $anio);
    $db->bind(':patron', codPatron($anio, $tipo, $origen));
    $fila = $db->single();
    $secuencia = (int) $fila['codigo'] + 1;
    return [
        'code' => $siglas . substr((string) $anio, -2) . $tipo . $origen . str_pad((string) $secuencia, 5, '0', STR_PAD_LEFT),
        'orden_codigo_serie' => $secuencia,
        'serie' => (int) $fila['serie'] + 1,
    ];
}
