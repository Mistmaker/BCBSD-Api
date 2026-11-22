<?php

use PHPUnit\Framework\TestCase;

/**
 * Petición de materiales contra una base PostgreSQL real (mismas condiciones que MantenimientoApiTest).
 * Requiere migrations/servicios-generales/01-peticion-materiales.sql. Usa los años 2031/2032 para no chocar con datos reales
 * y borra solo lo que crea (IDs 9501-9502 y peticiones del usuario 9501).
 */
final class PeticionMaterialesApiTest extends TestCase
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
        $puesto = (int) self::$pdo->query('SELECT min(puesto_id) FROM tthh.tb_puestos')->fetchColumn();
        self::$pdo->exec("SET session_replication_role = replica;
            INSERT INTO resources.tb_personas (persona_id, persona_doc_identidad, persona_nombres, persona_apellidos) VALUES (9501, 'PDM9501', 'ANA', 'SOLICITANTE PRUEBA');
            INSERT INTO tthh.tb_personal (personal_id, fk_persona_id) VALUES (9501, 9501);
            INSERT INTO tthh.tb_personal_puestos (ppersonal_id, fk_personal_id, fk_puesto_id) VALUES (9501, 9501, $puesto);
            INSERT INTO admin.tb_usuarios (usuario_id, fk_persona_id, fk_perfil_id, usuario_login, usuario_pass) VALUES (9501, 9501, 1, 'prueba.pdm', 'x'), (9502, 9501, 1, 'prueba.pdm2', 'x');
            SET session_replication_role = origin;
            INSERT INTO admin.tb_usuario_rol (fk_usuario_id, fk_rol_id) SELECT 9501, rol_id FROM admin.tb_roles WHERE rol_codigo IN ('ADM_PETICIONES_MATERIALES', 'ADM_PETICION_MATERIALES_GESTIONAR');
            INSERT INTO admin.tb_usuario_rol (fk_usuario_id, fk_rol_id) SELECT 9502, rol_id FROM admin.tb_roles WHERE rol_codigo = 'ADM_PETICIONES_MATERIALES';");

        $socket = stream_socket_server('tcp://127.0.0.1:0');
        self::$puerto = (int) substr(strrchr(stream_socket_get_name($socket, false), ':'), 1);
        fclose($socket);
        $env = array_merge(getenv(), [
            'BCBSD_JWT_SECRET' => self::SECRETO, 'BCBSD_DB_HOST' => $host, 'BCBSD_DB_PORT' => $port,
            'BCBSD_DB_NAME' => getenv('BCBSD_TEST_DB_NAME'), 'BCBSD_DB_USER' => getenv('BCBSD_TEST_DB_USER') ?: 'postgres',
            'BCBSD_DB_PASS' => getenv('BCBSD_TEST_DB_PASS') ?: '',
        ]);
        self::$servidor = proc_open([PHP_BINARY, '-S', '127.0.0.1:' . self::$puerto, '-t', dirname(__DIR__, 2)],
            [1 => ['file', '/dev/null', 'w'], 2 => ['file', sys_get_temp_dir() . '/bcbsd-api-pdm.log', 'w']], $pipes, dirname(__DIR__, 2), $env);
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
            DELETE FROM logistica.tb_peticionesmateriales WHERE fk_usuario_id = 9501;
            DELETE FROM admin.tb_usuario_rol WHERE fk_usuario_id IN (9501, 9502);
            DELETE FROM admin.tb_usuarios WHERE usuario_id IN (9501, 9502);
            DELETE FROM tthh.tb_personal_puestos WHERE ppersonal_id = 9501;
            DELETE FROM tthh.tb_personal WHERE personal_id = 9501;
            DELETE FROM resources.tb_personas WHERE persona_id = 9501;");
    }

    protected function setUp(): void
    {
        if (!self::$pdo) {
            $this->markTestSkipped('Defina BCBSD_TEST_DB_NAME para ejecutar las pruebas de integración');
        }
    }

    private function api(string $metodo, string $ruta, $cuerpo = null, int $usuario = 9501): array
    {
        $ctx = stream_context_create(['http' => ['method' => $metodo, 'ignore_errors' => true, 'timeout' => 30,
            'header' => 'Authorization: Bearer ' . jwtEmitir(['sub' => $usuario, 'tipo' => 'usuario'], 600, self::SECRETO) . "\r\nContent-Type: application/json",
            'content' => $cuerpo === null ? '' : json_encode($cuerpo)]]);
        $texto = file_get_contents('http://127.0.0.1:' . self::$puerto . '/' . $ruta, false, $ctx);
        return [(int) explode(' ', $http_response_header[0])[1], json_decode($texto, true), $texto, $http_response_header];
    }

    private function peticion(string $fecha, array $extra = []): array
    {
        return $extra + ['peticion_fecha' => $fecha, 'peticion_lugar' => 'Santo Domingo', 'peticion_destino' => 'Mantenimiento de la estación central',
            'peticion_autorizado_para' => 'BODEGA', 'solicitante_id' => 9501, 'solicitante_cargo' => 'ANALISTA DE SERVICIOS GENERALES',
            'autoriza_id' => 9501, 'autoriza_cargo' => 'DIRECTOR ADMINISTRATIVO',
            'detalle' => [['detalle_cantidad' => 3, 'detalle_unidad' => 'caja', 'detalle_descripcion' => 'Guantes de nitrilo talla M'],
                          ['detalle_cantidad' => 2.5, 'detalle_unidad' => 'GALÓN', 'detalle_descripcion' => 'Pintura de caucho blanca']]];
    }

    public function testFlujoCompleto(): void
    {
        $base = 'servicios/administrativo/serv-generales/';
        [$st, $cfg] = $this->api('GET', $base . 'getPeticionesMateriales.php?config=1');
        $this->assertSame(200, $st);
        $this->assertContains('CAJA', $cfg['unidades']);
        $this->assertArrayHasKey('ciudad', $cfg);

        // Numeración por año: 2031 -> 1, 2; 2032 vuelve a 1
        [$st, $r1, $t] = $this->api('POST', $base . 'setPeticionMateriales.php', $this->peticion('2031-01-15'));
        $this->assertSame(201, $st, $t);
        $this->assertMatchesRegularExpression('/^[A-Z]+31PDM00001$/', $r1['peticion_codigo']);
        [, $r2] = $this->api('POST', $base . 'setPeticionMateriales.php', $this->peticion('2031-02-01'));
        $this->assertMatchesRegularExpression('/31PDM00002$/', $r2['peticion_codigo']);
        [, $r3] = $this->api('POST', $base . 'setPeticionMateriales.php', $this->peticion('2032-01-02'));
        $this->assertMatchesRegularExpression('/32PDM00001$/', $r3['peticion_codigo']);

        // Consulta con ítems en orden
        [$st, $p] = $this->api('GET', $base . 'getPeticionesMateriales.php?id=' . $r1['id']);
        $this->assertSame(200, $st);
        $this->assertStringContainsString('SOLICITANTE PRUEBA', $p['solicitante_nombre']);
        $this->assertSame('BODEGA', $p['peticion_autorizado_para']);
        $this->assertSame(['CAJA', 'GALÓN'], array_column($p['detalle'], 'detalle_unidad'));
        $this->assertEquals(2.5, $p['detalle'][1]['detalle_cantidad']);
        [, $lista] = $this->api('GET', $base . 'getPeticionesMateriales.php?anio=2031');
        $this->assertSame([$r2['id'], $r1['id']], array_column($lista, 'peticion_id')); // más reciente primero

        // Edición: reemplaza los ítems y conserva el código
        [$st, $r] = $this->api('PUT', $base . 'setPeticionMateriales.php', $this->peticion('2031-01-15', ['peticion_id' => $r1['id'],
            'detalle' => [['detalle_cantidad' => 10, 'detalle_unidad' => 'resma', 'detalle_descripcion' => 'Papel bond A4']]]));
        $this->assertSame(200, $st);
        $this->assertSame($r1['peticion_codigo'], $r['peticion_codigo']);
        [, $p] = $this->api('GET', $base . 'getPeticionesMateriales.php?id=' . $r1['id']);
        $this->assertSame(1, $p['items']);

        // PDF
        [$st, , $pdf, $cab] = $this->api('GET', 'reportes/servicios-generales/peticionMateriales.php?id=' . $r1['id']);
        $this->assertSame(200, $st);
        $this->assertStringStartsWith('%PDF', $pdf);
        $this->assertStringContainsString($r1['peticion_codigo'], implode("\n", $cab));

        // Anulación: exige motivo; anulada no se edita
        [$st, $r] = $this->api('PUT', $base . 'setPeticionMateriales.php', ['peticion_id' => $r2['id'], 'peticion_estado' => 'ANULADA']);
        $this->assertSame(422, $st);
        [$st] = $this->api('PUT', $base . 'setPeticionMateriales.php', ['peticion_id' => $r2['id'], 'peticion_estado' => 'ANULADA', 'peticion_observaciones' => 'Duplicada']);
        $this->assertSame(200, $st);
        [$st, $r] = $this->api('PUT', $base . 'setPeticionMateriales.php', $this->peticion('2031-02-01', ['peticion_id' => $r2['id']]));
        $this->assertSame(422, $st);
        $this->assertStringContainsString('anulada', $r['msg']);
        [$st] = $this->api('PUT', $base . 'setPeticionMateriales.php', ['peticion_id' => $r2['id'], 'peticion_estado' => 'ANULADA', 'peticion_observaciones' => 'Otra vez']);
        $this->assertSame(404, $st);
    }

    public function testValidacionesYPermisos(): void
    {
        $base = 'servicios/administrativo/serv-generales/';
        [$st, $r] = $this->api('POST', $base . 'setPeticionMateriales.php', $this->peticion('2031-03-01', ['detalle' => []]));
        $this->assertSame(422, $st);
        $this->assertStringContainsString('al menos un material', $r['msg']);
        // Solo consulta: puede ver e imprimir, no registrar
        [$st] = $this->api('GET', $base . 'getPeticionesMateriales.php', null, 9502);
        $this->assertSame(200, $st);
        [$st] = $this->api('POST', $base . 'setPeticionMateriales.php', $this->peticion('2031-03-01'), 9502);
        $this->assertSame(403, $st);
    }
}
