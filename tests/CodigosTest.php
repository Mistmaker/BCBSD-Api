<?php

use PHPUnit\Framework\TestCase;

require_once __DIR__ . '/../classes/codigos.php';
require_once __DIR__ . '/../classes/mantenimiento.php';

final class CodigosTest extends TestCase
{
    public function testPatronPorAnioTipoYOrigenConCualquierPrefijo(): void
    {
        $p = '/' . str_replace('/', '\/', codPatron(2026, 'MOV', 'DA')) . '/';
        $this->assertMatchesRegularExpression($p, 'CBSD26MOVDA00012');
        $this->assertMatchesRegularExpression($p, 'BCBSD26MOVDA00012'); // otro prefijo: la secuencia continúa
        $this->assertDoesNotMatchRegularExpression($p, 'CBSD25MOVDA00012'); // otro año
        $this->assertDoesNotMatchRegularExpression($p, 'CBSD26ABASDA00012'); // otro tipo
        $this->assertDoesNotMatchRegularExpression($p, 'CBSD26MOVDAX00012'); // otro origen
        $this->assertDoesNotMatchRegularExpression($p, 'CBSD26MOVDA0012'); // 4 dígitos
    }

    public function testOrigenConCaracteresEspeciales(): void
    {
        $patron = codPatron(2026, 'ABAS', 'EST. 1 (CENTRO)');
        $this->assertSame('^[A-Z0-9]*26ABASEST\. 1 \(CENTRO\)[0-9]{5}$', $patron);
        $this->assertMatchesRegularExpression('/' . $patron . '/', 'CBSD26ABASEST. 1 (CENTRO)00003');
        $this->assertDoesNotMatchRegularExpression('/' . $patron . '/', 'CBSD26ABASESTX 1 (CENTRO)00003');
    }

    public function testCodigosDeMantenimientoYPeticiones(): void
    {
        $this->assertSame('CBSD26ODM00001', mantCodigo('CBSD', 'ODM', 1, 2026));
        $this->assertSame('CBSD27INF00123', mantCodigo('cbsd', 'INF', 123, 2027));
        $this->assertSame(2, mantSerieDeCodigo('CBSD27ODM00002', 'CBSD', 'ODM', 2027));
        $this->assertNull(mantSerieDeCodigo('CBSD26ODM00002', 'CBSD', 'ODM', 2027)); // otro año: no cuenta
    }

    public function testCombustibleCOMContinuaLaNumeracionDeABAS(): void
    {
        $patron = '/' . codPatron(2026, ['COM', 'ABAS'], 'DA') . '/';
        $this->assertMatchesRegularExpression($patron, 'CBSD26ABASDA00012');
        $this->assertMatchesRegularExpression($patron, 'CBSD26COMDA00013');
        $this->assertDoesNotMatchRegularExpression($patron, 'CBSD26MOVDA00013');
        $this->assertDoesNotMatchRegularExpression($patron, 'CBSD25COMDA00013', 'otro año');
    }
}
