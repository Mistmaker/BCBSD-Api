<?php
/*
 * Operadores: funcionarios (operativos o administrativos) con licencia de conducir registrada en tthh.tb_conductores.
 */
require_once __DIR__ . '/api.php';

/** Cédula ecuatoriana: 10 dígitos, provincia 01-24 o 30 y dígito verificador (módulo 10). */
function operCedulaValida(string $cedula): bool
{
    if (!preg_match('/^\d{10}$/', $cedula)) {
        return false;
    }
    $provincia = (int) substr($cedula, 0, 2);
    if (!(($provincia >= 1 && $provincia <= 24) || $provincia === 30) || (int) $cedula[2] > 5) {
        return false;
    }
    $suma = 0;
    for ($i = 0; $i < 9; $i++) {
        $d = (int) $cedula[$i] * ($i % 2 === 0 ? 2 : 1);
        $suma += $d > 9 ? $d - 9 : $d;
    }
    return (10 - $suma % 10) % 10 === (int) $cedula[9];
}

/** VIGENTE | POR VENCER (dentro de $diasAviso) | VENCIDA */
function operVigencia(?string $validez, int $diasAviso, ?string $hoy = null): string
{
    $hoy ??= date('Y-m-d');
    if (!$validez || $validez < $hoy) {
        return 'VENCIDA';
    }
    return $validez <= date('Y-m-d', strtotime("$hoy +$diasAviso days")) ? 'POR VENCER' : 'VIGENTE';
}

/**
 * Operadores con su persona, puesto en funciones y licencia. Un registro por conductor (si la persona tiene varios
 * puestos se toma el EN FUNCIONES más reciente). $donde y $params filtran.
 */
function operListar(Database $db, string $donde = '', array $params = []): array
{
    $db->query("SELECT DISTINCT ON (c.conductor_id)
                       c.conductor_id, c.conductor_estado, c.fk_licencia_id, c.conductor_licencia_emision::text AS conductor_licencia_emision,
                       c.conductor_licencia_validez::text AS conductor_licencia_validez, c.conductor_registro,
                       l.licencia_tipo, l.licencia_categoria, l.licencia_descripcion,
                       p.personal_id, p.personal_estado, pe.persona_id, pe.persona_doc_identidad, pe.persona_nombres, pe.persona_apellidos,
                       pp.ppersonal_id, pp.ppersonal_estado, pu.puesto_nombre, pu.puesto_modalidad
                  FROM tthh.tb_conductores c
                  JOIN tthh.tb_personal p ON p.personal_id = c.fk_personal_id
                  JOIN resources.tb_personas pe ON pe.persona_id = p.fk_persona_id
                  LEFT JOIN resources.tb_licenciasdeconducir l ON l.licencia_id = c.fk_licencia_id
                  LEFT JOIN tthh.tb_personal_puestos pp ON pp.fk_personal_id = p.personal_id
                  LEFT JOIN tthh.tb_puestos pu ON pu.puesto_id = pp.fk_puesto_id
                 WHERE TRUE $donde
                 ORDER BY c.conductor_id, (pp.ppersonal_estado = 'EN FUNCIONES') DESC NULLS LAST, pp.ppersonal_id DESC NULLS LAST");
    foreach ($params as $k => $v) {
        $db->bind($k, $v);
    }
    $filas = $db->resultset();
    usort($filas, fn($a, $b) => [$a['persona_apellidos'], $a['persona_nombres']] <=> [$b['persona_apellidos'], $b['persona_nombres']]);
    return $filas;
}

/** Agrega vigencia y si puede conducir (activo, en funciones y licencia no vencida). */
function operCompletar(array $o, int $diasAviso, ?string $hoy = null): array
{
    $o['licencia_vigencia'] = operVigencia($o['conductor_licencia_validez'], $diasAviso, $hoy);
    $o['en_funciones'] = $o['ppersonal_estado'] === 'EN FUNCIONES';
    $o['habilitado'] = $o['conductor_estado'] === 'ACTIVO' && $o['en_funciones'] && $o['licencia_vigencia'] !== 'VENCIDA';
    $o['nombre_completo'] = trim($o['persona_apellidos'] . ' ' . $o['persona_nombres']);
    return $o;
}

/**
 * Motivo por el que un operador no puede asignarse a una orden, o null si puede.
 * Respeta el parámetro OPER_BLOQUEAR_LICENCIA_VENCIDA. Leer antes de preparar otras sentencias (comparten la conexión).
 */
function operMotivoNoHabilitado(Database $db, $conductorId): ?string
{
    if (strtoupper((string) parametro($db, 'OPER_BLOQUEAR_LICENCIA_VENCIDA', 'SI')) !== 'SI') {
        return null;
    }
    if (!$conductorId) {
        return 'Seleccione el operador';
    }
    $o = operListar($db, 'AND c.conductor_id = :id', [':id' => (int) $conductorId])[0] ?? null;
    if (!$o) {
        return 'El operador seleccionado no existe';
    }
    $o = operCompletar($o, 0);
    $nombre = $o['nombre_completo'];
    if ($o['conductor_estado'] !== 'ACTIVO') {
        return "El operador $nombre está INACTIVO";
    }
    if (!$o['en_funciones']) {
        return "El operador $nombre no está EN FUNCIONES";
    }
    if ($o['licencia_vigencia'] === 'VENCIDA') {
        return "La licencia de $nombre venció el {$o['conductor_licencia_validez']}; actualícela en Operadores antes de asignarlo";
    }
    return null;
}
