<?php

use PHPUnit\Framework\TestCase;

require_once __DIR__ . '/../classes/bitacora.php';

final class BitacoraTest extends TestCase
{
    private function carga(int $id, string $fecha, ?float $km, float $gal, float $valor, bool $ref = false): array
    {
        return ['id' => $id, 'codigo' => "C$id", 'fecha' => $fecha, 'km' => $km, 'galones' => $gal, 'valor' => $valor,
                'tipo_combustible' => 'DIESEL', 'referencia' => $ref];
    }

    private function orden(int $id, string $fecha, float $km, array $rubros, array $trabajos = [], string $tipo = 'CORRECTIVO'): array
    {
        return ['id' => $id, 'codigo' => "M$id", 'fecha' => $fecha, 'km' => $km, 'tipo' => $tipo, 'estado' => 'ENTREGADO',
                'total' => array_sum($rubros), 'rubros' => $rubros, 'trabajos' => $trabajos];
    }

    public function testTramosMetodoTanqueLleno(): void
    {
        // desordenadas a propósito: se ordenan por fecha y km
        $t = bitTramosCombustible([
            $this->carga(3, '2026-03-01', 10600, 12, 24),
            $this->carga(1, '2025-12-20', 10000, 14, 28, true),
            $this->carga(2, '2026-02-01', 10300, 10, 20),
        ]);
        $this->assertCount(2, $t); // la de referencia no genera tramo
        $this->assertSame(2, $t[0]['carga_id']);
        $this->assertEquals(300, $t[0]['km_recorridos']);
        $this->assertEquals(30.0, $t[0]['rendimiento']); // 300 km / 10 gal de la carga que repone
        $this->assertEquals(43, $t[0]['dias']);
        $this->assertEquals(25.0, $t[1]['rendimiento']);
        $this->assertEquals(0.08, $t[1]['costo_km']);
    }

    public function testTramosInvalidos(): void
    {
        $t = bitTramosCombustible([
            $this->carga(1, '2026-01-01', 1000, 10, 20),
            $this->carga(2, '2026-01-10', null, 10, 20),
            $this->carga(3, '2026-01-20', 900, 10, 20),
            $this->carga(4, '2026-01-30', 1300, 0, 0),
        ]);
        $this->assertSame(['Carga sin kilometraje', 'Kilometraje menor o igual al de la carga anterior', null], array_column($t, 'motivo'));
        // el combustible de las cargas sin lectura válida se suma al siguiente tramo, medido desde la última lectura buena (1000)
        $this->assertEquals(300, $t[2]['km_recorridos']);
        $this->assertEquals(20, $t[2]['galones']);
        $this->assertEquals(15.0, $t[2]['rendimiento']);
        $this->assertTrue($t[2]['incluye_cargas_sin_lectura']);
        $this->assertEquals(29, $t[2]['dias']);
    }

    public function testTramoSinGalones(): void
    {
        $t = bitTramosCombustible([$this->carga(1, '2026-01-01', 1000, 10, 20), $this->carga(2, '2026-01-10', 1200, 0, 0), $this->carga(3, '2026-01-20', 1500, 10, 20)]);
        $this->assertSame(['Carga sin galones', null], array_column($t, 'motivo'));
        $this->assertEquals(300, $t[1]['km_recorridos']); // la lectura de 1200 sí vale como punto de partida
    }

    public function testResumenCombustiblePonderaPorGalones(): void
    {
        $r = bitResumenCombustible([
            $this->carga(1, '2026-01-01', 1000, 10, 20, true),
            $this->carga(2, '2026-01-02', 1010, 1, 2),     // tramo corto: 10 km/gal
            $this->carga(3, '2026-02-01', 1310, 10, 20),   // 30 km/gal
        ]);
        $this->assertSame(2, $r['cargas']);
        $this->assertEquals(11, $r['galones']);
        $this->assertEquals(22, $r['valor']);
        $this->assertEquals(2.0, $r['precio_galon']);
        $this->assertEquals(28.18, $r['rendimiento']); // 310/11, no el promedio simple (20)
        $this->assertSame(0, $r['inconsistencias']);
    }

    public function testResumenCombustibleSinTramos(): void
    {
        $r = bitResumenCombustible([$this->carga(1, '2026-01-01', 1000, 10, 20)]);
        $this->assertSame(1, $r['cargas']);
        $this->assertNull($r['rendimiento']);
        $this->assertNull($r['costo_km']);
        $this->assertNull($r['dias_entre_cargas']);
    }

    public function testResumenMantenimiento(): void
    {
        $r = bitResumenMantenimiento([
            $this->orden(2, '2026-04-01', 15000, ['REPUESTOS' => 100, 'MANO DE OBRA' => 20.5]),
            $this->orden(1, '2026-01-01', 10000, ['ACEITES Y LUBRICANTES' => 50], [], 'PREVENTIVO'),
        ]);
        $this->assertSame(2, $r['ordenes']);
        $this->assertSame(['PREVENTIVO' => 1, 'CORRECTIVO' => 1], $r['por_tipo']);
        $this->assertEquals(170.5, $r['total']);
        $this->assertEquals(['ACEITES Y LUBRICANTES' => 50, 'REPUESTOS' => 100, 'MANO DE OBRA' => 20.5], $r['por_rubro']);
        $this->assertEquals(5000, $r['km_entre']);
        $this->assertEquals(90, $r['dias_entre']);
    }

    public function testNormalizarTrabajo(): void
    {
        $this->assertSame('CAMBIO MOTOR ARRANQUE', bitNormalizarTrabajo(' Cambio de motor de arranque. '));
        $this->assertSame('CAMBIO MOTOR ARRANQUE', bitNormalizarTrabajo('CAMBIO DEL MOTOR DE ARRANQUE'));
        $this->assertSame('REVISION SISTEMA ELECTRICO', bitNormalizarTrabajo('Revisión del sistema eléctrico'));
    }

    public function testTrabajosRepetidos(): void
    {
        $ordenes = [
            $this->orden(1, '2026-01-15', 10150, [], ['Cambio de motor de arranque', 'Cambio de aceite']),
            $this->orden(2, '2026-04-20', 11050, [], ['CAMBIO MOTOR DE ARRANQUE']),
            $this->orden(3, '2026-12-20', 20000, [], ['Cambio de aceite', 'cambio de aceite']), // duplicado en la misma orden cuenta una vez
        ];
        $r = bitTrabajosRepetidos($ordenes, 180);
        $this->assertCount(2, $r);
        $this->assertSame('CAMBIO MOTOR ARRANQUE', $r[0]['clave']); // primero los que caen en la ventana
        $this->assertTrue($r[0]['en_ventana']);
        $this->assertSame(95, $r[0]['dias_min']);
        $this->assertEquals(900, $r[0]['km_min']);
        $this->assertSame('CAMBIO MOTOR DE ARRANQUE', $r[0]['trabajo']); // texto de la última vez
        $this->assertSame(2, $r[1]['veces']);
        $this->assertFalse($r[1]['en_ventana']); // 339 días > 180
    }

    public function testComparacion(): void
    {
        $c = bitComparacion(24.0, [30.0, null, 34.0]);
        $this->assertEquals(32, $c['promedio_pares']);
        $this->assertSame(2, $c['pares_con_dato']);
        $this->assertEquals(-25.0, $c['diferencia_pct']);
        $this->assertNull(bitComparacion(24.0, [null])['diferencia_pct']);
        $this->assertNull(bitComparacion(null, [30.0])['diferencia_pct']);
    }

    public function testGastoMensual(): void
    {
        $g = bitGastoMensual(
            [$this->carga(1, '2025-12-30', 1, 1, 99, true), $this->carga(2, '2026-01-05', 1, 1, 20), $this->carga(3, '2026-03-05', 1, 1, 30)],
            [$this->orden(1, '2026-01-20', 1, ['REPUESTOS' => 100.004]), $this->orden(2, '2026-07-01', 1, ['REPUESTOS' => 5])],
            ['MANO DE OBRA', 'REPUESTOS'], '2026-01-15', '2026-03-31');
        $this->assertSame(['2026-01', '2026-02', '2026-03'], array_column($g, 'mes'));
        $this->assertEquals(['mes' => '2026-01', 'COMBUSTIBLE' => 20, 'MANO DE OBRA' => 0, 'REPUESTOS' => 100, 'total' => 120], $g[0]);
        $this->assertEquals(0, $g[1]['total']);
        $this->assertEquals(30, $g[2]['total']);
    }

    public function testIndicadoresYAlertas(): void
    {
        $cargas = [$this->carga(1, '2026-01-01', 10000, 10, 20, true), $this->carga(2, '2026-02-01', 10200, 10, 20), $this->carga(3, '2026-02-10', 10100, 5, 10)];
        $ordenes = [$this->orden(1, '2026-01-15', 10100, ['REPUESTOS' => 200], ['Cambio motor de arranque']),
                    $this->orden(2, '2026-03-01', 10400, ['REPUESTOS' => 200], ['Cambio de motor de arranque'])];
        $ind = bitIndicadores($cargas, $ordenes, ['min' => 10000, 'max' => 11000], 180);
        $this->assertEquals(1000, $ind['km_recorridos']);
        $this->assertEquals(0.4, $ind['costo_mant_km']);
        $this->assertEquals(430, $ind['costo_total']);
        $this->assertEquals(0.43, $ind['costo_total_km']);

        $alertas = bitAlertas($ind, bitComparacion(20.0, [25.0]), bitComparacion(0.4, [0.2]), 15, 30);
        $this->assertSame(['TRABAJO_REPETIDO', 'RENDIMIENTO_BAJO', 'COSTO_MANTENIMIENTO_ALTO', 'LECTURAS_KM'], array_column($alertas, 'tipo'));
        $this->assertSame('warning', $alertas[3]['nivel']);

        // dentro de la tolerancia: sin alertas de comparación
        $alertas = bitAlertas($ind, bitComparacion(22.0, [25.0]), bitComparacion(0.25, [0.2]), 15, 30);
        $this->assertSame(['TRABAJO_REPETIDO', 'LECTURAS_KM'], array_column($alertas, 'tipo'));
    }

    public function testIndicadoresSinDatos(): void
    {
        $ind = bitIndicadores([], [], ['min' => null, 'max' => null], 180);
        $this->assertEquals(0, $ind['km_recorridos']);
        $this->assertNull($ind['costo_total_km']);
        $this->assertSame([], bitAlertas($ind, bitComparacion(null, []), bitComparacion(null, []), 15, 30));
    }
}
