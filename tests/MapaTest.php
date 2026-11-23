<?php

use PHPUnit\Framework\TestCase;

require_once __DIR__ . '/../classes/mapaUbicacion.php';

final class MapaTest extends TestCase
{
    private function cfg(array $cambios = []): array
    {
        return array_merge(['tipo' => 'CALLES', 'url' => 'https://tile.example/{z}/{x}/{y}.png', 'atribucion' => '© colaboradores de OpenStreetMap',
            'zoom' => 17, 'ancho' => 640, 'alto' => 360, 'color' => '#D32F2F', 'qr' => 'https://www.google.com/maps/search/?api=1&query={lat},{lng}',
            'agente' => 'Prueba/1.0'], $cambios);
    }

    /** Cuadro de 256x256 de un solo color (verde claro) */
    private function cuadro(): string
    {
        $t = imagecreatetruecolor(256, 256);
        imagefill($t, 0, 0, imagecolorallocate($t, 200, 230, 200));
        ob_start();
        imagepng($t);
        return ob_get_clean();
    }

    public function testCoordenadasACuadros(): void
    {
        $this->assertSame([256.0, 256.0], mapaPixel(0, 0, 1));
        [$x, $y] = mapaPixel(-0.2477, -79.1834, 17);
        $this->assertSame(36706, (int) floor($x / 256), 'cuadro x de Santo Domingo en zoom 17: (lng + 180) / 360 * 2^17');
        $this->assertSame(65626, (int) floor($y / 256));
        $plan = mapaTiles(-0.2477, -79.1834, 17, 640, 360);
        $this->assertGreaterThanOrEqual(6, count($plan['tiles']), '640x360 necesita al menos 3x2 cuadros');
        $this->assertLessThanOrEqual(12, count($plan['tiles']));
        $this->assertSame('https://t/1/0/1.png', mapaUrlTile('https://t/{z}/{x}/{y}.png', 1, 2, 1), 'la longitud da la vuelta');
        $this->assertSame('https://www.google.com/maps/search/?api=1&query=-0.2477,-79.1834', mapaUrlQr($this->cfg(), -0.2477, -79.1834));
    }

    public function testComponeLaImagenConElMarcador(): void
    {
        $pedidos = [];
        $png = mapaComponer(-0.2477, -79.1834, $this->cfg(), function ($z, $x, $y) use (&$pedidos) {
            $pedidos[] = "$z/$x/$y";
            return $this->cuadro();
        });
        $img = imagecreatefromstring($png);
        $this->assertSame([640, 360], [imagesx($img), imagesy($img)]);
        $this->assertSame(count(array_unique($pedidos)), count($pedidos), 'cada cuadro se pide una vez');
        // Cabeza del marcador (26 px sobre el punto): color del marcador; esquina superior: fondo del mapa
        $rgb = fn($x, $y) => array_values(array_slice(imagecolorsforindex($img, imagecolorat($img, $x, $y)), 0, 3));
        $this->assertSame([211, 47, 47], $rgb(320 - 8, 180 - 26));
        $this->assertSame([200, 230, 200], $rgb(5, 5));
    }

    public function testSinMapaLanzaExcepcion(): void
    {
        $intentos = 0;
        try {
            mapaComponer(-0.25, -79.18, $this->cfg(), function () use (&$intentos) { $intentos++; return null; });
            $this->fail('Debía lanzar excepción');
        } catch (RuntimeException $e) {
            $this->assertSame(2, $intentos, 'sin servidor de mapas se rinde rápido');
        }
    }

    public function testRutasYGuardado(): void
    {
        $this->assertTrue(mapaRutaValida('ubicaciones/partes/MAPA-CBSD-PA-X1-2026-0001.png'));
        $this->assertFalse(mapaRutaValida('ubicaciones/partes/../licencias/x.png'));
        $this->assertFalse(mapaRutaValida('licencias/LIC-C-1.pdf'));
        $ruta = mapaGenerar($this->cfg(['ancho' => 300, 'alto' => 200]), 'partes', 'PRUEBA/UNIT 1', -0.25, -79.18, fn() => $this->cuadro());
        $this->assertSame('ubicaciones/partes/MAPA-PRUEBA-UNIT-1.png', $ruta);
        $this->assertTrue(mapaExiste($ruta));
        // Regenerar: la anterior queda en el histórico
        mapaGenerar($this->cfg(['ancho' => 300, 'alto' => 200]), 'partes', 'PRUEBA/UNIT 1', -0.26, -79.18, fn() => $this->cuadro());
        $historico = glob(mapaRutaAbsoluta('ubicaciones/partes/historico') . '/MAPA-PRUEBA-UNIT-1_*.png');
        $this->assertNotEmpty($historico);
        array_map('unlink', array_merge($historico, [mapaRutaAbsoluta($ruta)]));
    }
}
