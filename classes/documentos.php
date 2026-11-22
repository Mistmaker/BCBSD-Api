<?php
/*
 * Documentos subidos (PDF): validación, guardado con nombre normalizado, histórico y descarga.
 * Carpeta base: DOCS_DIR (classes/dbconfig.php). Estructura y nombres: documentos/LEEME.md.
 */
require_once __DIR__ . '/api.php';

/** Tipos de documento: carpeta => prefijo del nombre */
const DOC_TIPOS = [
    'licencias' => 'LIC',
    'cedulas' => 'CED',
    'cursos' => 'CUR',
    'capacitaciones' => 'CAP',
    'reconocimientos' => 'REC',
    'cargas-familiares' => 'CFA',
];

/** 'LIC' + ['C1', '1712345675'] -> 'LIC-C1-1712345675.pdf' (solo letras, números y guiones) */
function docNombre(string $tipo, array $partes): string
{
    if (!isset(DOC_TIPOS[$tipo])) {
        throw new InvalidArgumentException("Tipo de documento desconocido: $tipo");
    }
    $limpias = array_map(fn($p) => trim(preg_replace('/[^A-Z0-9]+/', '-', strtoupper(strtr((string) $p, ['Ñ' => 'N', 'ñ' => 'n']))), '-'), $partes);
    $limpias = array_filter($limpias, fn($p) => $p !== '');
    return DOC_TIPOS[$tipo] . ($limpias ? '-' . implode('-', $limpias) : '') . '.pdf';
}

/** Ruta relativa válida: 'licencias/LIC-C-1712345675.pdf' (sin '..' ni subcarpetas extra) */
function docRutaValida(?string $relativa): bool
{
    if (!$relativa || !preg_match('#^([a-z-]+)/(historico/)?[A-Za-z0-9._-]+\.pdf$#', $relativa, $m)) {
        return false;
    }
    return isset(DOC_TIPOS[$m[1]]) && !str_contains($relativa, '..');
}

function docRutaAbsoluta(string $relativa): string
{
    return rtrim(DOCS_DIR, '/') . '/' . $relativa;
}

/** El documento guardado existe en disco */
function docExiste(?string $relativa): bool
{
    return docRutaValida($relativa) && is_file(docRutaAbsoluta($relativa));
}

/**
 * Valida un PDF recibido en $_FILES. Lanza ValidacionException con un mensaje para el usuario.
 * @param array|null $archivo elemento de $_FILES
 */
function docValidarPdf(?array $archivo, int $maxMb): void
{
    if (!$archivo || ($archivo['error'] ?? UPLOAD_ERR_NO_FILE) === UPLOAD_ERR_NO_FILE) {
        throw new ValidacionException('Adjunte el archivo PDF');
    }
    $error = $archivo['error'] ?? UPLOAD_ERR_OK;
    if ($error === UPLOAD_ERR_INI_SIZE || $error === UPLOAD_ERR_FORM_SIZE) {
        throw new ValidacionException("El archivo supera el tamaño permitido por el servidor (" . ini_get('upload_max_filesize') . ")");
    }
    if ($error !== UPLOAD_ERR_OK) {
        throw new ValidacionException('No se pudo recibir el archivo (código ' . $error . '); intente de nuevo');
    }
    if (($archivo['size'] ?? 0) > $maxMb * 1024 * 1024) {
        throw new ValidacionException("El archivo supera $maxMb MB");
    }
    if (($archivo['size'] ?? 0) < 100) {
        throw new ValidacionException('El archivo está vacío o dañado');
    }
    $tmp = $archivo['tmp_name'] ?? '';
    $inicio = is_file($tmp) ? (string) file_get_contents($tmp, false, null, 0, 5) : '';
    $mime = is_file($tmp) && function_exists('finfo_open') ? finfo_file(finfo_open(FILEINFO_MIME_TYPE), $tmp) : 'application/pdf';
    if ($inicio !== '%PDF-' || $mime !== 'application/pdf') {
        throw new ValidacionException('El archivo debe ser un PDF');
    }
}

/**
 * Guarda el archivo temporal como $tipo/$nombre. Si ya existe un archivo con ese nombre, o $anterior (la ruta que
 * tenía el registro, p. ej. con otra categoría de licencia), se mueve a historico/$tipo/ con fecha y hora.
 * Devuelve la ruta relativa guardada. $mover permite pruebas sin una subida HTTP real.
 */
function docGuardar(string $tmp, string $tipo, string $nombre, ?string $anterior = null, ?callable $mover = null): string
{
    $mover ??= 'move_uploaded_file';
    $relativa = "$tipo/$nombre";
    if (!docRutaValida($relativa)) {
        throw new InvalidArgumentException("Ruta de documento inválida: $relativa");
    }
    $carpeta = docRutaAbsoluta($tipo);
    $historico = docRutaAbsoluta("historico/$tipo");
    foreach ([$carpeta, $historico] as $dir) {
        if (!is_dir($dir) && !@mkdir($dir, 0750, true) && !is_dir($dir)) {
            throw new RuntimeException("No se pudo crear la carpeta de documentos $dir");
        }
    }
    $sello = date('Ymd-His');
    foreach (array_unique(array_filter([$relativa, $anterior])) as $previo) {
        if (docExiste($previo) && !str_contains($previo, 'historico/')) {
            $base = pathinfo($previo, PATHINFO_FILENAME);
            $destino = "$historico/{$base}_$sello.pdf";
            for ($n = 2; file_exists($destino); $n++) {
                $destino = "$historico/{$base}_$sello-$n.pdf";
            }
            rename(docRutaAbsoluta($previo), $destino);
        }
    }
    if (!$mover($tmp, docRutaAbsoluta($relativa))) {
        throw new RuntimeException('No se pudo guardar el archivo en ' . docRutaAbsoluta($relativa) . ' (revise los permisos de la carpeta)');
    }
    @chmod(docRutaAbsoluta($relativa), 0640);
    return $relativa;
}

/** Tamaño máximo de subida que admite PHP (upload_max_filesize y post_max_size), en MB. */
function docLimiteSubidaMb(): int
{
    $mb = function (string $v): float {
        $v = trim($v);
        $n = (float) $v;
        return match (strtoupper(substr($v, -1))) { 'G' => $n * 1024, 'K' => $n / 1024, 'M' => $n, default => $n / 1048576 };
    };
    $limites = array_filter([$mb((string) ini_get('upload_max_filesize')), $mb((string) ini_get('post_max_size'))], fn($x) => $x > 0);
    return $limites ? max(1, (int) floor(min($limites))) : 2;
}

/** Envía un PDF guardado al navegador (inline) y termina. */
function docEnviarPdf(string $relativa, string $nombreDescarga): void
{
    if (!docExiste($relativa)) {
        jsonResponse(['error' => 'Documento no disponible', 'msg' => 'El archivo no se encuentra en el servidor'], 404);
    }
    $ruta = docRutaAbsoluta($relativa);
    header('Content-Type: application/pdf');
    header('Content-Length: ' . filesize($ruta));
    header('Content-Disposition: inline; filename="' . preg_replace('/[^A-Za-z0-9._-]/', '_', $nombreDescarga) . '"');
    header('X-Content-Type-Options: nosniff');
    header('Cache-Control: private, no-store');
    readfile($ruta);
    exit;
}
