<?php

use PHPUnit\Framework\TestCase;

/**
 * Administración > Parámetros: consulta, edición validada por tipo, historial y protección de los parámetros de
 * Administración. Usuarios 9551 (consulta y edita) y 9552 (solo consulta); parámetros PRUEBA_PARAM_*, borrados al terminar.
 */
final class ParametrosApiTest extends TestCase
{
    private const SECRETO = 'secreto-de-prueba-integracion-de-al-menos-32-caracteres';
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
        self::$pdo->exec("SET session_replication_role = replica;
            INSERT INTO admin.tb_usuarios (usuario_id, fk_persona_id, fk_perfil_id, usuario_login, usuario_pass) VALUES (9551, 1, 1, 'prueba.par', 'x'), (9552, 1, 1, 'prueba.par2', 'x');
            SET session_replication_role = origin;
            INSERT INTO admin.tb_params (param_key, param_value, param_type, param_name, param_modulo) VALUES
                ('PRUEBA_PARAM_LISTA', 'A|B', 'LISTA', 'Lista de prueba', 'PRUEBAS'),
                ('PRUEBA_PARAM_ADMIN', '1', 'LISTA', 'Protegido de prueba', 'ADMINISTRACION');
            INSERT INTO admin.tb_usuario_rol (fk_usuario_id, fk_rol_id) SELECT 9551, rol_id FROM admin.tb_roles WHERE rol_codigo IN ('SIS_PARAMETROS', 'SIS_PARAMETRO_EDITAR');
            INSERT INTO admin.tb_usuario_rol (fk_usuario_id, fk_rol_id) SELECT 9552, rol_id FROM admin.tb_roles WHERE rol_codigo = 'SIS_PARAMETROS';");

        $socket = stream_socket_server('tcp://127.0.0.1:0');
        self::$puerto = (int) substr(strrchr(stream_socket_get_name($socket, false), ':'), 1);
        fclose($socket);
        $env = array_merge(getenv(), [
            'BCBSD_JWT_SECRET' => self::SECRETO, 'BCBSD_DB_HOST' => $host, 'BCBSD_DB_PORT' => $port,
            'BCBSD_DB_NAME' => getenv('BCBSD_TEST_DB_NAME'), 'BCBSD_DB_USER' => getenv('BCBSD_TEST_DB_USER') ?: 'postgres',
            'BCBSD_DB_PASS' => getenv('BCBSD_TEST_DB_PASS') ?: '',
        ]);
        self::$servidor = proc_open([PHP_BINARY, '-S', '127.0.0.1:' . self::$puerto, '-t', dirname(__DIR__, 2)],
            [1 => ['file', '/dev/null', 'w'], 2 => ['file', sys_get_temp_dir() . '/bcbsd-api-parametros.log', 'w']], $pipes, dirname(__DIR__, 2), $env);
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
            DELETE FROM admin.tb_params_historial WHERE fk_param_id IN (SELECT param_id FROM admin.tb_params WHERE param_key LIKE 'PRUEBA\\_PARAM\\_%');
            DELETE FROM admin.tb_params WHERE param_key LIKE 'PRUEBA\\_PARAM\\_%';
            DELETE FROM admin.tb_usuario_rol WHERE fk_usuario_id IN (9551, 9552);
            DELETE FROM admin.tb_usuarios WHERE usuario_id IN (9551, 9552);");
    }

    protected function setUp(): void
    {
        if (!self::$pdo) {
            $this->markTestSkipped('Defina BCBSD_TEST_DB_NAME para ejecutar las pruebas de integración');
        }
    }

    private function api(string $metodo, string $ruta, $cuerpo = null, int $sub = 9551): array
    {
        $ctx = stream_context_create(['http' => ['method' => $metodo, 'ignore_errors' => true, 'timeout' => 30,
            'header' => 'Authorization: Bearer ' . jwtEmitir(['sub' => $sub, 'tipo' => 'usuario'], 600, self::SECRETO) . "\r\nContent-Type: application/json",
            'content' => $cuerpo === null ? '' : json_encode($cuerpo)]]);
        $texto = file_get_contents('http://127.0.0.1:' . self::$puerto . '/servicios/admin/' . $ruta, false, $ctx);
        return [(int) explode(' ', $http_response_header[0])[1], json_decode($texto, true), $texto];
    }

    private function id(string $clave): int
    {
        return (int) self::$pdo->query("SELECT param_id FROM admin.tb_params WHERE param_key = '$clave'")->fetchColumn();
    }

    public function testConsultaEdicionEHistorial(): void
    {
        [$st, $r, $t] = $this->api('GET', 'getParametros.php');
        $this->assertSame(200, $st, $t);
        $this->assertTrue($r['puede_editar']);
        $this->assertFalse($r['puede_editar_protegidos']);
        $this->assertArrayHasKey('SI_NO', $r['tipos']);
        $lista = array_values(array_filter($r['parametros'], fn($p) => $p['param_key'] === 'PRUEBA_PARAM_LISTA'))[0];
        $this->assertSame('LISTA', $lista['param_type']);
        $tipos = array_unique(array_column($r['parametros'], 'param_type'));
        $this->assertEmpty(array_diff($tipos, array_keys($r['tipos'])), 'todos los tipos están unificados');

        $id = $this->id('PRUEBA_PARAM_LISTA');
        [$st, $r, $t] = $this->api('PUT', 'setParametro.php', ['param_id' => $id, 'param_value' => [' A', 'C ', '']]);
        $this->assertSame(200, $st, $t);
        $this->assertSame('A|C', $r['param_value']);
        [$st, $r] = $this->api('PUT', 'setParametro.php', ['param_id' => $id, 'param_value' => 'A|a']);
        $this->assertSame(422, $st);
        $this->assertStringContainsString('repetido', $r['msg']);
        [$st, $r] = $this->api('PUT', 'setParametro.php', ['param_id' => $id, 'param_value' => 'A|C']);
        $this->assertSame('Sin cambios', $r['msg']);

        [$st, $h] = $this->api('GET', 'getParametros.php?historial=' . $id);
        $this->assertSame(200, $st);
        $this->assertCount(1, $h, 'solo el cambio real queda en el historial');
        $this->assertSame(['A|B', 'A|C', 'prueba.par'], [$h[0]['historial_valor_anterior'], $h[0]['historial_valor_nuevo'], $h[0]['usuario_login']]);
        $this->assertSame('9551', (string) self::$pdo->query("SELECT fk_usuario_actualiza FROM admin.tb_params WHERE param_id = $id")->fetchColumn());
    }

    public function testPrivilegiosYProtegidos(): void
    {
        $id = $this->id('PRUEBA_PARAM_LISTA');
        [$st, $r] = $this->api('GET', 'getParametros.php', null, 9552);
        $this->assertSame(200, $st);
        $this->assertFalse($r['puede_editar']);
        [$st] = $this->api('PUT', 'setParametro.php', ['param_id' => $id, 'param_value' => 'X'], 9552);
        $this->assertSame(403, $st, 'sin SIS_PARAMETRO_EDITAR');
        [$st, $r] = $this->api('PUT', 'setParametro.php', ['param_id' => $this->id('PRUEBA_PARAM_ADMIN'), 'param_value' => '9551']);
        $this->assertSame(403, $st, 'un usuario que no es administrador no se agrega como administrador');
        $this->assertStringContainsString('administrador', $r['msg']);
        [$st] = $this->api('PUT', 'setParametro.php', ['param_id' => 999999999, 'param_value' => 'X']);
        $this->assertSame(404, $st);
        [$st] = $this->api('GET', 'getParametros.php', null, 9553);
        $this->assertSame(403, $st);
    }
}
