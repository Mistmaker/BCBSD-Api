<?php

use PHPUnit\Framework\TestCase;

/**
 * Códigos con secuencia anual en órdenes de combustible (misma función que movilización: classes/codigos.php).
 * Mismas condiciones que MantenimientoApiTest. Datos de prueba con IDs 9601-9699, borrados al terminar.
 */
final class CodigosApiTest extends TestCase
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
        $aa = date('y');
        $ant = date('y', strtotime('-1 year'));
        $orden = fn($id, $v, $codigo, $serie, $registro) => "($id, 9601, $v, '$codigo', $serie, $serie, 9601, 'TST', '$registro')";
        self::$pdo->exec("SET session_replication_role = replica;
            INSERT INTO admin.tb_usuarios (usuario_id, fk_persona_id, fk_perfil_id, usuario_login, usuario_pass) VALUES (9601, 1, 1, 'prueba.codigos', 'x'), (9602, 1, 1, 'prueba.codigos2', 'x');
            INSERT INTO tthh.tb_direcciones (direccion_id, direccion_codigo, direccion_nombre) VALUES (9601, 'TSTA', 'PRUEBA A'), (9602, 'TSTB', 'PRUEBA B');
            INSERT INTO administrativo.tb_vehiculos (vehiculo_id, fk_usuario_id, fk_marca_id, vehiculo_placa, vehiculo_tipo, vehiculo_combustible, vehiculo_sigla, fk_direccion_id, custodio_id)
                 VALUES (9601, 9601, 1, 'TST-9601', 'CAMIONETA', 'DIESEL', 'COD-A', 9601, 1), (9602, 9601, 1, 'TST-9602', 'CAMIONETA', 'DIESEL', 'COD-B', 9602, 1);
            INSERT INTO logistica.tb_ordenesabastecimiento (orden_id, fk_usuario_id, fk_unidad_id, orden_codigo, orden_codigo_serie, orden_serie, personal_solicita,
                 orden_codigo_institucion, orden_registro) VALUES " . implode(',', [
                $orden(9601, 9601, "BCBSD{$aa}ABASTSTA00007", 7, date('Y-m-d H:i:s')),             // año actual, prefijo antiguo
                $orden(9602, 9601, "CBSD{$ant}ABASTSTA00050", 50, date('Y-m-d', strtotime('-1 year'))), // año anterior: no cuenta
                $orden(9603, 9602, "CBSD{$ant}ABASTSTB00030", 30, date('Y-m-d', strtotime('-1 year'))), // TSTB solo tiene el año anterior
            ]) . ";
            SET session_replication_role = origin;
            INSERT INTO admin.tb_usuario_rol (fk_usuario_id, fk_rol_id) SELECT 9601, rol_id FROM admin.tb_roles WHERE rol_codigo IN ('ADM_COMBUSTIBLE', 'ADM_COMBUSTIBLE_CREAR');
            INSERT INTO admin.tb_usuario_rol (fk_usuario_id, fk_rol_id) SELECT 9602, rol_id FROM admin.tb_roles WHERE rol_codigo = 'ADM_COMBUSTIBLE';");

        $socket = stream_socket_server('tcp://127.0.0.1:0');
        self::$puerto = (int) substr(strrchr(stream_socket_get_name($socket, false), ':'), 1);
        fclose($socket);
        $env = array_merge(getenv(), [
            'BCBSD_JWT_SECRET' => self::SECRETO, 'BCBSD_DB_HOST' => $host, 'BCBSD_DB_PORT' => $port,
            'BCBSD_DB_NAME' => getenv('BCBSD_TEST_DB_NAME'), 'BCBSD_DB_USER' => getenv('BCBSD_TEST_DB_USER') ?: 'postgres',
            'BCBSD_DB_PASS' => getenv('BCBSD_TEST_DB_PASS') ?: '',
        ]);
        self::$servidor = proc_open([PHP_BINARY, '-S', '127.0.0.1:' . self::$puerto, '-t', dirname(__DIR__, 2)],
            [1 => ['file', '/dev/null', 'w'], 2 => ['file', sys_get_temp_dir() . '/bcbsd-api-codigos.log', 'w']], $pipes, dirname(__DIR__, 2), $env);
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
            DELETE FROM logistica.tb_ordenesabastecimiento WHERE fk_unidad_id IN (9601, 9602) OR orden_id BETWEEN 9601 AND 9699;
            DELETE FROM administrativo.tb_vehiculos WHERE vehiculo_id IN (9601, 9602);
            DELETE FROM tthh.tb_direcciones WHERE direccion_id IN (9601, 9602);
            DELETE FROM admin.tb_usuario_rol WHERE fk_usuario_id IN (9601, 9602);
            DELETE FROM admin.tb_usuarios WHERE usuario_id IN (9601, 9602);");
    }

    protected function setUp(): void
    {
        if (!self::$pdo) {
            $this->markTestSkipped('Defina BCBSD_TEST_DB_NAME para ejecutar las pruebas de integración');
        }
    }

    private function crear(int $vehiculo, int $vales, int $usuario = 9601): array
    {
        $ctx = stream_context_create(['http' => ['method' => 'POST', 'ignore_errors' => true, 'timeout' => 15,
            'header' => 'Authorization: Bearer ' . jwtEmitir(['sub' => $usuario, 'tipo' => 'usuario'], 600, self::SECRETO) . "\r\nContent-Type: application/json",
            'content' => json_encode(['fk_unidad_id' => $vehiculo, 'orden_nro_vales' => $vales, 'personal_solicita' => 1, 'orden_codigo_institucion' => 'TST'])]]);
        $texto = file_get_contents('http://127.0.0.1:' . self::$puerto . '/servicios/administrativo/ordenes-abastecimiento/setOrdenAbastecimiento.php', false, $ctx);
        return [(int) explode(' ', $http_response_header[0])[1], $texto];
    }

    private function codigos(int $vehiculo): array
    {
        return self::$pdo->query("SELECT orden_codigo FROM logistica.tb_ordenesabastecimiento WHERE fk_unidad_id = $vehiculo
                                   AND orden_id NOT BETWEEN 9601 AND 9699 ORDER BY orden_id")->fetchAll(PDO::FETCH_COLUMN);
    }

    public function testSecuenciaAnualConSiglasDeLaInstitucion(): void
    {
        $siglas = strtoupper(preg_replace('/[^A-Za-z0-9]/', '', (string) self::$pdo->query('SELECT sistema_siglas FROM admin.tb_sistema LIMIT 1')->fetchColumn())) ?: 'CBSD';
        $aa = date('y');
        // Continúa la secuencia del año (7, aunque el prefijo anterior fuera BCBSD) e ignora el año pasado (50); dos vales seguidos
        [$st, $t] = $this->crear(9601, 2);
        $this->assertSame(201, $st, $t);
        $this->assertSame(["{$siglas}{$aa}COMTSTA00008", "{$siglas}{$aa}COMTSTA00009"], $this->codigos(9601));
        // Origen que solo tiene órdenes del año anterior: reinicia en 1
        [$st] = $this->crear(9602, 1);
        $this->assertSame(201, $st);
        $this->assertSame(["{$siglas}{$aa}COMTSTB00001"], $this->codigos(9602));
    }

    public function testEmitirExigePrivilegio(): void
    {
        [$st] = $this->crear(9602, 1, 9602); // solo acceso a la pantalla
        $this->assertSame(403, $st);
    }
}
