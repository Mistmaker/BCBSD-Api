<?php
require_once __DIR__ . '/../../classes/auth.php';
$auth = requireAuth();
require_once __DIR__ . '/../../classes/usuarios.php';
require_once __DIR__ . '/../../classes/operadores.php'; // operCedulaValida
// POST -> crea un usuario: { persona_tipo_doc (CEDULA|PASAPORTE), persona_doc_identidad, persona_nombres, persona_apellidos,
//          persona_correo, persona_celular, usuario_login, clave, fk_perfil_id, usuario_estado }
//   La persona puede ser funcionario o externa (p. ej. delegada de otra institución). Si el documento ya existe se reutiliza
//   la persona; si ya tiene usuario -> 409 con su id. La clave se guarda con password_hash y se pide cambiarla al entrar.
// PUT  -> edita: { usuario_id, usuario_login, fk_perfil_id, usuario_estado, persona_correo, persona_celular,
//          persona_nombres, persona_apellidos (solo si no es funcionario: esos datos los mantiene Talento Humano) }
// Privilegio: SIS_USUARIO_GESTIONAR. Nadie puede inactivarse ni quitarse a sí mismo la administración de usuarios.
$metodo = apiMetodo(['POST', 'PUT']);
$u = apiCuerpoJson();
$db = null;
try {
    $actual = authUsuarioId();
    if ($actual === null) {
        jsonResponse(['error' => 'No autorizado'], 403);
    }
    $texto = fn($v) => trim(preg_replace('/\s+/', ' ', (string) $v));
    $mayus = fn($v) => mb_strtoupper($texto($v));
    $login = usrNormalizarLogin(prop($u, 'usuario_login'));
    $estado = strtoupper((string) prop($u, 'usuario_estado', 'ACTIVO'));
    if (!in_array($estado, USR_ESTADOS, true)) {
        throw new ValidacionException('Estado inválido');
    }
    $correo = $texto(prop($u, 'persona_correo', ''));
    if ($correo !== '' && !filter_var($correo, FILTER_VALIDATE_EMAIL)) {
        throw new ValidacionException('El correo no es válido');
    }
    $celular = preg_replace('/\D/', '', (string) prop($u, 'persona_celular', ''));
    if ($celular !== '' && !preg_match('/^\d{7,15}$/', $celular)) {
        throw new ValidacionException('El celular debe tener entre 7 y 15 dígitos');
    }
    $perfilId = (int) prop($u, 'fk_perfil_id', 0);

    $db = new Database();
    requirePermiso($db, 'SIS_USUARIO_GESTIONAR');
    $db->beginTransaction();
    $db->query("SELECT perfil_id, COALESCE(perfil_estado, 'ACTIVO') AS estado FROM admin.tb_perfiles WHERE perfil_id = :p");
    $db->bind(':p', $perfilId);
    $perfil = $db->single();
    if (!$perfil) {
        throw new ValidacionException('Seleccione el perfil');
    }
    $db->query('SELECT usuario_id FROM admin.tb_usuarios WHERE lower(usuario_login) = :l AND usuario_id <> :id LIMIT 1');
    $db->bind(':l', $login);
    $db->bind(':id', (int) prop($u, 'usuario_id', 0));
    if ($db->single()) {
        throw new ValidacionException("El usuario \"$login\" ya existe; elija otro");
    }

    if ($metodo === 'PUT') {
        $id = (int) prop($u, 'usuario_id', 0);
        $existente = usrListar($db, 'AND u.usuario_id = :id', [':id' => $id])[0] ?? null;
        if (!$existente) {
            $db->cancelTransaction();
            jsonResponse(['error' => 'Usuario no encontrado'], 404);
        }
        if ($id === $actual && $estado !== 'ACTIVO') {
            throw new ValidacionException('No puede inactivar su propio usuario');
        }
        if ((int) $existente['fk_perfil_id'] !== $perfilId && $perfil['estado'] !== 'ACTIVO') {
            throw new ValidacionException('El perfil seleccionado está inactivo');
        }
        $db->query('UPDATE admin.tb_usuarios SET usuario_login = :l, fk_perfil_id = :p, usuario_estado = :e WHERE usuario_id = :id');
        $db->bind(':l', $login);
        $db->bind(':p', $perfilId);
        $db->bind(':e', $estado);
        $db->bind(':id', $id);
        $db->execute();
        // Datos de contacto; nombres solo de personas que no son funcionarios
        $sets = ['persona_correo = :c', 'persona_celular = :cel'];
        if (!$existente['es_funcionario'] && $texto(prop($u, 'persona_nombres', '')) !== '' && $texto(prop($u, 'persona_apellidos', '')) !== '') {
            $sets[] = 'persona_nombres = :n';
            $sets[] = 'persona_apellidos = :a';
        }
        $db->query('UPDATE resources.tb_personas SET ' . implode(', ', $sets) . ' WHERE persona_id = :pid');
        $db->bind(':c', $correo ?: null);
        $db->bind(':cel', $celular ?: null);
        if (count($sets) > 2) {
            $db->bind(':n', $mayus(prop($u, 'persona_nombres')));
            $db->bind(':a', $mayus(prop($u, 'persona_apellidos')));
        }
        $db->bind(':pid', (int) $existente['persona_id']);
        $db->execute();
        if ($id === $actual) {
            usrNoBloquearse($db, $actual, 'SIS_USUARIO_GESTIONAR', 'Con ese perfil perdería la administración de usuarios; pida a otro administrador que haga el cambio');
        }
        $db->endTransaction();
        jsonResponse(['msg' => 'Usuario actualizado', 'id' => $id]);
    }

    // POST: persona (existente o nueva) y usuario
    if ($perfil['estado'] !== 'ACTIVO') {
        throw new ValidacionException('El perfil seleccionado está inactivo');
    }
    $tipoDoc = strtoupper((string) prop($u, 'persona_tipo_doc', 'CEDULA'));
    $doc = strtoupper($texto(prop($u, 'persona_doc_identidad', '')));
    if ($tipoDoc === 'CEDULA' && !operCedulaValida($doc)) {
        throw new ValidacionException('La cédula no es válida');
    }
    if ($tipoDoc === 'PASAPORTE' && !preg_match('/^[A-Z0-9]{5,20}$/', $doc)) {
        throw new ValidacionException('El pasaporte debe tener de 5 a 20 letras o números');
    }
    if (!in_array($tipoDoc, ['CEDULA', 'PASAPORTE'], true)) {
        throw new ValidacionException('Tipo de documento inválido');
    }
    $clave = (string) prop($u, 'clave', '');
    if ($error = usrErrorClave($clave, $login)) {
        throw new ValidacionException($error);
    }

    $db->query('SELECT pg_advisory_xact_lock(hashtext(:d))');
    $db->bind(':d', 'usuario-' . $doc);
    $db->execute();
    $db->query('SELECT persona_id FROM resources.tb_personas WHERE persona_doc_identidad = :d ORDER BY persona_id LIMIT 1');
    $db->bind(':d', $doc);
    $personaId = $db->single()['persona_id'] ?? null;
    if ($personaId) {
        $db->query('SELECT usuario_id FROM admin.tb_usuarios WHERE fk_persona_id = :p ORDER BY usuario_id LIMIT 1');
        $db->bind(':p', $personaId);
        if ($ya = $db->single()) {
            $db->cancelTransaction();
            jsonResponse(['error' => 'Ya tiene usuario', 'msg' => 'Esta persona ya tiene un usuario; edítelo', 'id' => (int) $ya['usuario_id']], 409);
        }
        // completa los datos de contacto que falten
        $db->query('UPDATE resources.tb_personas SET persona_correo = COALESCE(NULLIF(persona_correo, \'\'), :c), persona_celular = COALESCE(NULLIF(persona_celular, \'\'), :cel)
                     WHERE persona_id = :p');
        $db->bind(':c', $correo ?: null);
        $db->bind(':cel', $celular ?: null);
        $db->bind(':p', $personaId);
        $db->execute();
    } else {
        $nombres = $mayus(prop($u, 'persona_nombres', ''));
        $apellidos = $mayus(prop($u, 'persona_apellidos', ''));
        if ($nombres === '' || $apellidos === '') {
            throw new ValidacionException('Ingrese nombres y apellidos');
        }
        $db->query('INSERT INTO resources.tb_personas (persona_tipo_doc, persona_doc_identidad, persona_nombres, persona_apellidos, persona_correo, persona_celular, fk_usuario_id)
                     VALUES (:t, :d, :n, :a, :c, :cel, :u) RETURNING persona_id');
        $db->bind(':t', $tipoDoc);
        $db->bind(':d', $doc);
        $db->bind(':n', $nombres);
        $db->bind(':a', $apellidos);
        $db->bind(':c', $correo ?: null);
        $db->bind(':cel', $celular ?: null);
        $db->bind(':u', $actual);
        $personaId = $db->single()['persona_id'];
    }
    $db->query('INSERT INTO admin.tb_usuarios (fk_persona_id, fk_perfil_id, usuario_login, usuario_pass, usuario_estado, usuario_cambiar_pass, fk_usuario_id)
                 VALUES (:p, :pf, :l, :h, :e, TRUE, :u) RETURNING usuario_id');
    $db->bind(':p', $personaId);
    $db->bind(':pf', $perfilId);
    $db->bind(':l', $login);
    $db->bind(':h', usrHashClave($clave));
    $db->bind(':e', $estado);
    $db->bind(':u', $actual);
    $id = (int) $db->single()['usuario_id'];
    $db->endTransaction();
    jsonResponse(['msg' => 'Usuario creado', 'id' => $id], 201);
} catch (Throwable $e) {
    $db?->cancelTransaction();
    apiError($e, 'Error al guardar el usuario');
}
