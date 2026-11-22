<?php
/*
 * Usuarios: contraseñas y validaciones comunes.
 * Las contraseñas se guardan con password_hash() (bcrypt). Las MD5 heredadas del sistema anterior se aceptan una
 * última vez y se reemplazan por password_hash en ese mismo inicio de sesión.
 */
require_once __DIR__ . '/api.php';

const USR_ESTADOS = ['ACTIVO', 'INACTIVO'];

function usrHashClave(string $clave): string
{
    return password_hash($clave, PASSWORD_DEFAULT);
}

/** Hash MD5 heredado (32 caracteres hexadecimales) */
function usrEsMd5(?string $hash): bool
{
    return is_string($hash) && preg_match('/^[a-f0-9]{32}$/i', $hash) === 1;
}

/**
 * Verifica la clave. Devuelve [válida, nuevoHash]: nuevoHash no es null cuando hay que actualizar el guardado
 * (era MD5 o el algoritmo de password_hash cambió).
 */
function usrVerificarClave(string $clave, ?string $hash): array
{
    if (!$hash || $clave === '') {
        return [false, null];
    }
    if (usrEsMd5($hash)) {
        return hash_equals(strtolower($hash), md5($clave)) ? [true, usrHashClave($clave)] : [false, null];
    }
    if (!password_verify($clave, $hash)) {
        return [false, null];
    }
    return [true, password_needs_rehash($hash, PASSWORD_DEFAULT) ? usrHashClave($clave) : null];
}

/** Mensaje de error de una clave nueva, o null si es aceptable: mínimo 8 caracteres, con letras y números. */
function usrErrorClave(?string $clave, string $login = ''): ?string
{
    $clave = (string) $clave;
    if (mb_strlen($clave) < 8) {
        return 'La clave debe tener al menos 8 caracteres';
    }
    if (!preg_match('/[A-Za-zÁÉÍÓÚáéíóúÑñ]/u', $clave) || !preg_match('/\d/', $clave)) {
        return 'La clave debe combinar letras y números';
    }
    if ($login !== '' && mb_strtolower($clave) === mb_strtolower($login)) {
        return 'La clave no puede ser igual al usuario';
    }
    return null;
}

/** Login: 3 a 40 caracteres, letras, números, punto, guion o guion bajo; se guarda en minúsculas. */
function usrNormalizarLogin(?string $login): string
{
    $login = mb_strtolower(trim((string) $login));
    if (!preg_match('/^[a-z0-9._-]{3,40}$/', $login)) {
        throw new ValidacionException('El usuario debe tener de 3 a 40 caracteres: letras sin tildes, números, punto, guion o guion bajo');
    }
    return $login;
}

/**
 * Usuarios con los datos de su persona, perfil y si es funcionario (puesto EN FUNCIONES). NUNCA incluye la clave.
 * $donde / $params filtran (alias: u usuario, pe persona, pf perfil).
 */
function usrListar(Database $db, string $donde = '', array $params = []): array
{
    $db->query("SELECT u.usuario_id, u.usuario_login, COALESCE(u.usuario_estado, 'ACTIVO') AS usuario_estado, u.usuario_tipo,
                       u.usuario_cambiar_pass, u.usuario_registro, u.usuario_ultimo_acceso, u.fk_perfil_id, pf.perfil_nombre,
                       COALESCE(pf.perfil_estado, 'ACTIVO') AS perfil_estado,
                       pe.persona_id, pe.persona_tipo_doc, pe.persona_doc_identidad, pe.persona_nombres, pe.persona_apellidos,
                       pe.persona_correo, pe.persona_celular, pe.persona_telefono,
                       f.ppersonal_id, f.puesto_nombre, f.puesto_modalidad, (f.ppersonal_id IS NOT NULL) AS es_funcionario,
                       (SELECT count(*) FROM admin.tb_usuario_rol ur WHERE ur.fk_usuario_id = u.usuario_id)::int AS privilegios_adicionales
                  FROM admin.tb_usuarios u
                  LEFT JOIN resources.tb_personas pe ON pe.persona_id = u.fk_persona_id
                  LEFT JOIN admin.tb_perfiles pf ON pf.perfil_id = u.fk_perfil_id
                  LEFT JOIN LATERAL (
                      SELECT pp.ppersonal_id, pu.puesto_nombre, pu.puesto_modalidad
                        FROM tthh.tb_personal p JOIN tthh.tb_personal_puestos pp ON pp.fk_personal_id = p.personal_id
                        LEFT JOIN tthh.tb_puestos pu ON pu.puesto_id = pp.fk_puesto_id
                       WHERE p.fk_persona_id = u.fk_persona_id AND pp.ppersonal_estado = 'EN FUNCIONES'
                       ORDER BY pp.ppersonal_id DESC LIMIT 1) f ON TRUE
                 WHERE TRUE $donde
                 ORDER BY pe.persona_apellidos NULLS LAST, pe.persona_nombres, u.usuario_login");
    foreach ($params as $k => $v) {
        $db->bind($k, $v);
    }
    return $db->resultset();
}

/**
 * Árbol módulo -> submódulo -> privilegios. tipo: ACCESO (pantalla, con ruta) | ACCION (sin ruta).
 * $asignados: rol_id marcados (asignado = true). $delPerfil: rol_id que vienen del perfil del usuario (del_perfil = true).
 */
function usrArbolPrivilegios(Database $db, array $asignados = [], array $delPerfil = []): array
{
    $db->query("SELECT m.modulo_id, m.modulo_nombre, s.submodulo_id, s.submodulo_nombre, r.rol_id, r.rol_nombre, r.rol_descripcion,
                       r.rol_path, r.rol_codigo
                  FROM admin.tb_roles r JOIN admin.tb_submodulos s ON s.submodulo_id = r.fk_submodulo_id
                  JOIN admin.tb_modulos m ON m.modulo_id = s.fk_modulo_id
                 ORDER BY m.modulo_nombre, s.submodulo_nombre, (r.rol_path IS NULL), r.rol_nombre");
    $asignados = array_flip(array_map('intval', $asignados));
    $delPerfil = array_flip(array_map('intval', $delPerfil));
    $modulos = [];
    foreach ($db->resultset() as $f) {
        $m = (int) $f['modulo_id'];
        $s = (int) $f['submodulo_id'];
        $modulos[$m] ??= ['modulo_id' => $m, 'modulo_nombre' => $f['modulo_nombre'], 'submodulos' => []];
        $modulos[$m]['submodulos'][$s] ??= ['submodulo_id' => $s, 'submodulo_nombre' => $f['submodulo_nombre'], 'roles' => []];
        $id = (int) $f['rol_id'];
        $modulos[$m]['submodulos'][$s]['roles'][] = [
            'rol_id' => $id, 'rol_nombre' => $f['rol_nombre'], 'rol_descripcion' => $f['rol_descripcion'], 'rol_path' => $f['rol_path'],
            'rol_codigo' => $f['rol_codigo'], 'tipo' => $f['rol_path'] ? 'ACCESO' : 'ACCION',
            'asignado' => isset($asignados[$id]), 'del_perfil' => isset($delPerfil[$id]),
        ];
    }
    foreach ($modulos as &$m) {
        $m['submodulos'] = array_values($m['submodulos']);
    }
    return array_values($modulos);
}

/** rol_id existentes de una lista (descarta los inexistentes) */
function usrRolesValidos(Database $db, array $roles): array
{
    $roles = array_values(array_unique(array_filter(array_map('intval', $roles), fn($r) => $r > 0)));
    if (!$roles) {
        return [];
    }
    $db->query('SELECT rol_id FROM admin.tb_roles WHERE rol_id = ANY(CAST(:r AS int[]))');
    $db->bind(':r', '{' . implode(',', $roles) . '}');
    return array_map('intval', array_column($db->resultset(), 'rol_id'));
}

/**
 * Evita que un administrador se quite a sí mismo el acceso: tras el cambio (dentro de la transacción) debe conservar
 * $codigo. Si no, lanza ValidacionException (el llamador hace rollback).
 */
function usrNoBloquearse(Database $db, int $usuarioActual, string $codigo, string $mensaje): void
{
    if (!in_array($codigo, permisosUsuario($db, $usuarioActual), true)) {
        throw new ValidacionException($mensaje);
    }
}
