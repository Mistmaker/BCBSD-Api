<?php

use PHPUnit\Framework\TestCase;

/** script-3.sql se genera desde migrations/: esta prueba avisa si quedó desactualizado. */
final class Script3Test extends TestCase
{
    public function testScript3EstaActualizado(): void
    {
        $raiz = dirname(__DIR__);
        $actual = file_get_contents("$raiz/script-3.sql");
        exec('python3 ' . escapeshellarg("$raiz/migrations/generar-script-3.py") . ' 2>&1', $salida, $codigo);
        if ($codigo !== 0) {
            $this->markTestSkipped('python3 no disponible: ' . implode("\n", $salida));
        }
        $generado = file_get_contents("$raiz/script-3.sql");
        $this->assertSame($generado, $actual, 'script-3.sql no coincide con migrations/: ejecute python3 migrations/generar-script-3.py');
    }

    public function testNoUsaComandosDePsqlNiTocaEstaciones(): void
    {
        $sql = file_get_contents(dirname(__DIR__) . '/script-3.sql');
        $this->assertDoesNotMatchRegularExpression('/^\\\\/m', $sql, 'Debe poder pegarse en pgAdmin (sin comandos \\set de psql)');
        $this->assertStringNotContainsString(":'legacy_conn'", $sql);
        // Estaciones: la base nueva las crea, pero el script nunca modifica, borra ni agrega filas si ya existen
        $this->assertDoesNotMatchRegularExpression('/(DROP\s+TABLE|TRUNCATE|DELETE\s+FROM|UPDATE)\s+(IF\s+EXISTS\s+)?operaciones\.tb_estaciones\b/i', $sql);
        $inicio = strpos($sql, 'IF NOT EXISTS (SELECT 1 FROM operaciones.tb_estaciones) THEN');
        $this->assertNotFalse($inicio, 'las estaciones iniciales solo se cargan si la tabla está vacía');
        $bloque = substr($sql, $inicio, strpos($sql, 'END IF;', $inicio) - $inicio);
        $this->assertSame(substr_count($sql, 'INSERT INTO operaciones.tb_estaciones'), substr_count($bloque, 'INSERT INTO operaciones.tb_estaciones'));
        $this->assertDoesNotMatchRegularExpression('/DROP\s+TABLE/i', $sql, 'No debe borrar tablas');
    }
}
