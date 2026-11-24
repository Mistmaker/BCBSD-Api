<?php

use PHPUnit\Framework\TestCase;

require_once __DIR__ . '/../classes/parametros.php';

final class ParametrosTest extends TestCase
{
    public function testTiposConocidos(): void
    {
        $this->assertSame('NUMERO', paramTipo('numero'));
        $this->assertSame('TEXTO', paramTipo('integer'), 'un tipo antiguo sin migrar se trata como texto');
        $this->assertSame('TEXTO', paramTipo(null));
    }

    public function testValoresValidos(): void
    {
        $this->assertSame('1.5', paramValidar('NUMERO', ' 1,5 '));
        $this->assertSame('', paramValidar('NUMERO', ''), 'vacío permitido (p. ej. "vacío = ninguna")');
        $this->assertSame('Hola', paramValidar('TEXTO', '  Hola '));
        $this->assertSame("a\nb", paramValidar('TEXTO_LARGO', "a\r\nb"));
        $this->assertSame('A|B C|D', paramValidar('LISTA', ' A | B C ||D| '));
        $this->assertSame('A|B', paramValidar('LISTA', ['A', ' B ']));
        $this->assertSame('A|B', paramValidar('LISTA', "A\nB"));
        $this->assertSame('SI', paramValidar('SI_NO', 'sí'));
        $this->assertSame('NO', paramValidar('SI_NO', 'no'));
        $this->assertSame("{\n    \"a\": \"Ñ\"\n}", paramValidar('JSON', '{"a":"Ñ"}'));
        $this->assertSame("[\n    1,\n    2\n]", paramValidar('JSON', [1, 2]));
        $this->assertSame('#D32F2F', paramValidar('COLOR', '#d32f2f'));
        $this->assertSame('<b>x</b>', paramValidar('HTML', '<b>x</b>'));
    }

    /** @dataProvider invalidos */
    public function testValoresInvalidos(string $tipo, $valor, string $mensaje): void
    {
        try {
            paramValidar($tipo, $valor);
            $this->fail('debió rechazar el valor');
        } catch (ValidacionException $e) {
            $this->assertStringContainsString($mensaje, $e->getMessage());
        }
    }

    public static function invalidos(): array
    {
        return [
            'número' => ['NUMERO', '12a', 'número'],
            'texto en varias líneas' => ['TEXTO', "a\nb", 'una sola línea'],
            'lista repetida' => ['LISTA', 'A|b|B', 'repetido'],
            'si/no' => ['SI_NO', 'quizás', 'SI o NO'],
            'json' => ['JSON', '{"a":', 'JSON inválido'],
            'json vacío' => ['JSON', '', 'vacío'],
            'color' => ['COLOR', 'rojo', '#RRGGBB'],
            'objeto en texto' => ['TEXTO', ['a'], 'inválido'],
        ];
    }
}
