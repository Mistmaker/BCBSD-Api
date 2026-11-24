<?php

use PHPUnit\Framework\TestCase;

require_once __DIR__ . '/../classes/informePartes.php';
require_once __DIR__ . '/../classes/informeBitacora.php';
require_once __DIR__ . '/../classes/informeResumenGerencial.php';

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

    public function testRangoYFormatosDeBitacora(): void
    {
        $this->assertSame(['2026-01-01', '2026-06-30'], informeRango((object) ['desde' => '2026-01-01', 'hasta' => '2026-06-30']));
        [$d, $h] = informeRango((object) ['hasta' => '2026-06-30']);
        $this->assertSame(['2025-07-01', '2026-06-30'], [$d, $h], 'por defecto 12 meses');
        $this->assertSame('$ 1.234,57', informeDinero(1234.567));
        $this->assertSame('$ 0,044', informeDinero(0.0436, 3));
        $this->assertSame('Aceites y lubricantes', informeEtiqueta('ACEITES Y LUBRICANTES'));
        $v = ['vehiculo_sigla' => 'B-1', 'vehiculo_placa' => 'PEA-1', 'vehiculo_marca' => 'HINO', 'vehiculo_modelo' => 'GH8', 'vehiculo_anio' => 2015];
        $this->assertSame('B-1 · PEA-1', informeVehiculoCorto($v));
        $this->assertSame('HINO GH8 2015', informeVehiculoModelo($v));
        $grave = ['nivel' => 'serious'];
        $orden = informeOrdenFlota([
            ['vehiculo_id' => 1, 'alertas' => [], 'costo_total_km' => 0.9],
            ['vehiculo_id' => 2, 'alertas' => [$grave], 'costo_total_km' => 0.1],
            ['vehiculo_id' => 3, 'alertas' => [], 'costo_total_km' => null],
        ]);
        $this->assertSame([2, 1, 3], array_column($orden, 'vehiculo_id'));
        $this->expectException(ValidacionException::class);
        informeRango((object) ['desde' => '2026-13-01']);
    }

    public function testTablaLargaSeParte(): void
    {
        $filas = array_fill(0, 30, ['x']);
        $s = informeSeccion(1, 'Historial', ['ruta' => '/tmp/g.png', 'ancho' => 1600, 'alto' => 600], informeTabla([['A', 100]], $filas, '', 'Título'));
        $this->assertStringContainsString('</nobreak><table', $s, 'solo título y gráfico juntos');
        $this->assertStringContainsString('<thead><tr><th colspan="1" class="seccion-th">TÍTULO</th>', $s);
    }

    public function testResumenMesYVariacion(): void
    {
        $this->assertSame('2026-11', informeMesValido((object) ['mes' => '2026-11']));
        $this->assertSame(date('Y-m'), informeMesValido((object) []));
        $this->assertSame(20.0, informeVariacion(1200, 1000));
        $this->assertNull(informeVariacion(1200, 0));
        $this->assertSame('CAM-01 · P-2', informeVehiculoTexto(['vehiculo_sigla' => 'CAM-01', 'vehiculo_placa' => 'P-2']));
        $this->expectException(ValidacionException::class);
        informeMesValido((object) ['mes' => '2026-13']);
    }
}
