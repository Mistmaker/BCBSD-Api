<?php

use PHPUnit\Framework\TestCase;

require_once __DIR__ . '/../classes/reporte.php';

final class ReporteTest extends TestCase
{
    /** @dataProvider montos */
    public function testMontoEnLetras(float $monto, string $esperado): void
    {
        $this->assertSame($esperado, montoEnLetras($monto));
    }

    public static function montos(): array
    {
        return [
            'formato del informe' => [466.10, 'CUATROCIENTOS SESENTA Y SEIS DÓLARES CON DIEZ CENTAVOS'],
            'formato de la bitácora' => [2349.89, 'DOS MIL TRESCIENTOS CUARENTA Y NUEVE DÓLARES CON OCHENTA Y NUEVE CENTAVOS'],
            'uno en singular' => [1.01, 'UN DÓLAR CON UN CENTAVO'],
            'veintiún' => [21, 'VEINTIÚN DÓLARES CON CERO CENTAVOS'],
            'cien' => [100, 'CIEN DÓLARES CON CERO CENTAVOS'],
            'ciento uno' => [101, 'CIENTO UN DÓLARES CON CERO CENTAVOS'],
            'veintiún mil' => [21000, 'VEINTIÚN MIL DÓLARES CON CERO CENTAVOS'],
            'millón exacto' => [1000000, 'UN MILLÓN DE DÓLARES CON CERO CENTAVOS'],
            'solo centavos' => [0.5, 'CERO DÓLARES CON CINCUENTA CENTAVOS'],
            'redondeo de flotantes' => [0.1 + 0.2, 'CERO DÓLARES CON TREINTA CENTAVOS'],
        ];
    }

    public function testFechaEnLetras(): void
    {
        $this->assertSame('01 DÍAS DEL MES DE JUNIO DE 2026', fechaEnLetras('2026-06-01'));
        $this->assertSame('31 DÍAS DEL MES DE DICIEMBRE DE 2025', fechaEnLetras('2025-12-31 18:00:00'));
    }

    public function testEscapaHtml(): void
    {
        $this->assertSame('&lt;b&gt;TALLER &amp; CIA&lt;/b&gt;', e('<b>TALLER & CIA</b>'));
        $this->assertSame('', e(null));
    }
}
