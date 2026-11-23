<?php

use PHPUnit\Framework\TestCase;

/** Los privilegios iniciales no deben depender de un usuario_id fijo: se usa admin.fn_es_administrador (parámetro SIS_ADMINISTRADORES). */
final class AdministradoresMigracionTest extends TestCase
{
    public function testSinUsuarioFijoEnLasMigraciones(): void
    {
        foreach (glob(dirname(__DIR__) . '/migrations/*/*.sql') as $archivo) {
            $sql = file_get_contents($archivo);
            $this->assertDoesNotMatchRegularExpression('/usuario_id\s*(=|IN\s*\()\s*\d+/i', $sql, basename($archivo) . ': use admin.fn_es_administrador()');
            $this->assertDoesNotMatchRegularExpression("/perfil_nombre\)\)\s*=\s*'ADMINISTRADOR'/i", $sql, basename($archivo) . ': use admin.fn_perfil_es_administrador()');
        }
    }

    public function testAccesoDeAdministradoresAlFinalDelScript(): void
    {
        $script = file_get_contents(dirname(__DIR__) . '/script-3.sql');
        $funcion = strpos($script, 'CREATE OR REPLACE FUNCTION admin.fn_es_administrador');
        $acceso = strpos($script, 'ACCESO DE LOS ADMINISTRADORES');
        $this->assertNotFalse($funcion);
        $this->assertNotFalse($acceso);
        $this->assertLessThan(strpos($script, 'admin.fn_es_administrador(u.usuario_id)'), $funcion, 'la función se crea antes de usarse');
        // Títulos de sección: línea '-- N. TÍTULO' justo después de una línea de '='
        preg_match_all('/^-- =+\n-- (\d+)\. (.+)$/m', $script, $m);
        $this->assertStringStartsWith('ACCESO DE LOS ADMINISTRADORES', end($m[2]), 'el acceso de administradores es la última sección');
    }
}
