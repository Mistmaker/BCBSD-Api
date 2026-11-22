<?php

use PHPUnit\Framework\TestCase;

require_once __DIR__ . '/../classes/reporteParte.php';

final class ReporteParteTest extends TestCase
{
    public function testTextosDelFormato(): void
    {
        $this->assertSame('viernes, 20 de noviembre de 2026', parteFechaTexto('2026-11-20'));
        $this->assertSame('', parteFechaTexto(null));
        $this->assertSame('22:14', parteHoraCorta('2026-11-20T22:14', '2026-11-20'));
        $this->assertSame('21/11 00:35', parteHoraCorta('2026-11-21 00:35:00', '2026-11-20'), 'otro día: se indica la fecha');
        $this->assertSame('6', parteCantidad('6.0000'));
        $this->assertSame('1.5', parteCantidad(1.5));
        $this->assertSame('', parteCantidad(null));
        $this->assertSame('15 min', minutosTexto(15));
        $this->assertSame('1 h 05 min', minutosTexto(65));
    }

    public function testTablaVaciaYEscapada(): void
    {
        $vacia = parteTabla([['Placa', 50], ['Siglas', 50]], []);
        $this->assertStringContainsString('colspan="2"', $vacia);
        $this->assertStringContainsString('Ninguno', $vacia);
        $html = parteTabla([['Placa', 50], ['Siglas', 50]], [[e('<b>PMA</b>'), e('R-11')]]);
        $this->assertStringContainsString('&lt;b&gt;PMA&lt;/b&gt;', $html);
        $this->assertStringContainsString('width:50%', $html);
    }
}
