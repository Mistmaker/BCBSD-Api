<?php
/*
 * Imagen de ubicación: recorte del mapa alrededor de una coordenada con el marcador del punto (PNG).
 * Reutilizable por cualquier módulo (partes de servicio y, más adelante, permisos de funcionamiento y planes de
 * emergencia). Se genera en el servidor al guardar el registro y se guarda en DOCS_DIR/ubicaciones/{módulo}/.
 *
 * Parámetros (admin.tb_params, módulo MAPAS): servidor de mapas de calles y satelital ({z}/{x}/{y}), su atribución,
 * zoom, tamaño, color del marcador, enlace del QR e identificación ante el servidor de mapas.
 * Los cuadros (tiles) descargados se guardan en caché 30 días (política de uso de OpenStreetMap).
 */
require_once __DIR__ . '/api.php';

const MAPA_TIPOS = ['CALLES', 'SATELITE'];
const MAPA_TILE = 256;

/** Configuración del mapa de un tipo. Leer ANTES de preparar otras consultas (Database comparte la sentencia). */
function mapaConfig(Database $db, string $tipo = 'CALLES'): array
{
    $tipo = in_array($tipo, MAPA_TIPOS, true) ? $tipo : 'CALLES';
    $sat = $tipo === 'SATELITE';
    return [
        'tipo' => $tipo,
        'url' => parametro($db, $sat ? 'MAPA_SATELITE_URL' : 'MAPA_CALLES_URL',
            $sat ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}' : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
        'atribucion' => parametro($db, $sat ? 'MAPA_SATELITE_ATRIBUCION' : 'MAPA_CALLES_ATRIBUCION',
            $sat ? 'Imágenes © Esri, Maxar, Earthstar Geographics' : '© colaboradores de OpenStreetMap'),
        'zoom' => max(1, min(19, (int) parametro($db, 'MAPA_ZOOM', 17))),
        'ancho' => max(200, min(1200, (int) parametro($db, 'MAPA_ANCHO', 640))),
        'alto' => max(150, min(900, (int) parametro($db, 'MAPA_ALTO', 360))),
        'color' => (string) parametro($db, 'MAPA_MARCADOR_COLOR', '#D32F2F'),
        'qr' => (string) parametro($db, 'MAPA_QR_URL', 'https://www.google.com/maps/search/?api=1&query={lat},{lng}'),
        'agente' => (string) parametro($db, 'MAPA_USER_AGENT', 'SistemaBomberos/1.0'),
    ];
}

/** Coordenada -> píxel global (Web Mercator) en el zoom indicado */
function mapaPixel(float $lat, float $lng, int $zoom): array
{
    $lat = max(-85.05112878, min(85.05112878, $lat));
    $escala = MAPA_TILE * (2 ** $zoom);
    $x = ($lng + 180) / 360 * $escala;
    $s = sin(deg2rad($lat));
    $y = (0.5 - log((1 + $s) / (1 - $s)) / (4 * M_PI)) * $escala;
    return [$x, $y];
}

/** Cuadros que cubren un recorte de $ancho x $alto centrado en el punto: ['origen' => [x0, y0], 'tiles' => [[tx, ty], ...]] */
function mapaTiles(float $lat, float $lng, int $zoom, int $ancho, int $alto): array
{
    [$px, $py] = mapaPixel($lat, $lng, $zoom);
    $x0 = (int) floor($px - $ancho / 2);
    $y0 = (int) floor($py - $alto / 2);
    $max = 2 ** $zoom;
    $tiles = [];
    for ($ty = intdiv($y0 - ($y0 < 0 ? MAPA_TILE - 1 : 0), MAPA_TILE); $ty * MAPA_TILE < $y0 + $alto; $ty++) {
        for ($tx = intdiv($x0 - ($x0 < 0 ? MAPA_TILE - 1 : 0), MAPA_TILE); $tx * MAPA_TILE < $x0 + $ancho; $tx++) {
            if ($ty >= 0 && $ty < $max) {
                $tiles[] = [$tx, $ty];
            }
        }
    }
    return ['origen' => [$x0, $y0], 'tiles' => $tiles];
}

function mapaUrlTile(string $plantilla, int $z, int $x, int $y): string
{
    $max = 2 ** $z;
    $x = (($x % $max) + $max) % $max; // la longitud da la vuelta al mundo
    return strtr($plantilla, ['{z}' => $z, '{x}' => $x, '{y}' => $y]);
}

/** Enlace del QR (abre la ubicación en el teléfono) */
function mapaUrlQr(array $cfg, float $lat, float $lng): string
{
    $f = fn(float $v) => rtrim(rtrim(number_format($v, 6, '.', ''), '0'), '.');
    return strtr($cfg['qr'], ['{lat}' => $f($lat), '{lng}' => $f($lng)]);
}

/**
 * Compone el PNG: cuadros del mapa + marcador en el centro + atribución. $tile(z, x, y) devuelve los bytes del cuadro
 * (PNG o JPEG) o null. Lanza RuntimeException si no se pudo obtener ningún cuadro.
 */
function mapaComponer(float $lat, float $lng, array $cfg, callable $tile): string
{
    [$ancho, $alto, $zoom] = [$cfg['ancho'], $cfg['alto'], $cfg['zoom']];
    $plan = mapaTiles($lat, $lng, $zoom, $ancho, $alto);
    [$x0, $y0] = $plan['origen'];
    $img = imagecreatetruecolor($ancho, $alto);
    imagefill($img, 0, 0, imagecolorallocate($img, 229, 227, 223));
    $pegados = 0;
    $fallidos = 0;
    foreach ($plan['tiles'] as [$tx, $ty]) {
        $bytes = $tile($zoom, $tx, $ty);
        $t = $bytes ? @imagecreatefromstring($bytes) : false;
        if (!$t) {
            // Servidor de mapas caído o sin internet: no esperar todos los cuadros (guardar el parte no debe demorar)
            if (++$fallidos >= 2 && $pegados === 0) {
                break;
            }
            continue;
        }
        imagecopy($img, $t, $tx * MAPA_TILE - $x0, $ty * MAPA_TILE - $y0, 0, 0, imagesx($t), imagesy($t));
        imagedestroy($t);
        $pegados++;
    }
    if ($pegados === 0) {
        imagedestroy($img);
        throw new RuntimeException('No se pudo descargar el mapa (servidor de mapas no disponible)');
    }
    mapaMarcador($img, (int) round($ancho / 2), (int) round($alto / 2), $cfg['color']);
    mapaAtribucion($img, $cfg['atribucion']);
    ob_start();
    imagepng($img, null, 6);
    imagedestroy($img);
    return ob_get_clean();
}

/** Marcador tipo "pin" con la punta en ($x, $y) */
function mapaMarcador(\GdImage $img, int $x, int $y, string $colorHex): void
{
    [$r, $g, $b] = sscanf(ltrim(preg_match('/^#?[0-9a-f]{6}$/i', $colorHex) ? $colorHex : '#D32F2F', '#'), '%02x%02x%02x');
    imageantialias($img, true);
    $color = imagecolorallocate($img, $r, $g, $b);
    $blanco = imagecolorallocate($img, 255, 255, 255);
    $sombra = imagecolorallocatealpha($img, 0, 0, 0, 90);
    imagefilledellipse($img, $x, $y, 14, 6, $sombra);                       // sombra en el suelo
    $cy = $y - 26;                                                        // centro de la cabeza
    imagefilledpolygon($img, [$x - 11, $cy + 5, $x + 11, $cy + 5, $x, $y], $blanco);
    imagefilledellipse($img, $x, $cy, 30, 30, $blanco);                   // borde blanco
    imagefilledpolygon($img, [$x - 8, $cy + 5, $x + 8, $cy + 5, $x, $y - 3], $color);
    imagefilledellipse($img, $x, $cy, 24, 24, $color);
    imagefilledellipse($img, $x, $cy, 9, 9, $blanco);                     // punto central
}

/** Atribución en la esquina inferior derecha (texto ASCII de la fuente interna de GD) */
function mapaAtribucion(\GdImage $img, string $texto): void
{
    $ascii = trim((string) @iconv('UTF-8', 'ASCII//TRANSLIT', str_replace('©', '(c)', $texto)));
    if ($ascii === '') {
        return;
    }
    $fuente = 2;
    $w = imagefontwidth($fuente) * strlen($ascii) + 8;
    $h = imagefontheight($fuente) + 4;
    $x = imagesx($img) - $w;
    $y = imagesy($img) - $h;
    imagefilledrectangle($img, $x, $y, imagesx($img), imagesy($img), imagecolorallocatealpha($img, 255, 255, 255, 40));
    imagestring($img, $fuente, $x + 4, $y + 2, $ascii, imagecolorallocate($img, 60, 60, 60));
}

/** Descarga un cuadro con caché en disco (30 días). null si no se pudo. */
function mapaDescargarTile(string $url, string $agente, ?string $cache = null): ?string
{
    $cache ??= rtrim(DOCS_DIR, '/') . '/cache/mapas';
    $archivo = $cache . '/' . sha1($url) . '.img';
    if (is_file($archivo) && filemtime($archivo) > time() - 30 * 86400) {
        return file_get_contents($archivo) ?: null;
    }
    $ch = curl_init($url);
    curl_setopt_array($ch, [CURLOPT_RETURNTRANSFER => true, CURLOPT_FOLLOWLOCATION => true, CURLOPT_CONNECTTIMEOUT => 5, CURLOPT_TIMEOUT => 10,
        CURLOPT_USERAGENT => $agente, CURLOPT_PROTOCOLS => CURLPROTO_HTTPS | CURLPROTO_HTTP | CURLPROTO_FILE]);
    $bytes = curl_exec($ch);
    $codigo = (int) curl_getinfo($ch, CURLINFO_RESPONSE_CODE);
    curl_close($ch);
    $ok = is_string($bytes) && $bytes !== '' && ($codigo === 200 || ($codigo === 0 && str_starts_with($url, 'file://')));
    if (!$ok) {
        return null;
    }
    if (is_dir($cache) || @mkdir($cache, 0750, true)) {
        @file_put_contents($archivo, $bytes);
    }
    return $bytes;
}

/** Ruta relativa válida de una imagen de ubicación: 'ubicaciones/partes/MAPA-CBSD-PA-X1-2026-0001.png' */
function mapaRutaValida(?string $relativa): bool
{
    return (bool) $relativa && (bool) preg_match('#^ubicaciones/[a-z-]+/(historico/)?MAPA-[A-Za-z0-9_-]+\.png$#', $relativa) && !str_contains($relativa, '..');
}

function mapaRutaAbsoluta(string $relativa): string
{
    return rtrim(DOCS_DIR, '/') . '/' . $relativa;
}

/** La imagen guardada existe en disco */
function mapaExiste(?string $relativa): bool
{
    return mapaRutaValida($relativa) && is_file(mapaRutaAbsoluta($relativa));
}

/**
 * Genera y guarda la imagen de ubicación. $modulo: carpeta ('partes'); $nombre: identificador del registro (número).
 * La imagen anterior con el mismo nombre pasa a ubicaciones/{módulo}/historico/ con fecha. Devuelve la ruta relativa.
 * $tile permite pruebas sin descargar.
 */
function mapaGenerar(array $cfg, string $modulo, string $nombre, float $lat, float $lng, ?callable $tile = null): string
{
    if (!preg_match('/^[a-z-]+$/', $modulo)) {
        throw new InvalidArgumentException("Módulo inválido: $modulo");
    }
    if ($lat < -90 || $lat > 90 || $lng < -180 || $lng > 180) {
        throw new InvalidArgumentException('Coordenadas fuera de rango');
    }
    $tile ??= fn(int $z, int $x, int $y) => mapaDescargarTile(mapaUrlTile($cfg['url'], $z, $x, $y), $cfg['agente']);
    $png = mapaComponer($lat, $lng, $cfg, $tile);
    $base = 'MAPA-' . trim(preg_replace('/[^A-Za-z0-9_-]+/', '-', $nombre), '-');
    $relativa = "ubicaciones/$modulo/$base.png";
    $dir = mapaRutaAbsoluta("ubicaciones/$modulo");
    $historico = "$dir/historico";
    foreach ([$dir, $historico] as $d) {
        if (!is_dir($d) && !@mkdir($d, 0750, true) && !is_dir($d)) {
            throw new RuntimeException("No se pudo crear la carpeta $d");
        }
    }
    if (is_file(mapaRutaAbsoluta($relativa))) {
        rename(mapaRutaAbsoluta($relativa), "$historico/{$base}_" . date('Ymd-His') . '.png');
    }
    if (file_put_contents(mapaRutaAbsoluta($relativa), $png) === false) {
        throw new RuntimeException('No se pudo guardar la imagen del mapa (revise los permisos de la carpeta de documentos)');
    }
    @chmod(mapaRutaAbsoluta($relativa), 0640);
    return $relativa;
}

/** Envía la imagen al navegador (con sesión y privilegio ya verificados por el endpoint) */
function mapaEnviar(string $relativa): void
{
    header('Content-Type: image/png');
    header('Cache-Control: private, max-age=300');
    header('Content-Length: ' . filesize(mapaRutaAbsoluta($relativa)));
    readfile(mapaRutaAbsoluta($relativa));
    exit;
}
