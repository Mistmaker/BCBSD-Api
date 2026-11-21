<?php

use PHPUnit\Framework\TestCase;

require_once __DIR__ . '/../classes/api.php';
require_once __DIR__ . '/../classes/mantenimiento.php';

final class MantenimientoTest extends TestCase
{
    /** @dataProvider proximos */
    public function testProximoKm(float $km, int $inicio, int $intervalo, ?float $ultimo, int $esperado): void
    {
        $this->assertSame($esperado, mantProximoKm($km, $inicio, $intervalo, $ultimo, 1000));
    }

    public static function proximos(): array
    {
        return [
            'vehículo nuevo, antes del primer punto' => [1200, 5000, 10000, null, 5000],
            'sin historial: siguiente punto desde el km actual' => [27000, 5000, 10000, null, 35000],
            'sin historial: punto dentro de la tolerancia se considera pendiente' => [25600, 5000, 10000, null, 25000],
            'con preventivo previo: siguiente punto tras el último' => [33000, 5000, 10000, 25100, 35000],
            'preventivo justo en el punto: el siguiente es el próximo intervalo' => [25000, 5000, 10000, 25000, 35000],
            'preventivo omitido: queda el punto vencido' => [47000, 5000, 10000, 25000, 35000],
            'km inicial 0' => [9000, 0, 5000, 5000, 10000],
            'preventivo adelantado dentro de la tolerancia cubre el punto' => [34600, 5000, 10000, 34500, 45000],
            'preventivo antes del primer punto lo cubre' => [4300, 5000, 10000, 4200, 15000],
            'preventivo demasiado adelantado no cubre el punto' => [32000, 5000, 10000, 32000, 35000],
        ];
    }

    public function testEstados(): void
    {
        $this->assertSame(MANT_ESTADO_AL_DIA, mantEstado(30000, 35000, 1000));
        $this->assertSame(MANT_ESTADO_PROXIMO, mantEstado(34000, 35000, 1000));
        $this->assertSame(MANT_ESTADO_VENCIDO, mantEstado(35000, 35000, 1000));
        $this->assertSame(MANT_ESTADO_VENCIDO, mantEstado(47000, 35000, 1000));
    }

    public function testIntervaloInvalido(): void
    {
        $this->expectException(InvalidArgumentException::class);
        mantProximoKm(1000, 0, 0, null, 1000);
    }

    public function testEvaluarPlanDevuelveLaReglaMasUrgente(): void
    {
        $reglas = [
            ['mantenimiento_id' => 1, 'mantenimiento_km_inicio' => 5000, 'mantenimiento_km_intervalo' => 10000],  // próximo 35000
            ['mantenimiento_id' => 2, 'mantenimiento_km_inicio' => 0, 'mantenimiento_km_intervalo' => 40000],     // próximo 40000
            ['mantenimiento_id' => 3, 'mantenimiento_km_inicio' => 0, 'mantenimiento_km_intervalo' => 32000],     // próximo 32000
        ];
        $r = mantEvaluarPlan(31500, $reglas, null, 1000);
        $this->assertSame(3, $r['mantenimiento_id']);
        $this->assertSame(32000, $r['km_proximo']);
        $this->assertEquals(500, $r['km_restante']);
        $this->assertSame(MANT_ESTADO_PROXIMO, $r['estado']);

        $this->assertNull(mantEvaluarPlan(1000, [], null, 1000));
    }

    public function testCodigo(): void
    {
        $this->assertSame('CBSD26MAN00012', mantCodigo('cbsd', 'MAN', 12, 2026));
        $this->assertSame('CBQ27INF00001', mantCodigo('CBQ', 'inf', 1, 2027));
    }

    public function testSerieDeCodigo(): void
    {
        $this->assertSame(12, mantSerieDeCodigo('CBSD26INF00012', 'CBSD', 'INF', 2026));
        $this->assertSame(3, mantSerieDeCodigo(' cbsd26inf00003 ', 'CBSD', 'INF', 2026));
        $this->assertNull(mantSerieDeCodigo('CBSD25INF00012', 'CBSD', 'INF', 2026), 'otro año');
        $this->assertNull(mantSerieDeCodigo('CBSD-17-RUPIF-001-M', 'CBSD', 'INF', 2026), 'formato manual');
    }

    public function testLista(): void
    {
        $this->assertSame(['MANO DE OBRA', 'REPUESTOS', 'ACEITES Y LUBRICANTES'], mantLista('MANO DE OBRA| REPUESTOS |ACEITES Y LUBRICANTES|'));
        $this->assertSame([], mantLista(null));
    }

    private function ordenValida(): object
    {
        return (object) [
            'fk_vehiculo_id' => 1, 'personal_solicita' => 2, 'director_administrativo' => 3, 'tecnico_servicios' => 4,
            'orden_fecha_mantenimiento' => '2026-11-20 10:00', 'orden_km_mantenimiento' => 15000,
            'trabajos' => [(object) ['trabajo_descripcion' => 'Cambio de aceite']],
            'facturas' => [(object) ['factura_tipo' => 'FACTURA', 'factura_valor' => '120.50']],
        ];
    }

    public function testOrdenValidaNormalizaTipo(): void
    {
        $o = $this->ordenValida();
        $o->orden_tipomantenimiento = 'preventivo';
        mantValidarOrden($o);
        $this->assertSame('PREVENTIVO', $o->orden_tipomantenimiento);

        $o2 = $this->ordenValida();
        mantValidarOrden($o2);
        $this->assertSame('CORRECTIVO', $o2->orden_tipomantenimiento);
    }

    /** @dataProvider ordenesInvalidas */
    public function testOrdenInvalida(callable $alterar, string $mensaje): void
    {
        $o = $this->ordenValida();
        $alterar($o);
        $this->expectException(ValidacionException::class);
        $this->expectExceptionMessage($mensaje);
        mantValidarOrden($o);
    }

    public static function ordenesInvalidas(): array
    {
        return [
            'sin vehículo' => [fn($o) => $o->fk_vehiculo_id = null, 'vehículo'],
            'sin técnico' => [fn($o) => $o->tecnico_servicios = 0, 'técnico'],
            'km negativo' => [fn($o) => $o->orden_km_mantenimiento = -5, 'kilometraje'],
            'km no numérico' => [fn($o) => $o->orden_km_mantenimiento = 'abc', 'kilometraje'],
            'tipo inválido' => [fn($o) => $o->orden_tipomantenimiento = 'OTRO', 'Tipo'],
            'estado inválido' => [fn($o) => $o->orden_estado = 'BORRADA', 'Estado'],
            'trabajo vacío' => [fn($o) => $o->trabajos[] = (object) ['trabajo_descripcion' => '  '], 'trabajos'],
            'factura sin rubro' => [fn($o) => $o->facturas[0]->factura_tipo = '', 'rubro'],
            'factura negativa' => [fn($o) => $o->facturas[0]->factura_valor = -1, 'valor'],
        ];
    }
}
