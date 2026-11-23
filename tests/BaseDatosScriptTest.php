<?php

use PHPUnit\Framework\TestCase;

/** script-3.sql es el único script de la base: no borra datos ni lleva claves. */
final class BaseDatosScriptTest extends TestCase
{
    private function script(): string
    {
        return file_get_contents(dirname(__DIR__) . '/script-3.sql');
    }

    public function testNoBorraTablasNiDatos(): void
    {
        $sql = $this->script();
        $this->assertDoesNotMatchRegularExpression('/^\s*DROP\s+(TABLE|SCHEMA)/im', $sql);
        $this->assertDoesNotMatchRegularExpression('/^\s*(TRUNCATE|DELETE\s+FROM)\s/im', $sql);
    }

    public function testSinClavesEnElArchivo(): void
    {
        preg_match_all('/password=([^\s\'"]+)/i', $this->script(), $m);
        $this->assertSame([], array_values(array_diff(array_unique($m[1]), ['CAMBIAR'])), 'la conexión a db_cbsd se edita al ejecutar, no se versiona');
    }

    public function testLosScriptsAnterioresYaNoExisten(): void
    {
        foreach (['script.sql', 'script-2.sql', 'script_sbj_temp.sql'] as $f) {
            $this->assertFileDoesNotExist(dirname(__DIR__) . "/$f", "$f fue reemplazado por script-3.sql");
        }
    }
}
