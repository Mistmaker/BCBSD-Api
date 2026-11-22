<?php
require_once __DIR__ . '/../../../classes/auth.php';
$auth = requireAuth();
require_once __DIR__ . '/../../../classes/operadores.php';
require_once __DIR__ . '/../../../classes/documentos.php';
// Formato: multipart/form-data con 'datos' (JSON) y 'licencia_pdf' (PDF escaneado de la licencia), o JSON sin archivo.
// El PDF se guarda en documentos/licencias/LIC-{CATEGORÍA}-{CÉDULA}.pdf; el anterior pasa a documentos/historico/licencias/.
// Es obligatorio (parámetro OPER_EXIGIR_PDF_LICENCIA) al registrar y al cambiar tipo, emisión o validez de la licencia.
// POST -> ingreso rápido de un operador:
//   { persona_doc_identidad, persona_nombres, persona_apellidos, fk_licencia_id, conductor_licencia_emision, conductor_licencia_validez,
//     fk_puesto_id (solo si la persona aún no tiene un puesto EN FUNCIONES) }
//   Si la cédula ya existe se reutiliza la persona (sus datos los mantiene Talento Humano); si ya es operador -> 409.
// PUT o POST con conductor_id -> actualiza solo la licencia: { conductor_id, fk_licencia_id, conductor_licencia_emision,
//      conductor_licencia_validez, conductor_estado } (+ licencia_pdf). Con archivo debe ser POST (PHP no procesa archivos en PUT).
$metodo = apiMetodo(['POST', 'PUT']);
$multipart = str_starts_with(strtolower($_SERVER['CONTENT_TYPE'] ?? ''), 'multipart/form-data');
if ($multipart) {
    $o = json_decode($_POST['datos'] ?? '');
    if (!is_object($o)) {
        jsonResponse(['error' => 'Datos inválidos', 'msg' => 'Falta el campo datos (JSON)'], 400);
    }
} else {
    $o = apiCuerpoJson();
}
$archivo = $_FILES['licencia_pdf'] ?? null;
$hayArchivo = $archivo && ($archivo['error'] ?? UPLOAD_ERR_NO_FILE) !== UPLOAD_ERR_NO_FILE;
$esEdicion = $metodo === 'PUT' || prop($o, 'conductor_id');
$db = null;
$guardado = null;
try {
    $usuario = authUsuarioId();
    if ($usuario === null) {
        jsonResponse(['error' => 'No autorizado', 'msg' => 'Solo usuarios administrativos pueden registrar operadores'], 403);
    }
    // Licencia (común a ambos métodos)
    $emision = (string) prop($o, 'conductor_licencia_emision', '');
    $validez = (string) prop($o, 'conductor_licencia_validez', '');
    $fecha = fn($f) => preg_match('/^\d{4}-\d{2}-\d{2}$/', $f) && strtotime($f) !== false;
    if (!prop($o, 'fk_licencia_id')) {
        throw new ValidacionException('Seleccione el tipo de licencia');
    }
    if (!$fecha($emision) || !$fecha($validez)) {
        throw new ValidacionException('Ingrese las fechas de emisión y de validez de la licencia');
    }
    if ($validez <= $emision) {
        throw new ValidacionException('La fecha de validez debe ser posterior a la de emisión');
    }
    if ($emision > date('Y-m-d')) {
        throw new ValidacionException('La fecha de emisión no puede ser futura');
    }
    $estado = strtoupper((string) prop($o, 'conductor_estado', 'ACTIVO'));
    if (!in_array($estado, ['ACTIVO', 'INACTIVO'], true)) {
        throw new ValidacionException('Estado inválido');
    }

    $db = new Database();
    requirePermiso($db, 'ADM_OPERADOR_GESTIONAR');
    // Parámetros antes de preparar otras sentencias (comparten la conexión)
    $exigirPdf = strtoupper((string) parametro($db, 'OPER_EXIGIR_PDF_LICENCIA', 'SI')) === 'SI';
    $maxMb = (int) parametro($db, 'OPER_PDF_MAX_MB', 5);
    if ($hayArchivo) {
        docValidarPdf($archivo, $maxMb);
    }
    $db->query("SELECT licencia_categoria FROM resources.tb_licenciasdeconducir WHERE licencia_id = :l");
    $db->bind(':l', (int) $o->fk_licencia_id);
    $categoria = $db->single()['licencia_categoria'] ?? null;
    if ($categoria === null) {
        throw new ValidacionException('El tipo de licencia no existe');
    }

    if ($esEdicion) {
        $id = (int) prop($o, 'conductor_id', 0);
        $db->beginTransaction();
        $db->query("SELECT c.fk_licencia_id, c.conductor_licencia_emision::text AS emision, c.conductor_licencia_validez::text AS validez, c.conductor_pdf,
                           pe.persona_doc_identidad
                      FROM tthh.tb_conductores c JOIN tthh.tb_personal p ON p.personal_id = c.fk_personal_id
                      JOIN resources.tb_personas pe ON pe.persona_id = p.fk_persona_id
                     WHERE c.conductor_id = :id FOR UPDATE OF c");
        $db->bind(':id', $id);
        $actual = $db->single();
        if (!$actual) {
            $db->cancelTransaction();
            jsonResponse(['error' => 'Operador no encontrado'], 404);
        }
        $cambiaLicencia = (int) $actual['fk_licencia_id'] !== (int) $o->fk_licencia_id || $actual['emision'] !== $emision || $actual['validez'] !== $validez;
        if ($exigirPdf && $cambiaLicencia && !$hayArchivo) {
            throw new ValidacionException('Adjunte el PDF de la licencia actualizada');
        }
        $pdf = $actual['conductor_pdf'];
        if ($hayArchivo) {
            $guardado = docGuardar($archivo['tmp_name'], 'licencias', docNombre('licencias', [$categoria, $actual['persona_doc_identidad']]), $pdf);
            $pdf = $guardado;
        }
        $db->query('UPDATE tthh.tb_conductores SET fk_licencia_id = :l, conductor_licencia_emision = :e, conductor_licencia_validez = :v, conductor_estado = :s,
                           conductor_pdf = :pdf
                     WHERE conductor_id = :id RETURNING conductor_id');
        $db->bind(':l', (int) $o->fk_licencia_id);
        $db->bind(':e', $emision);
        $db->bind(':v', $validez);
        $db->bind(':s', $estado);
        $db->bind(':pdf', $pdf);
        $db->bind(':id', $id);
        $db->single();
        $db->endTransaction();
        jsonResponse(['msg' => 'Licencia actualizada', 'id' => $id, 'conductor_pdf' => $pdf]);
    }


    // POST: persona -> personal -> puesto -> conductor
    $cedula = trim((string) prop($o, 'persona_doc_identidad', ''));
    $nombres = mb_strtoupper(trim(preg_replace('/\s+/', ' ', (string) prop($o, 'persona_nombres', ''))));
    $apellidos = mb_strtoupper(trim(preg_replace('/\s+/', ' ', (string) prop($o, 'persona_apellidos', ''))));
    if (!operCedulaValida($cedula)) {
        throw new ValidacionException('La cédula no es válida');
    }
    if ($exigirPdf && !$hayArchivo) {
        throw new ValidacionException('Adjunte el PDF escaneado de la licencia');
    }
    $db->beginTransaction();
    $db->query('SELECT pg_advisory_xact_lock(hashtext(:c))');
    $db->bind(':c', 'operador-' . $cedula);
    $db->execute();

    $db->query('SELECT persona_id FROM resources.tb_personas WHERE persona_doc_identidad = :c ORDER BY persona_id LIMIT 1');
    $db->bind(':c', $cedula);
    $personaId = $db->single()['persona_id'] ?? null;
    if (!$personaId) {
        if ($nombres === '' || $apellidos === '') {
            throw new ValidacionException('Ingrese nombres y apellidos');
        }
        $db->query("INSERT INTO resources.tb_personas (persona_tipo_doc, persona_doc_identidad, persona_nombres, persona_apellidos, fk_usuario_id)
                     VALUES ('CEDULA', :c, :n, :a, :u) RETURNING persona_id");
        $db->bind(':c', $cedula);
        $db->bind(':n', $nombres);
        $db->bind(':a', $apellidos);
        $db->bind(':u', $usuario);
        $personaId = $db->single()['persona_id'];
    }

    $db->query('SELECT personal_id FROM tthh.tb_personal WHERE fk_persona_id = :p ORDER BY personal_id DESC LIMIT 1');
    $db->bind(':p', $personaId);
    $personalId = $db->single()['personal_id'] ?? null;
    if (!$personalId) {
        $db->query("INSERT INTO tthh.tb_personal (fk_persona_id, fk_usuario_id) VALUES (:p, :u) RETURNING personal_id");
        $db->bind(':p', $personaId);
        $db->bind(':u', $usuario);
        $personalId = $db->single()['personal_id'];
    }

    $db->query('SELECT conductor_id FROM tthh.tb_conductores WHERE fk_personal_id = :p ORDER BY conductor_id DESC LIMIT 1');
    $db->bind(':p', $personalId);
    if ($existente = $db->single()) {
        $db->cancelTransaction();
        jsonResponse(['error' => 'Ya registrado', 'msg' => 'Esta persona ya es operador; actualice su licencia', 'id' => (int) $existente['conductor_id']], 409);
    }

    $db->query("SELECT 1 FROM tthh.tb_personal_puestos WHERE fk_personal_id = :p AND ppersonal_estado = 'EN FUNCIONES' LIMIT 1");
    $db->bind(':p', $personalId);
    if (!$db->single()) {
        if (!prop($o, 'fk_puesto_id')) {
            throw new ValidacionException('La persona no tiene un puesto EN FUNCIONES: seleccione su puesto');
        }
        $db->query("INSERT INTO tthh.tb_personal_puestos (fk_personal_id, fk_puesto_id, fk_usuario_id, personal_fecha_registro)
                     SELECT :p, puesto_id, :u, CURRENT_DATE FROM tthh.tb_puestos WHERE puesto_id = :pu RETURNING ppersonal_id");
        $db->bind(':p', $personalId);
        $db->bind(':u', $usuario);
        $db->bind(':pu', (int) $o->fk_puesto_id);
        if (!$db->single()) {
            throw new ValidacionException('El puesto seleccionado no existe');
        }
    }

    $db->query("INSERT INTO tthh.tb_conductores (fk_personal_id, fk_licencia_id, conductor_licencia_emision, conductor_licencia_validez, conductor_estado, fk_usuario_id)
                 VALUES (:p, :l, :e, :v, :s, :u) RETURNING conductor_id");
    $db->bind(':p', $personalId);
    $db->bind(':l', (int) $o->fk_licencia_id);
    $db->bind(':e', $emision);
    $db->bind(':v', $validez);
    $db->bind(':s', $estado);
    $db->bind(':u', $usuario);
    $id = (int) $db->single()['conductor_id'];
    if ($hayArchivo) {
        $guardado = docGuardar($archivo['tmp_name'], 'licencias', docNombre('licencias', [$categoria, $cedula]));
        $db->query('UPDATE tthh.tb_conductores SET conductor_pdf = :pdf WHERE conductor_id = :id');
        $db->bind(':pdf', $guardado);
        $db->bind(':id', $id);
        $db->execute();
    }
    $db->endTransaction();
    jsonResponse(['msg' => 'Operador registrado', 'id' => $id, 'conductor_pdf' => $guardado], 201);
} catch (Throwable $e) {
    $db?->cancelTransaction();
    // Si el archivo se guardó pero el registro no, no dejarlo huérfano
    if ($guardado && docExiste($guardado)) {
        @unlink(docRutaAbsoluta($guardado));
    }
    apiError($e, 'Error al guardar el operador');
}
