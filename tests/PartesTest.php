<?php

use PHPUnit\Framework\TestCase;

require_once __DIR__ . '/../classes/partes.php';

final class PartesTest extends TestCase
{
    private function base(array $cambios = []): object
    {
        return json_decode(json_encode(array_merge([
            'parte_tipo' => 'AUXILIO', 'parte_fecha' => '2026-11-20', 'fk_estacion_id' => 1, 'parte_hora_aviso' => '10:09',
            'parte_descripcion_operaciones' => 'Operaciones', 'personal' => [['fk_personal_id' => 5, 'parte_personal_rol' => PARTE_ROL_MANDO]],
            'vehiculos' => [['fk_vehiculo_id' => 7, 'parte_vehiculo_hora_salida' => '2026-11-20T10:12', 'parte_vehiculo_hora_arribo' => '2026-11-20T10:20',
                'parte_vehiculo_hora_fin_operaciones' => '2026-11-20T11:00']],
        ], $cambios)));
    }

    public function testNumeroComoElFormatoDelArea(): void
    {
        $this->assertSame('CBSD-PA-X1-2026-0001', parteCodigo('CBSD', 'AUXILIO', 'X-1', 2026, 1));
        $this->assertSame('CBGADMSD-PI-X12-2026-0101', parteCodigo('CBGADMSD', 'INCENDIO', 'x 12', 2026, 101));
        $this->assertSame('CBSD-PA-X1-2026-12345', parteCodigo('CBSD', 'AUXILIO', 'X1', 2026, 12345));
        $this->assertSame('EST', parteSiglaEstacion('--'));
        $this->assertSame(['Bro. V.', 'Bro. 1'], parteLista(' Bro. V. | |Bro. 1 '));
    }

    public function testValidacionCorrecta(): void
    {
        $d = parteValidar($this->base(['parte_calle_principal' => 'Av. Quito', 'parte_calle_secundaria' => 'Tulcán',
            'equipos_herramientas' => [['parte_recurso_descripcion' => 'motosierra', 'parte_recurso_cantidad' => '1'], ['parte_recurso_cantidad' => null]],
            'victimas' => [['parte_victima_tipo_edad' => 'años'], ['parte_victima_nombres' => 'X', 'parte_victima_edad' => 30]]]), '2026-11-22');
        $this->assertSame(5, $d['cab']['fk_personal_id']);
        $this->assertSame('10:12', $d['cab']['parte_hora_salida']);
        $this->assertSame('11:00', $d['cab']['parte_hora_finalizacion']);
        $this->assertSame('2026-11-20', $d['cab']['parte_fecha_aviso'], 'sin fecha de aviso: la del parte');
        $this->assertSame('Av. Quito y Tulcán', $d['cab']['parte_direccion']);
        $this->assertSame('2026-11-20 10:20:00', $d['vehiculos'][0]['parte_vehiculo_hora_arribo']);
        $this->assertSame('MOTOSIERRA', $d['recursos']['equipos_herramientas'][0]['parte_recurso_descripcion']);
        $this->assertCount(1, $d['recursos']['equipos_herramientas'], 'fila vacía ignorada');
        $this->assertSame(1, $d['cab']['parte_total_heridos']);
        $this->assertSame('NINGUNO', $d['cab']['parte_danios_materiales']);
        $this->assertSame([], $d['tipos_incendio'], 'solo los partes de incendio guardan tipo de incendio');
    }

    public static function invalidos(): array
    {
        return [
            'tipo' => [['parte_tipo' => 'RESCATE'], 'AUXILIO o INCENDIO'],
            'fecha futura' => [['parte_fecha' => '2026-11-23'], 'futura'],
            'sin estación' => [['fk_estacion_id' => null], 'estación'],
            'hora aviso' => [['parte_hora_aviso' => '25:00'], 'Hora inválida'],
            'sin descripción' => [['parte_descripcion_operaciones' => '  '], 'operaciones'],
            'dos al mando' => [['personal' => [['fk_personal_id' => 5, 'parte_personal_rol' => PARTE_ROL_MANDO], ['fk_personal_id' => 6, 'parte_personal_rol' => PARTE_ROL_MANDO]]], 'una (y solo una)'],
            'persona repetida' => [['personal' => [['fk_personal_id' => 5, 'parte_personal_rol' => PARTE_ROL_MANDO], ['fk_personal_id' => 5]]], 'ya está registrada'],
            'vehículo repetido' => [['vehiculos' => [['fk_vehiculo_id' => 7], ['fk_vehiculo_id' => 7]]], 'ya está registrado'],
            'vehículo sin placa' => [['vehiculos' => [['parte_vehiculo_km_salida' => 10]]], 'placa'],
            'cantidad' => [['insumos' => [['parte_recurso_descripcion' => 'Gasa', 'parte_recurso_cantidad' => 0]]], 'mayor a 0'],
            'coordenadas' => [['parte_latitud' => '95'], 'Coordenadas'],
            'croquis' => [['parte_croquis_url' => 'javascript:alert(1)'], 'http'],
            'estado anulado' => [['parte_estado' => 'ANULADO'], 'Anular'],
            'aviso posterior' => [['parte_fecha_aviso' => '2026-11-21'], 'posterior'],
        ];
    }

    /** @dataProvider invalidos */
    public function testValidacionesQueFallan(array $cambios, string $mensaje): void
    {
        $this->expectException(ValidacionException::class);
        $this->expectExceptionMessage($mensaje);
        parteValidar($this->base($cambios), '2026-11-22');
    }

    public function testTiemposYMinutos(): void
    {
        $t = parteTiempos([
            ['parte_vehiculo_hora_salida' => '2026-11-20 10:15:00', 'parte_vehiculo_hora_arribo' => '2026-11-20 10:30:00', 'parte_vehiculo_hora_fin_operaciones' => '2026-11-20 11:00:00'],
            ['parte_vehiculo_hora_salida' => '2026-11-20 10:12:00', 'parte_vehiculo_hora_arribo' => null, 'parte_vehiculo_hora_fin_operaciones' => '2026-11-21 01:00:00'],
        ]);
        $this->assertSame(['salida' => '10:12', 'arribo' => '10:30', 'fin' => '01:00'], $t);
        $this->assertSame(15, parteMinutos('2026-11-20 10:05', '2026-11-20 10:20'));
        $this->assertNull(parteMinutos('2026-11-20 10:20', '2026-11-20 10:05'));
        $this->assertNull(parteMinutos(null, '2026-11-20 10:05'));
        $this->assertSame('2026-11-20 10:05:00', parteFechaHora('2026-11-20T10:05', 'x'));
        $this->expectException(ValidacionException::class);
        parteFechaHora('2026-02-30T10:05', 'x');
    }
}
