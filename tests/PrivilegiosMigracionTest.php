<?php

use PHPUnit\Framework\TestCase;

/**
 * Todo privilegio que el API exige (requirePermiso / códigos de permiso en classes/) debe crearse en alguna migración
 * (admin.tb_roles con rol_codigo); si no, nadie podría asignarlo en Administración > Usuarios > Privilegios.
 * Ver la convención en CLAUDE.md ("Nuevas pantallas y privilegios").
 */
final class PrivilegiosMigracionTest extends TestCase
{
    public function testCadaPrivilegioExigidoSeCreaEnUnaMigracion(): void
    {
        $raiz = dirname(__DIR__);
        $codigos = [];
        $it = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($raiz . '/servicios', FilesystemIterator::SKIP_DOTS));
        foreach ($it as $f) {
            if ($f->getExtension() === 'php' && preg_match_all('/requirePermiso\([^)]*\)/', file_get_contents($f->getPathname()), $m)) {
                foreach ($m[0] as $llamada) {
                    preg_match_all("/'([A-Z][A-Z0-9_]+)'/", $llamada, $c);
                    $codigos = array_merge($codigos, $c[1]);
                }
            }
        }
        // Códigos devueltos por funciones (p. ej. mantPermisoOrden)
        foreach (glob($raiz . '/classes/*.php') as $f) {
            preg_match_all("/'((?:ADM|MANT|SBJ|OPE|TTHH)_[A-Z0-9_]+)'/", file_get_contents($f), $c);
            $codigos = array_merge($codigos, $c[1]);
        }
        $codigos = array_unique($codigos);
        $this->assertNotEmpty($codigos);

        $sql = '';
        foreach (new RecursiveIteratorIterator(new RecursiveDirectoryIterator($raiz . '/migrations', FilesystemIterator::SKIP_DOTS)) as $f) {
            if ($f->getExtension() === 'sql') {
                $sql .= file_get_contents($f->getPathname());
            }
        }
        $faltan = array_values(array_filter($codigos, fn($c) => !str_contains($sql, "'$c'")));
        $this->assertSame([], $faltan, 'Privilegios exigidos por el API sin INSERT en admin.tb_roles en migrations/: ' . implode(', ', $faltan));
    }
}
