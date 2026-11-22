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
        $menu = menuUsuario([
            ['rol_id' => 5, 'rol_nombre' => 'Usuarios', 'rol_path' => '/adm/usuarios', 'modulo_nombre' => 'Administración'],
            ['rol_id' => 2, 'rol_nombre' => 'Operadores', 'rol_path' => '/admin/operadores', 'modulo_nombre' => 'Dir. Administrativa'],
            ['rol_id' => 9, 'rol_nombre' => 'Crear', 'rol_path' => null, 'modulo_nombre' => 'Dir. Administrativa'],
            ['rol_id' => 1, 'rol_nombre' => 'Vehículos', 'rol_path' => '/admin/vehiculos', 'modulo_nombre' => 'Dir. Administrativa'],
        ]);
        $this->assertSame(['Administración', 'Dir. Administrativa'], array_column($menu, 'name'));
        $this->assertSame('/adm', $menu[0]['url']);
        $this->assertSame(['Vehículos', 'Operadores'], array_column($menu[1]['children'], 'name')); // sin acciones, por rol_id
    }
}
