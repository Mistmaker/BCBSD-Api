<?php

use PHPUnit\Framework\TestCase;

/**
 * Usuarios, perfiles y privilegios efectivos contra una base PostgreSQL real (mismas condiciones que MantenimientoApiTest).
 * Requiere migrations/admin/01-usuarios-perfiles.sql. Borra solo lo que crea (IDs 9401-9403 o fk_usuario_id 9401).
 */
final class UsuariosApiTest extends TestCase
{
    private const SECRETO = 'secreto-de-prueba-integracion-de-al-menos-32-caracteres';
    private const ADMIN = 9401;
    private const CED_NUEVA = '0900000019';
    private static ?PDO $pdo = null;
    /** @var resource|null */
    private static $servidor = null;
    private static int $puerto = 0;

    public static function setUpBeforeClass(): void
    {
        if (!getenv('BCBSD_TEST_DB_NAME')) {
            return;
        }
        $host = getenv('BCBSD_TEST_DB_HOST') ?: 'localhost';
        $port = getenv('BCBSD_TEST_DB_PORT') ?: '5432';
        self::$pdo = new PDO("pgsql:host=$host;port=$port;dbname=" . getenv('BCBSD_TEST_DB_NAME'),
            getenv('BCBSD_TEST_DB_USER') ?: 'postgres', getenv('BCBSD_TEST_DB_PASS') ?: '', [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);
        self::limpiar();
        $sinPerfil = (int) self::$pdo->query("SELECT perfil_id FROM admin.tb_perfiles WHERE perfil_nombre = 'SIN PERFIL'")->fetchColumn();
        $md5 = md5('Heredada2020');
        self::$pdo->exec("SET session_replication_role = replica;
            INSERT INTO resources.tb_personas (persona_id, persona_doc_identidad, persona_nombres, persona_apellidos)
                 VALUES (9401, 'ADM9401', 'ADMIN', 'PRUEBA'), (9402, 'HER9402', 'HEREDADO', 'PRUEBA'), (9403, 'INA9403', 'INACTIVO', 'PRUEBA');
            INSERT INTO admin.tb_usuarios (usuario_id, fk_persona_id, fk_perfil_id, usuario_login, usuario_pass, usuario_estado)
                 VALUES (9401, 9401, $sinPerfil, 'prueba.admin', '" . password_hash('Admin2026x', PASSWORD_DEFAULT) . "', 'ACTIVO'),
                        (9402, 9402, $sinPerfil, 'prueba.heredado', '$md5', 'ACTIVO'),
                        (9403, 9403, $sinPerfil, 'prueba.inactivo', '$md5', 'INACTIVO');
            SET session_replication_role = origin;
            INSERT INTO admin.tb_usuario_rol (fk_usuario_id, fk_rol_id) SELECT 9401, rol_id FROM admin.tb_roles WHERE rol_codigo LIKE 'SIS\\_%';");

        $socket = stream_socket_server('tcp://127.0.0.1:0');
        self::$puerto = (int) substr(strrchr(stream_socket_get_name($socket, false), ':'), 1);
        fclose($socket);
        $env = array_merge(getenv(), [
            'BCBSD_JWT_SECRET' => self::SECRETO, 'BCBSD_DB_HOST' => $host, 'BCBSD_DB_PORT' => $port,
            'BCBSD_DB_NAME' => getenv('BCBSD_TEST_DB_NAME'), 'BCBSD_DB_USER' => getenv('BCBSD_TEST_DB_USER') ?: 'postgres',
            'BCBSD_DB_PASS' => getenv('BCBSD_TEST_DB_PASS') ?: '',
        ]);
        self::$servidor = proc_open([PHP_BINARY, '-S', '127.0.0.1:' . self::$puerto, '-t', dirname(__DIR__, 2)],
            [1 => ['file', '/dev/null', 'w'], 2 => ['file', sys_get_temp_dir() . '/bcbsd-api-usuarios.log', 'w']], $pipes, dirname(__DIR__, 2), $env);
        for ($i = 0; $i < 50 && !@fsockopen('127.0.0.1', self::$puerto); $i++) {
            usleep(100000);
        }
    }

    public static function tearDownAfterClass(): void
    {
        if (self::$servidor) {
            proc_terminate(self::$servidor);
            proc_close(self::$servidor);
        }
        if (self::$pdo) {
            self::limpiar();
        }
    }

    private static function limpiar(): void
    {
        self::$pdo->exec("
            DELETE FROM admin.tb_usuario_rol WHERE fk_usuario_id IN (SELECT usuario_id FROM admin.tb_usuarios WHERE usuario_id BETWEEN 9401 AND 9403 OR fk_usuario_id = 9401);
            DELETE FROM admin.tb_usuarios WHERE usuario_id BETWEEN 9401 AND 9403 OR fk_usuario_id = 9401;
            DELETE FROM admin.tb_perfiles WHERE fk_usuario_id = 9401;
            DELETE FROM resources.tb_personas WHERE persona_id BETWEEN 9401 AND 9403 OR fk_usuario_id = 9401;");
    }

    protected function setUp(): void
    {
        if (!self::$pdo) {
            $this->markTestSkipped('Defina BCBSD_TEST_DB_NAME para ejecutar las pruebas de integración');
        }
    }

    private function api(string $metodo, string $ruta, $cuerpo = null, ?int $usuario = self::ADMIN): array
    {
        $cab = "Content-Type: application/json";
        if ($usuario !== null) {
            $cab = 'Authorization: Bearer ' . jwtEmitir(['sub' => $usuario, 'tipo' => 'usuario'], 600, self::SECRETO) . "\r\n$cab";
        }
        $ctx = stream_context_create(['http' => ['method' => $metodo, 'ignore_errors' => true, 'timeout' => 15, 'header' => $cab,
            'content' => $cuerpo === null ? '' : json_encode($cuerpo)]]);
        $texto = file_get_contents('http://127.0.0.1:' . self::$puerto . '/servicios/' . $ruta, false, $ctx);
        return [(int) explode(' ', $http_response_header[0])[1], json_decode($texto, true), $texto];
    }

    private function login(string $usuario, string $clave): array
    {
        return $this->api('POST', 'auth/login.php', ['usuario' => $usuario, 'password' => $clave], null);
    }

    private function rol(string $codigo): int
    {
        $st = self::$pdo->prepare('SELECT rol_id FROM admin.tb_roles WHERE rol_codigo = ?');
        $st->execute([$codigo]);
        return (int) $st->fetchColumn();
    }

    private function hash(int $usuario): string
    {
        return (string) self::$pdo->query("SELECT usuario_pass FROM admin.tb_usuarios WHERE usuario_id = $usuario")->fetchColumn();
    }

    public function testLogin(): void
    {
        // Clave MD5 heredada: entra y queda convertida a password_hash
        [$st, $r, $t] = $this->login('Prueba.Heredado', 'Heredada2020');
        $this->assertSame(200, $st, $t);
        $this->assertStringStartsWith('$2y$', $this->hash(9402));
        [$st] = $this->login('prueba.heredado', 'Heredada2020');
        $this->assertSame(200, $st);
        [$st] = $this->login('prueba.heredado', 'otra');
        $this->assertSame(401, $st);
        // Inactivo: no entra aunque la clave sea correcta
        [$st, $r] = $this->login('prueba.inactivo', 'Heredada2020');
        $this->assertSame(403, $st);
        $this->assertStringContainsString('inactivo', $r['msg']);
        $this->assertNotNull(self::$pdo->query('SELECT usuario_ultimo_acceso FROM admin.tb_usuarios WHERE usuario_id = 9402')->fetchColumn());
    }

    public function testListadoNoExponeClaves(): void
    {
        [$st, $lista, $t] = $this->api('GET', 'admin/getUsuarios.php');
        $this->assertSame(200, $st, $t);
        $this->assertStringNotContainsString('usuario_pass', $t);
        $this->assertStringNotContainsString('webmail', $t);
        $fila = array_values(array_filter($lista, fn($u) => $u['usuario_id'] === 9402))[0];
        $this->assertSame('HEREDADO', $fila['persona_nombres']);
        $this->assertSame('SIN PERFIL', $fila['perfil_nombre']);
        [, , $t] = $this->api('GET', 'auth/getUsuarios.php'); // ruta antigua: mismo listado seguro
        $this->assertStringNotContainsString('usuario_pass', $t);
        // Sin privilegio: 403
        [$st] = $this->api('GET', 'admin/getUsuarios.php', null, 9402);
        $this->assertSame(403, $st);
    }

    public function testPerfilUsuarioYPrivilegiosEfectivos(): void
    {
        $oper = $this->rol('ADM_OPERADORES');
        $bitacora = $this->rol('ADM_BITACORA_VEHICULOS');
        // 1. Perfil con una pantalla
        [$st, $r, $t] = $this->api('POST', 'admin/setPerfil.php', ['perfil_nombre' => ' prueba   perfil mantenimiento ', 'roles' => [$oper, 999999]]);
        $this->assertSame(201, $st, $t);
        $perfil = $r['id'];
        [$st, $r] = $this->api('POST', 'admin/setPerfil.php', ['perfil_nombre' => 'PRUEBA PERFIL MANTENIMIENTO']);
        $this->assertSame(422, $st);
        [, $p] = $this->api('GET', 'admin/getPerfiles.php?id=' . $perfil);
        $this->assertSame('PRUEBA PERFIL MANTENIMIENTO', $p['perfil_nombre']);
        $this->assertSame([$oper], $p['roles']); // el rol inexistente se descarta

        // 2. Usuario nuevo (persona externa nueva) con ese perfil
        $nuevo = ['persona_tipo_doc' => 'CEDULA', 'persona_doc_identidad' => self::CED_NUEVA, 'persona_nombres' => 'maría', 'persona_apellidos' => 'externa prueba',
                  'persona_correo' => 'maria@ejemplo.gob.ec', 'persona_celular' => '0991234567', 'usuario_login' => 'M.Externa', 'clave' => 'Inicial2026',
                  'fk_perfil_id' => $perfil];
        foreach ([[['clave' => 'corta'], '8 caracteres'], [['persona_doc_identidad' => '0900000010'], 'cédula'], [['persona_correo' => 'x@'], 'correo'],
                  [['usuario_login' => 'prueba.admin'], 'ya existe'], [['fk_perfil_id' => 0], 'perfil']] as [$cambio, $msg]) {
            [$st, $r] = $this->api('POST', 'admin/setUsuario.php', $cambio + $nuevo);
            $this->assertSame(422, $st, json_encode($r));
            $this->assertStringContainsString($msg, $r['msg']);
        }
        [$st, $r, $t] = $this->api('POST', 'admin/setUsuario.php', $nuevo);
        $this->assertSame(201, $st, $t);
        $usuario = $r['id'];
        [$st, $r] = $this->api('POST', 'admin/setUsuario.php', ['usuario_login' => 'otro.login'] + $nuevo);
        $this->assertSame(409, $st); // la persona ya tiene usuario
        $this->assertSame($usuario, $r['id']);
        [, $u] = $this->api('GET', 'admin/getUsuarios.php?id=' . $usuario);
        $this->assertSame('m.externa', $u['usuario_login']);
        $this->assertSame('MARÍA', $u['persona_nombres']);
        $this->assertFalse($u['es_funcionario']);
        $this->assertStringStartsWith('$2y$', $this->hash($usuario));

        // 3. Al entrar recibe los privilegios del perfil y debe cambiar la clave
        [$st, $l] = $this->login('m.externa', 'Inicial2026');
        $this->assertSame(200, $st);
        $this->assertContains('ADM_OPERADORES', $l['usuario']['permisos']);
        $this->assertTrue($l['usuario']['cambiar_clave']);
        $this->assertSame('/admin', $l['usuario']['menus'][0]['url']);

        // 4. Privilegio adicional; uno del perfil no se duplica como adicional
        [, $arbol] = $this->api('GET', 'auth/getPrivilegios.php?id=' . $usuario);
        $roles = array_merge(...array_map(fn($m) => array_merge(...array_column($m['submodulos'], 'roles')), $arbol));
        $this->assertTrue(array_values(array_filter($roles, fn($x) => $x['rol_id'] === $oper))[0]['del_perfil']);
        [$st] = $this->api('POST', 'auth/setPrivilegios.php', ['usuario_id' => $usuario, 'roles' => [$oper, $bitacora]]);
        $this->assertSame(200, $st);
        $this->assertSame([$bitacora], array_map('intval', self::$pdo->query("SELECT fk_rol_id FROM admin.tb_usuario_rol WHERE fk_usuario_id = $usuario")->fetchAll(PDO::FETCH_COLUMN)));
        [, $perm] = $this->api('GET', 'auth/getPermisos.php', null, $usuario);
        $this->assertEqualsCanonicalizing(['ADM_OPERADORES', 'ADM_BITACORA_VEHICULOS'], $perm['permisos']);

        // 5. Quitar la pantalla del perfil se refleja de inmediato en el usuario; el adicional se conserva
        [$st] = $this->api('PUT', 'admin/setPerfil.php', ['perfil_id' => $perfil, 'perfil_nombre' => 'PRUEBA PERFIL MANTENIMIENTO', 'roles' => []]);
        $this->assertSame(200, $st);
        [, $perm] = $this->api('GET', 'auth/getPermisos.php', null, $usuario);
        $this->assertSame(['ADM_BITACORA_VEHICULOS'], $perm['permisos']);
        // Perfil o usuario inactivo: sin privilegios
        [$st] = $this->api('PUT', 'admin/setUsuario.php', ['usuario_id' => $usuario, 'usuario_login' => 'm.externa', 'fk_perfil_id' => $perfil, 'usuario_estado' => 'INACTIVO',
                                                            'persona_correo' => 'maria@ejemplo.gob.ec']);
        $this->assertSame(200, $st);
        [, $perm] = $this->api('GET', 'auth/getPermisos.php', null, $usuario);
        $this->assertSame([], $perm['permisos']);
        [$st] = $this->login('m.externa', 'Inicial2026');
        $this->assertSame(403, $st);

        // 6. Escalada de privilegios cerrada: un usuario sin SIS_USUARIO_PRIVILEGIOS no puede darse privilegios
        [$st] = $this->api('POST', 'auth/setPrivilegios.php', ['usuario_id' => 9402, 'roles' => [$this->rol('SIS_USUARIO_PRIVILEGIOS')]], 9402);
        $this->assertSame(403, $st);

        // 7. Clave: el administrador la restablece; el usuario cambia la suya con la actual
        [$st] = $this->api('POST', 'admin/setClaveUsuario.php', ['usuario_id' => 9402, 'clave' => 'Nueva2026x']);
        $this->assertSame(200, $st);
        $this->assertTrue((bool) self::$pdo->query('SELECT usuario_cambiar_pass FROM admin.tb_usuarios WHERE usuario_id = 9402')->fetchColumn());
        [$st, $r] = $this->api('POST', 'admin/setClaveUsuario.php', ['clave_actual' => 'mal', 'clave' => 'Propia2026x'], 9402);
        $this->assertSame(422, $st);
        [$st] = $this->api('POST', 'admin/setClaveUsuario.php', ['clave_actual' => 'Nueva2026x', 'clave' => 'Propia2026x'], 9402);
        $this->assertSame(200, $st);
        [$st, $l] = $this->login('prueba.heredado', 'Propia2026x');
        $this->assertSame(200, $st);
        $this->assertFalse($l['usuario']['cambiar_clave']);
        [$st] = $this->api('POST', 'admin/setClaveUsuario.php', ['usuario_id' => self::ADMIN, 'clave' => 'Robada2026x'], 9402); // ajena sin privilegio
        $this->assertSame(403, $st);
    }

    public function testNoSePuedeBloquearASiMismo(): void
    {
        [$st, $r] = $this->api('PUT', 'admin/setUsuario.php', ['usuario_id' => self::ADMIN, 'usuario_login' => 'prueba.admin', 'usuario_estado' => 'INACTIVO',
            'fk_perfil_id' => (int) self::$pdo->query("SELECT perfil_id FROM admin.tb_perfiles WHERE perfil_nombre = 'SIN PERFIL'")->fetchColumn()]);
        $this->assertSame(422, $st);
        $this->assertStringContainsString('propio usuario', $r['msg']);
        [$st, $r] = $this->api('POST', 'auth/setPrivilegios.php', ['usuario_id' => self::ADMIN, 'roles' => [$this->rol('SIS_USUARIOS')]]);
        $this->assertSame(422, $st);
        $this->assertStringContainsString('a sí mismo', $r['msg']);
        $this->assertSame(5, (int) self::$pdo->query('SELECT count(*) FROM admin.tb_usuario_rol WHERE fk_usuario_id = 9401')->fetchColumn()); // sin cambios
    }
}
