<?php

use PHPUnit\Framework\TestCase;

require_once __DIR__ . '/../classes/informePartes.php';

final class InformeEstadisticoTest extends TestCase
{
    private static function png(int $ancho, int $alto): string
    {
        $im = imagecreatetruecolor($ancho, $alto);
        ob_start();
        imagepng($im);
        return 'data:image/png;base64,' . base64_encode(ob_get_clean());
    }

    public function testGraficosValidosSeGuardanYSeLimpian(): void
    {
        $g = informeGraficos(['mes' => self::png(800, 300), 'otro' => self::png(20, 20), 'hora' => ''], ['mes', 'hora']);
        $this->assertSame(['mes'], array_keys($g), 'solo claves conocidas y con datos');
        $this->assertSame([800, 300], [$g['mes']['ancho'], $g['mes']['alto']]);
        $this->assertFileExists($g['mes']['ruta']);
        informeLimpiar($g);
        $this->assertFileDoesNotExist($g['mes']['ruta']);
        $this->assertSame([], informeGraficos(null, ['mes']));
    }

    public function testRechazaLoQueNoEsPng(): void
    {
        foreach (['data:image/png;base64,' . base64_encode('<svg></svg>'), 'no-base64-%%', self::png(5, 5), self::png(4100, 20)] as $malo) {
            try {
                informeGraficos(['mes' => $malo], ['mes']);
                $this->fail('debió rechazar el gráfico');
            } catch (ValidacionException $e) {
                $this->assertStringContainsString('"mes"', $e->getMessage());
            }
        }
        $this->expectException(ValidacionException::class);
        informeGraficos(array_fill(0, 21, ''), ['mes']);
    }

    public function testMedidasYFormatos(): void
    {
        $this->assertSame([170.0, 63.8], informeMedidas(1600, 600));
        $this->assertSame([95.0, 95.0], informeMedidas(1000, 1000), 'alto limitado: se reduce el ancho');
        $this->assertSame([120.0, 60.0], informeMedidas(1200, 600, 120));
        $this->assertSame('1.234,6', informeNumero(1234.56, 1));
        $this->assertSame('—', informeNumero(null));
        $this->assertSame('15 min', informeMinutos(15));
        $this->assertSame('1 h 05 min', informeMinutos(65));
        $this->assertSame('—', informeMinutos(null));
        $this->assertSame('20/11/2026', informeFecha('2026-11-20'));
        $this->assertSame('marzo 2026', informeMes('2026-03'));
    }

    public function testTablaCifrasYSeccion(): void
    {
        $vacia = informeTabla([['Mes', 50], ['Total', 50, 'right']], [], 'Nada.');
        $this->assertStringContainsString('colspan="2"', $vacia);
        $this->assertStringContainsString('Nada.', $vacia);
        $t = informeTabla([['Mes', 50], ['Total', 50, 'right']], [['<i>x</i>', ['b' => 7]]]);
        $this->assertStringContainsString('&lt;i&gt;x&lt;/i&gt;', $t);
        $this->assertStringContainsString('text-align:right;"><b>7</b>', $t);
        $c = informeCifras([['A', 1, ''], ['B', 2, ''], ['C', 3, ''], ['D', 4, '']]);
        $this->assertSame(2, substr_count($c, '<tr>'), 'filas de 3');
        $s = informeSeccion(2, 'Por mes', ['ruta' => '/tmp/g.png', 'ancho' => 1600, 'alto' => 600], '<p>t</p>', 170, 'nota');
        $this->assertStringContainsString('2. POR MES', $s);
        $this->assertStringContainsString('width:170mm;height:63.8mm', $s);
        $this->assertStringContainsString('<nobreak>', $s);
    }

    public function testFiltros(): void
    {
        $f = informePartesFiltros((object) ['desde' => '2025-01-01', 'hasta' => '2025-02-01', 'tipo' => 'auxilio', 'estacion' => '3']);
        $this->assertSame(['desde' => '2025-01-01', 'hasta' => '2025-02-01', 'estacion' => 3, 'tipo' => 'AUXILIO'], $f);
        $this->expectException(ValidacionException::class);
        informePartesFiltros((object) ['tipo' => 'OTRO']);
    }
}
