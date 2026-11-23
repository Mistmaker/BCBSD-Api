<?php

use PHPUnit\Framework\TestCase;

require_once __DIR__ . '/../classes/usuarios.php';

final class UsuariosTest extends TestCase
{
    public function testClaveConPasswordHash(): void
    {
        $hash = usrHashClave('Bomberos2026');
        $this->assertStringStartsWith('$2y$', $hash);
        $this->assertSame([true, null], usrVerificarClave('Bomberos2026', $hash));
        $this->assertFalse(usrVerificarClave('bomberos2026', $hash)[0]);
        $this->assertFalse(usrVerificarClave('', $hash)[0]);
        $this->assertFalse(usrVerificarClave('x', null)[0]);
    }

    public function testClaveMd5HeredadaSeActualiza(): void
    {
        [$ok, $nuevo] = usrVerificarClave('clave123', md5('clave123'));
        $this->assertTrue($ok);
        $this->assertNotNull($nuevo);
        $this->assertTrue(password_verify('clave123', $nuevo));
        $this->assertSame([false, null], usrVerificarClave('otra', md5('clave123')));
        $this->assertTrue(usrVerificarClave('clave123', strtoupper(md5('clave123')))[0]);
    }

    public function testReglasDeClave(): void
    {
        $this->assertNull(usrErrorClave('Bomberos2026'));
        $this->assertStringContainsString('8 caracteres', usrErrorClave('Ab1'));
        $this->assertStringContainsString('letras y números', usrErrorClave('soloLetrasAqui'));
        $this->assertStringContainsString('letras y números', usrErrorClave('1234567890'));
        $this->assertStringContainsString('igual al usuario', usrErrorClave('dperez2026', 'DPerez2026'));
    }

    public function testLogin(): void
    {
        $this->assertSame('d.perez-1', usrNormalizarLogin(' D.Perez-1 '));
        $this->assertSame('1712345675', usrNormalizarLogin('1712345675'));
        foreach (['ab', 'josé', 'con espacio', str_repeat('a', 41), ''] as $malo) {
            try {
                usrNormalizarLogin($malo);
                $this->fail("Debió rechazar: $malo");
            } catch (ValidacionException $e) {
                $this->assertStringContainsString('3 a 40', $e->getMessage());
            }
        }
    }

    public function testMenuAgrupadoPorModulo(): void
    {
        $p = fn($id, $nombre, $ruta, $modulo, $mo, $grupo, $go, $ro, $menu = null, $tipo = 'GRUPO') => ['rol_id' => $id, 'rol_nombre' => $nombre,
            'rol_path' => $ruta, 'modulo_nombre' => $modulo, 'modulo_orden' => $mo, 'submodulo_nombre' => $grupo, 'submodulo_orden' => $go,
            'submodulo_menu' => $tipo, 'rol_orden' => $ro, 'rol_menu' => $menu];
        $menu = menuUsuario([
            $p(5, 'Usuarios', '/adm/usuarios', 'Administración', 90, 'Usuarios y perfiles', 100, 10),
            $p(6, 'Perfiles', '/adm/perfiles', 'Administración', 90, 'Usuarios y perfiles', 100, 20),
            $p(40, 'Resumen gerencial', '/admin/dashboard', 'Dir. Administrativa', 10, 'Panel', 10, 10, 'Panel', 'DIRECTO'),
            $p(2, 'Operadores', '/admin/operadores', 'Dir. Administrativa', 10, 'Parámetros', 20, 30),
            $p(9, 'Crear', null, 'Dir. Administrativa', 10, 'Parámetros', 20, 11),
            $p(1, 'Vehículos', '/admin/vehiculos', 'Dir. Administrativa', 10, 'Parámetros', 20, 10),
            $p(7, 'Órdenes de movilización', '/admin/ordenes-movilizacion', 'Dir. Administrativa', 10, 'Gestión', 30, 10),
        ]);
        // Módulos por orden; el Panel primero y sin carpeta; grupos con su orden; sin acciones
        $this->assertSame(['Dir. Administrativa', 'Administración'], array_column($menu, 'name'));
        $this->assertSame('/admin', $menu[0]['url']);
        $this->assertSame(['Panel', 'Parámetros', 'Órdenes de movilización'], array_column($menu[0]['children'], 'name'),
            'Gestión con una sola pantalla visible se muestra sin carpeta');
        $this->assertSame('/admin/dashboard', $menu[0]['children'][0]['url']);
        $this->assertSame(['Vehículos', 'Operadores'], array_column($menu[0]['children'][1]['children'], 'name'));
        // Módulo con un solo grupo: pantallas directas
        $this->assertSame(['Usuarios', 'Perfiles'], array_column($menu[1]['children'], 'name'));
        $this->assertArrayNotHasKey('children', $menu[1]['children'][0]);
        // Sin datos de orden (migración aún no ejecutada): sigue funcionando, por nombre de módulo y rol_id
        $simple = menuUsuario([['rol_id' => 2, 'rol_nombre' => 'B', 'rol_path' => '/x/b', 'modulo_nombre' => 'M'],
                               ['rol_id' => 1, 'rol_nombre' => 'A', 'rol_path' => '/x/a', 'modulo_nombre' => 'M']]);
        $this->assertSame(['A', 'B'], array_column($simple[0]['children'], 'name'));
    }
}
