<?php

use PHPUnit\Framework\TestCase;

require_once __DIR__ . '/../classes/operadores.php';

final class OperadoresTest extends TestCase
{
    public static function cedulas(): array
    {
        return [
            'válida Pichincha' => ['1712345675', true],
            'válida Santo Domingo' => ['2301234569', true],
            'dígito verificador incorrecto' => ['1712345670', false],
            'provincia inexistente' => ['2512345678', false],
            'tercer dígito mayor a 5 (RUC)' => ['1762345675', false],
            'con letras' => ['17123A5675', false],
            '9 dígitos' => ['171234567', false],
            'vacía' => ['', false],
        ];
    }

    /** @dataProvider cedulas */
    public function testCedula(string $cedula, bool $esperado): void
    {
        $this->assertSame($esperado, operCedulaValida($cedula));
    }

    public function testVigencia(): void
    {
        $hoy = '2026-11-22';
        $this->assertSame('VENCIDA', operVigencia('2026-11-21', 30, $hoy));
        $this->assertSame('VENCIDA', operVigencia(null, 30, $hoy));
        $this->assertSame('POR VENCER', operVigencia('2026-11-22', 30, $hoy)); // vence hoy: aún vale
        $this->assertSame('POR VENCER', operVigencia('2026-12-22', 30, $hoy));
        $this->assertSame('VIGENTE', operVigencia('2026-12-23', 30, $hoy));
        $this->assertSame('VIGENTE', operVigencia('2026-11-23', 0, $hoy));
    }

    public function testHabilitado(): void
    {
        $base = ['persona_apellidos' => 'PÉREZ', 'persona_nombres' => 'ANA', 'conductor_estado' => 'ACTIVO',
                 'ppersonal_estado' => 'EN FUNCIONES', 'conductor_licencia_validez' => '2030-01-01'];
        $o = operCompletar($base, 30, '2026-11-22');
        $this->assertTrue($o['habilitado']);
        $this->assertSame('PÉREZ ANA', $o['nombre_completo']);
        $this->assertFalse(operCompletar(['conductor_licencia_validez' => '2026-01-01'] + $base, 30, '2026-11-22')['habilitado']);
        $this->assertFalse(operCompletar(['conductor_estado' => 'INACTIVO'] + $base, 30, '2026-11-22')['habilitado']);
        $this->assertFalse(operCompletar(['ppersonal_estado' => 'SALIDA'] + $base, 30, '2026-11-22')['habilitado']);
        $this->assertTrue(operCompletar(['conductor_licencia_validez' => '2026-12-01'] + $base, 30, '2026-11-22')['habilitado']); // por vencer sí conduce
    }
}
