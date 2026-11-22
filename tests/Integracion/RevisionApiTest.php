<?php

use PHPUnit\Framework\TestCase;

/**
 * Revisión final: resumen gerencial y eliminaciones que el front ya usaba pero no existían en el API.
 * Mismas condiciones que MantenimientoApiTest. IDs 9701-9799, borrados al terminar.
 */
final class RevisionApiTest extends TestCase
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
            INSERT INTO admin.tb_usuarios (usuario_id, fk_persona_id, fk_perfil_id, usuario_login, usuario_pass) VALUES (9701, 1, 1, 'prueba.rev', 'x'), (9702, 1, 1, 'prueba.rev2', 'x');
            INSERT INTO subjefatura.tb_voluntarios (voluntario_id, voluntario_tipo_doc, voluntario_doc_identidad, voluntario_nombres, voluntario_apellidos)
                 VALUES (9701, 'CEDULA', 'V9701', 'ANA', 'VOLUNTARIA'), (9702, 'CEDULA', 'V9702', 'LUIS', 'VOLUNTARIO');
            INSERT INTO subjefatura.tb_voluntarios_actividades (actividad_id, fk_voluntario_id, actividad_actividad, actividad_descripcion, actividad_fecha_inicio)
                 VALUES (9701, 9701, 'GUARDIA', 'Prueba', now()), (9702, 9702, 'GUARDIA', 'Prueba', now());
            INSERT INTO archivo.documentos (documento_id, documento_numero_documento, documento_numero_folio, documento_fecha_documento, documento_remitente,
                 documento_destinatario, documento_asunto, documento_archivo_escaneado, documento_ubicacion_fisica, documento_anio)
                 VALUES (9701, 'DOC-9701', '1', now(), 'A', 'B', 'Prueba', 'x.pdf', 'Estante 1', 2026);
            SET session_replication_role = origin;
            INSERT INTO admin.tb_usuario_rol (fk_usuario_id, fk_rol_id) SELECT 9701, rol_id FROM admin.tb_roles
             WHERE rol_codigo IN ('ADM_DASHBOARD', 'SBJ_VOLUNTARIOS', 'SBJ_UBV_ACTIVIDADES');");

        $socket = stream_socket_server('tcp://127.0.0.1:0');
        self::$puerto = (int) substr(strrchr(stream_socket_get_name($socket, false), ':'), 1);
        fclose($socket);
        $env = array_merge(getenv(), [
            'BCBSD_JWT_SECRET' => self::SECRETO, 'BCBSD_DB_HOST' => $host, 'BCBSD_DB_PORT' => $port,
            'BCBSD_DB_NAME' => getenv('BCBSD_TEST_DB_NAME'), 'BCBSD_DB_USER' => getenv('BCBSD_TEST_DB_USER') ?: 'postgres',
            'BCBSD_DB_PASS' => getenv('BCBSD_TEST_DB_PASS') ?: '',
        ]);
        self::$servidor = proc_open([PHP_BINARY, '-S', '127.0.0.1:' . self::$puerto, '-t', dirname(__DIR__, 2)],
            [1 => ['file', '/dev/null', 'w'], 2 => ['file', sys_get_temp_dir() . '/bcbsd-api-revision.log', 'w']], $pipes, dirname(__DIR__, 2), $env);
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
            DELETE FROM subjefatura.tb_voluntarios_actividades WHERE actividad_id IN (9701, 9702);
            DELETE FROM subjefatura.tb_voluntarios WHERE voluntario_id IN (9701, 9702);
            DELETE FROM archivo.documentos WHERE documento_id = 9701;
            DELETE FROM admin.tb_usuario_rol WHERE fk_usuario_id IN (9701, 9702);
            DELETE FROM admin.tb_usuarios WHERE usuario_id IN (9701, 9702);");
    }

    protected function setUp(): void
    {
        if (!self::$pdo) {
            $this->markTestSkipped('Defina BCBSD_TEST_DB_NAME para ejecutar las pruebas de integración');
        }
    }

    private function api(string $metodo, string $ruta, int $sub = 9701, string $tipo = 'usuario'): array
    {
        $ctx = stream_context_create(['http' => ['method' => $metodo, 'ignore_errors' => true, 'timeout' => 60,
            'header' => 'Authorization: Bearer ' . jwtEmitir(['sub' => $sub, 'tipo' => $tipo], 600, self::SECRETO)]]);
        $texto = file_get_contents('http://127.0.0.1:' . self::$puerto . '/servicios/' . $ruta, false, $ctx);
        return [(int) explode(' ', $http_response_header[0])[1], json_decode($texto, true), $texto];
    }

    private function estado(string $tabla, string $col, string $colId, int $id): ?string
    {
        return self::$pdo->query("SELECT $col FROM $tabla WHERE $colId = $id")->fetchColumn() ?: null;
    }

    public function testResumenGerencial(): void
    {
        [$st, $r, $t] = $this->api('GET', 'administrativo/getResumenGerencial.php?mes=2026-11');
        $this->assertSame(200, $st, $t);
        foreach (['flota', 'gasto', 'contratos', 'alertas', 'licencias', 'peticiones'] as $clave) {
            $this->assertArrayHasKey($clave, $r);
        }
        $this->assertCount(12, $r['gasto']['meses']);
        $this->assertSame('2026-11', end($r['gasto']['meses'])['mes']);
        $this->assertSame('2025-12', $r['gasto']['meses'][0]['mes']);
        $this->assertGreaterThanOrEqual(0, $r['flota']['activos']);
        [$st] = $this->api('GET', 'administrativo/getResumenGerencial.php?mes=2026-13');
        $this->assertSame(400, $st);
        [$st] = $this->api('GET', 'administrativo/getResumenGerencial.php', 9702); // sin ADM_DASHBOARD
        $this->assertSame(403, $st);
    }

    public function testEliminacionesLogicas(): void
    {
        // Un voluntario solo elimina sus propias actividades
        [$st] = $this->api('DELETE', 'subjefatura/ubv/deleteActividad.php?id=9702', 9701, 'voluntario');
        $this->assertSame(404, $st);
        $this->assertNotSame('ELIMINADA', $this->estado('subjefatura.tb_voluntarios_actividades', 'actividad_estado', 'actividad_id', 9702));
        [$st] = $this->api('DELETE', 'subjefatura/ubv/deleteActividad.php?id=9701', 9701, 'voluntario');
        $this->assertSame(200, $st);
        $this->assertSame('ELIMINADA', $this->estado('subjefatura.tb_voluntarios_actividades', 'actividad_estado', 'actividad_id', 9701));
        // ya no aparece en el listado; eliminar dos veces -> 404
        [, $lista] = $this->api('GET', 'subjefatura/ubv/getActividades.php');
        $this->assertNotContains(9701, array_map('intval', array_column($lista, 'actividad_id')));
        [$st] = $this->api('DELETE', 'subjefatura/ubv/deleteActividad.php?id=9701', 9701, 'voluntario');
        $this->assertSame(404, $st);
        // Usuario administrativo: con privilegio elimina cualquiera; sin privilegio, 403
        [$st] = $this->api('DELETE', 'subjefatura/ubv/deleteActividad.php?id=9702', 9702);
        $this->assertSame(403, $st);
        [$st] = $this->api('DELETE', 'subjefatura/ubv/deleteActividad.php?id=9702');
        $this->assertSame(200, $st);
        // Voluntario (registro conservado con estado ELIMINADO)
        [$st] = $this->api('DELETE', 'subjefatura/ubv/deleteVoluntario.php?id=9702');
        $this->assertSame(200, $st);
        $this->assertSame('ELIMINADO', $this->estado('subjefatura.tb_voluntarios', 'voluntario_estado', 'voluntario_id', 9702));
        // Documento de archivo: queda quién y cuándo
        [$st] = $this->api('DELETE', 'archivo/deleteDocumento.php?id=9701', 9701, 'voluntario');
        $this->assertSame(403, $st);
        [$st] = $this->api('DELETE', 'archivo/deleteDocumento.php?id=9701');
        $this->assertSame(200, $st);
        $this->assertSame('ELIMINADO', $this->estado('archivo.documentos', 'documento_estado', 'documento_id', 9701));
        $this->assertSame('9701', (string) $this->estado('archivo.documentos', 'documento_eliminado_por', 'documento_id', 9701));
        // Método incorrecto
        [$st] = $this->api('GET', 'archivo/deleteDocumento.php?id=9701');
        $this->assertSame(405, $st);
    }
}
