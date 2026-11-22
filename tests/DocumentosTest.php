<?php

use PHPUnit\Framework\TestCase;

require_once __DIR__ . '/../classes/documentos.php';

final class DocumentosTest extends TestCase
{
    private const PDF = "%PDF-1.4\n1 0 obj << /Type /Catalog >> endobj\ntrailer << /Root 1 0 R >>\n%%EOF\n" . 'relleno para superar el tamaño mínimo del archivo de prueba...';

    protected function tearDown(): void
    {
        exec('rm -rf ' . escapeshellarg(DOCS_DIR));
    }

    private function tmp(string $contenido): string
    {
        $f = tempnam(sys_get_temp_dir(), 'pdf');
        file_put_contents($f, $contenido);
        return $f;
    }

    public function testNombre(): void
    {
        $this->assertSame('LIC-C1-1712345675.pdf', docNombre('licencias', ['c1', '1712345675']));
        $this->assertSame('LIC-E-1712345675.pdf', docNombre('licencias', [' E ', '1712345675']));
        $this->assertSame('CFA-1712345675-2301234569.pdf', docNombre('cargas-familiares', ['1712345675', '2301234569']));
        $this->assertSame('CUR-1712345675-PRIMEROS-AUXILIOS.pdf', docNombre('cursos', ['1712345675', 'primeros/auxilios']));
        $this->expectException(InvalidArgumentException::class);
        docNombre('otros', ['x']);
    }

    public function testRutaValida(): void
    {
        $this->assertTrue(docRutaValida('licencias/LIC-C-1712345675.pdf'));
        $this->assertTrue(docRutaValida('licencias/historico/LIC-C-1712345675_20261122-101010.pdf'));
        $this->assertFalse(docRutaValida('../classes/dbconfig.php'));
        $this->assertFalse(docRutaValida('licencias/../../etc/passwd.pdf'));
        $this->assertFalse(docRutaValida('/etc/LIC.pdf'));
        $this->assertFalse(docRutaValida('otros/LIC.pdf'));
        $this->assertFalse(docRutaValida('licencias/LIC.exe'));
        $this->assertFalse(docRutaValida(null));
    }

    public function testValidarPdf(): void
    {
        docValidarPdf(['error' => UPLOAD_ERR_OK, 'size' => strlen(self::PDF), 'tmp_name' => $this->tmp(self::PDF)], 5);
        $casos = [
            [null, 'Adjunte'],
            [['error' => UPLOAD_ERR_NO_FILE], 'Adjunte'],
            [['error' => UPLOAD_ERR_INI_SIZE], 'tamaño permitido'],
            [['error' => UPLOAD_ERR_PARTIAL], 'No se pudo recibir'],
            [['error' => UPLOAD_ERR_OK, 'size' => 6 * 1024 * 1024, 'tmp_name' => $this->tmp(self::PDF)], 'supera 5 MB'],
            [['error' => UPLOAD_ERR_OK, 'size' => 10, 'tmp_name' => $this->tmp('%PDF-')], 'vacío'],
            [['error' => UPLOAD_ERR_OK, 'size' => 200, 'tmp_name' => $this->tmp(str_repeat("\xFF\xD8\xFF imagen JPG ", 20))], 'debe ser un PDF'],
        ];
        foreach ($casos as [$archivo, $mensaje]) {
            try {
                docValidarPdf($archivo, 5);
                $this->fail("Se esperaba error: $mensaje");
            } catch (ValidacionException $e) {
                $this->assertStringContainsString($mensaje, $e->getMessage());
            }
        }
    }

    public function testGuardarConHistorico(): void
    {
        $mover = fn($de, $a) => rename($de, $a);
        $r1 = docGuardar($this->tmp(self::PDF . 'v1'), 'licencias', docNombre('licencias', ['B', '1712345675']), null, $mover);
        $this->assertSame('licencias/LIC-B-1712345675.pdf', $r1);
        $this->assertTrue(docExiste($r1));
        // renovación con otra categoría: el archivo anterior pasa al histórico
        $r2 = docGuardar($this->tmp(self::PDF . 'v2'), 'licencias', docNombre('licencias', ['C', '1712345675']), $r1, $mover);
        $this->assertSame('licencias/LIC-C-1712345675.pdf', $r2);
        $this->assertFalse(docExiste($r1));
        // misma categoría: el de igual nombre también pasa al histórico
        $r3 = docGuardar($this->tmp(self::PDF . 'v3'), 'licencias', docNombre('licencias', ['C', '1712345675']), $r2, $mover);
        $this->assertStringEndsWith('v3', file_get_contents(docRutaAbsoluta($r3)));
        $historico = glob(DOCS_DIR . '/historico/licencias/*.pdf');
        $this->assertCount(2, $historico);
        $this->assertMatchesRegularExpression('/LIC-B-1712345675_\d{8}-\d{6}\.pdf/', implode(' ', $historico));
        // otro reemplazo en el mismo segundo no pisa el histórico
        docGuardar($this->tmp(self::PDF . 'v4'), 'licencias', docNombre('licencias', ['C', '1712345675']), $r3, $mover);
        $this->assertCount(3, glob(DOCS_DIR . '/historico/licencias/*.pdf'));
    }
}
