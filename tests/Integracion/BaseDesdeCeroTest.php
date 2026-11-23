<?php

use PHPUnit\Framework\TestCase;

/**
 * script-3.sql crea la base completa desde cero y se puede ejecutar de nuevo sin errores ni duplicados.
 * Crea una base temporal en el mismo servidor de pruebas y la elimina al terminar.
 */
final class BaseDesdeCeroTest extends TestCase
{
    public function testCreaLaBaseDesdeCeroYEsReejecutable(): void
    {
        if (!getenv('BCBSD_TEST_DB_NAME')) {
            $this->markTestSkipped('Defina BCBSD_TEST_DB_NAME para ejecutar las pruebas de integración');
        }
        $dsn = fn(string $db) => 'pgsql:host=' . (getenv('BCBSD_TEST_DB_HOST') ?: 'localhost') . ';port=' . (getenv('BCBSD_TEST_DB_PORT') ?: '5432') . ";dbname=$db";
        $usuario = getenv('BCBSD_TEST_DB_USER') ?: 'postgres';
        $clave = getenv('BCBSD_TEST_DB_PASS') ?: '';
        $admin = new PDO($dsn('postgres'), $usuario, $clave, [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);
        $nombre = 'bcbsd_prueba_cero_' . getmypid();
        $admin->exec("DROP DATABASE IF EXISTS $nombre");
        $admin->exec("CREATE DATABASE $nombre TEMPLATE template0");
        try {
            $db = new PDO($dsn($nombre), $usuario, $clave, [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);
            $script = file_get_contents(dirname(__DIR__, 2) . '/script-3.sql');
            $conteo = fn() => $db->query("SELECT (SELECT count(*) FROM information_schema.tables WHERE table_schema NOT IN ('pg_catalog', 'information_schema')),
                                                 (SELECT count(*) FROM admin.tb_roles), (SELECT count(*) FROM operaciones.tb_estaciones),
                                                 (SELECT count(*) FROM subjefatura.tb_causas), (SELECT count(*) FROM admin.tb_usuarios),
                                                 (SELECT count(*) FROM operaciones.tb_partes_catalogo_tipos_auxilio)")->fetch(PDO::FETCH_NUM);
            $db->exec($script);
            $primera = $conteo();
            $db->exec($script);
            $this->assertSame($primera, $conteo(), 'la segunda ejecución no agrega ni duplica nada');
            $this->assertGreaterThanOrEqual(100, (int) $primera[0], 'tablas y vistas');
            $this->assertSame(1, (int) $primera[4], 'usuario admin inicial');
            $privilegios = $db->query("SELECT count(DISTINCT v.rol_id) = (SELECT count(*) FROM admin.tb_roles r WHERE r.rol_estado IS DISTINCT FROM 'INACTIVO')
                                         FROM admin.tb_usuarios u JOIN admin.vw_usuario_privilegios v ON v.usuario_id = u.usuario_id
                                        WHERE u.usuario_login = 'admin'")->fetchColumn();
            $this->assertTrue((bool) $privilegios, 'el admin inicial tiene todos los privilegios');
            $db = null;
        } finally {
            $admin->exec("SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$nombre' AND pid <> pg_backend_pid()");
            $admin->exec("DROP DATABASE IF EXISTS $nombre");
        }
    }
}
