<?php

use PHPUnit\Framework\TestCase;

/**
 * Operadores contra una base PostgreSQL real (mismas condiciones que MantenimientoApiTest).
 * Requiere migrations/operadores/01-operadores.sql. Usa cédulas de prueba; al terminar borra solo lo creado por la prueba (ID 9301 o fk_usuario_id 9301).
 */
final class OperadoresApiTest extends TestCase
{
    private const SECRETO = 'secreto-de-prueba-integracion-de-al-menos-32-caracteres';
    private const CED_NUEVA = '1712345675';     // persona inexistente
    private const CED_FUNCIONARIO = '2301234569'; // persona que ya es funcionario con puesto
    private static ?PDO $pdo = null;
    /** @var resource|null */
    private static $servidor = null;
    private static int $puerto = 0;
    private static int $puesto = 0;
    private static string $docs = '';
    private const PDF = "%PDF-1.4\n1 0 obj << /Type /Catalog >> endobj\ntrailer << /Root 1 0 R >>\n%%EOF\nLicencia de prueba escaneada............................";

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
        self::$puesto = (int) self::$pdo->query('SELECT min(puesto_id) FROM tthh.tb_puestos')->fetchColumn();
        self::$pdo->exec("SET session_replication_role = replica;
            INSERT INTO admin.tb_usuarios (usuario_id, fk_persona_id, fk_perfil_id, usuario_login, usuario_pass) VALUES (9301, 1, 1, 'prueba_oper', 'x'), (9302, 1, 1, 'prueba_oper2', 'x');
            INSERT INTO resources.tb_personas (persona_id, persona_doc_identidad, persona_nombres, persona_apellidos) VALUES (9301, '" . self::CED_FUNCIONARIO . "', 'DIEGO', 'PRUEBA ADMINISTRATIVO');
            INSERT INTO tthh.tb_personal (personal_id, fk_persona_id) VALUES (9301, 9301);
            INSERT INTO tthh.tb_personal_puestos (ppersonal_id, fk_personal_id, fk_puesto_id) VALUES (9301, 9301, " . self::$puesto . ");
            SET session_replication_role = origin;
            INSERT INTO admin.tb_usuario_rol (fk_usuario_id, fk_rol_id) SELECT 9301, rol_id FROM admin.tb_roles WHERE rol_codigo IN ('ADM_OPERADORES', 'ADM_OPERADOR_GESTIONAR', 'ADM_MOVILIZACION_CREAR');
            INSERT INTO admin.tb_usuario_rol (fk_usuario_id, fk_rol_id) SELECT 9302, rol_id FROM admin.tb_roles WHERE rol_codigo = 'ADM_OPERADORES';");

        $socket = stream_socket_server('tcp://127.0.0.1:0');
        self::$puerto = (int) substr(strrchr(stream_socket_get_name($socket, false), ':'), 1);
        fclose($socket);
        self::$docs = sys_get_temp_dir() . '/bcbsd-docs-integracion-' . getmypid();
        $env = array_merge(getenv(), [
            'BCBSD_DOCS_DIR' => self::$docs,
            'BCBSD_JWT_SECRET' => self::SECRETO, 'BCBSD_DB_HOST' => $host, 'BCBSD_DB_PORT' => $port,
            'BCBSD_DB_NAME' => getenv('BCBSD_TEST_DB_NAME'), 'BCBSD_DB_USER' => getenv('BCBSD_TEST_DB_USER') ?: 'postgres',
            'BCBSD_DB_PASS' => getenv('BCBSD_TEST_DB_PASS') ?: '',
        ]);
        self::$servidor = proc_open([PHP_BINARY, '-S', '127.0.0.1:' . self::$puerto, '-t', dirname(__DIR__, 2)],
            [1 => ['file', '/dev/null', 'w'], 2 => ['file', sys_get_temp_dir() . '/bcbsd-api-operadores.log', 'w']], $pipes, dirname(__DIR__, 2), $env);
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
        if (self::$docs) {
            exec('rm -rf ' . escapeshellarg(self::$docs));
        }
    }

    /** Borra solo lo que creó la prueba: filas con ID 9301 o registradas por el usuario de prueba (fk_usuario_id = 9301). */
    private static function limpiar(): void
    {
        self::$pdo->exec("
            DELETE FROM tthh.tb_conductores WHERE fk_usuario_id = 9301 OR fk_personal_id = 9301;
            DELETE FROM tthh.tb_personal_puestos WHERE fk_usuario_id = 9301 OR ppersonal_id = 9301;
            DELETE FROM tthh.tb_personal WHERE fk_usuario_id = 9301 OR personal_id = 9301;
            DELETE FROM resources.tb_personas WHERE fk_usuario_id = 9301 OR persona_id = 9301;
            DELETE FROM admin.tb_usuario_rol WHERE fk_usuario_id BETWEEN 9301 AND 9399;
            DELETE FROM admin.tb_usuarios WHERE usuario_id BETWEEN 9301 AND 9399;");
    }

    protected function setUp(): void
    {
        if (!self::$pdo) {
            $this->markTestSkipped('Defina BCBSD_TEST_DB_NAME para ejecutar las pruebas de integración');
        }
    }

    private function api(string $metodo, string $ruta, $cuerpo = null, int $usuario = 9301): array
    {
        $token = jwtEmitir(['sub' => $usuario, 'tipo' => 'usuario'], 600, self::SECRETO);
        $ctx = stream_context_create(['http' => [
            'method' => $metodo, 'ignore_errors' => true, 'timeout' => 15,
            'header' => "Authorization: Bearer $token\r\nContent-Type: application/json",
            'content' => $cuerpo === null ? '' : json_encode($cuerpo),
        ]]);
        $texto = file_get_contents('http://127.0.0.1:' . self::$puerto . '/servicios/' . $ruta, false, $ctx);
        return [(int) explode(' ', $http_response_header[0])[1], json_decode($texto, true), $texto];
    }

    /** POST multipart: 'datos' (JSON) y opcionalmente 'licencia_pdf' */
    private function multipart(string $ruta, array $datos, ?string $pdf = null, string $nombre = 'licencia.pdf', int $usuario = 9301): array
    {
        $limite = '----bcbsd' . bin2hex(random_bytes(8));
        $cuerpo = "--$limite\r\nContent-Disposition: form-data; name=\"datos\"\r\n\r\n" . json_encode($datos) . "\r\n";
        if ($pdf !== null) {
            $cuerpo .= "--$limite\r\nContent-Disposition: form-data; name=\"licencia_pdf\"; filename=\"$nombre\"\r\nContent-Type: application/pdf\r\n\r\n$pdf\r\n";
        }
        $cuerpo .= "--$limite--\r\n";
        $token = jwtEmitir(['sub' => $usuario, 'tipo' => 'usuario'], 600, self::SECRETO);
        $ctx = stream_context_create(['http' => ['method' => 'POST', 'ignore_errors' => true, 'timeout' => 15,
            'header' => "Authorization: Bearer $token\r\nContent-Type: multipart/form-data; boundary=$limite", 'content' => $cuerpo]]);
        $texto = file_get_contents('http://127.0.0.1:' . self::$puerto . '/servicios/' . $ruta, false, $ctx);
        return [(int) explode(' ', $http_response_header[0])[1], json_decode($texto, true), $texto, $http_response_header];
    }

    private function licencia(string $categoria): int
    {
        $st = self::$pdo->prepare('SELECT licencia_id FROM resources.tb_licenciasdeconducir WHERE licencia_categoria = ? ORDER BY licencia_id LIMIT 1');
        $st->execute([$categoria]);
        return (int) $st->fetchColumn();
    }

    public function testIngresoRapidoYEdicionDeLicencia(): void
    {
        $base = 'administrativo/operadores/';
        [$st, $cat] = $this->api('GET', $base . 'getCatalogosOperador.php');
        $this->assertSame(200, $st);
        $this->assertNotEmpty($cat['licencias']);
        $this->assertNotEmpty($cat['puestos']);

        // 1. Funcionario administrativo existente: solo falta la licencia
        [$st, $b] = $this->api('GET', $base . 'getPersonaOperador.php?cedula=' . self::CED_FUNCIONARIO);
        $this->assertSame(200, $st);
        $this->assertTrue($b['cedula_valida']);
        $this->assertSame('PRUEBA ADMINISTRATIVO', $b['persona']['persona_apellidos']);
        $this->assertNotNull($b['persona']['ppersonal_id']);
        $this->assertNull($b['operador']);
        $licencia = ['fk_licencia_id' => $this->licencia('C'), 'conductor_licencia_emision' => '2024-01-10', 'conductor_licencia_validez' => '2029-01-10'];
        // el PDF de la licencia es obligatorio y debe ser un PDF
        [$st, $r] = $this->multipart($base . 'setOperador.php', ['persona_doc_identidad' => self::CED_FUNCIONARIO] + $licencia);
        $this->assertSame(422, $st);
        $this->assertStringContainsString('PDF', $r['msg']);
        [$st, $r] = $this->multipart($base . 'setOperador.php', ['persona_doc_identidad' => self::CED_FUNCIONARIO] + $licencia, str_repeat("\xFF\xD8 jpg ", 30), 'foto.pdf');
        $this->assertSame(422, $st);
        $this->assertStringContainsString('debe ser un PDF', $r['msg']);
        [$st, $r, $t] = $this->multipart($base . 'setOperador.php', ['persona_doc_identidad' => self::CED_FUNCIONARIO] + $licencia, self::PDF, 'escaneo licencia.pdf');
        $this->assertSame(201, $st, $t);
        $id = $r['id'];
        $this->assertSame('licencias/LIC-C-' . self::CED_FUNCIONARIO . '.pdf', $r['conductor_pdf']);
        $this->assertFileExists(self::$docs . '/licencias/LIC-C-' . self::CED_FUNCIONARIO . '.pdf');
        // descarga solo por el API
        [$st, , $pdf] = $this->api('GET', $base . 'getLicenciaPdf.php?id=' . $id);
        $this->assertSame(200, $st);
        $this->assertSame(self::PDF, $pdf);
        // no duplica: 409 con el id existente
        [$st, $r] = $this->multipart($base . 'setOperador.php', ['persona_doc_identidad' => self::CED_FUNCIONARIO] + $licencia, self::PDF);
        $this->assertSame(409, $st);
        $this->assertSame($id, $r['id']);

        // 2. Persona nueva: crea persona, personal y puesto; exige el puesto
        $nuevo = ['persona_doc_identidad' => self::CED_NUEVA, 'persona_nombres' => ' juan  carlos ', 'persona_apellidos' => 'operador prueba'] + $licencia;
        [$st, $r] = $this->multipart($base . 'setOperador.php', $nuevo, self::PDF);
        $this->assertSame(422, $st);
        $this->assertStringContainsString('puesto', $r['msg']);
        [$st, $r, $t] = $this->multipart($base . 'setOperador.php', $nuevo + ['fk_puesto_id' => self::$puesto], self::PDF);
        $this->assertSame(201, $st, $t);
        [$st, $o] = $this->api('GET', $base . 'getOperadores.php?id=' . $r['id']);
        $this->assertSame('JUAN CARLOS', $o['persona_nombres']);
        $this->assertSame('OPERADOR PRUEBA', $o['persona_apellidos']);
        $this->assertSame('VIGENTE', $o['licencia_vigencia']);
        $this->assertTrue($o['habilitado']);
        $this->assertTrue($o['tiene_sustento']);

        // 3. Validaciones
        foreach ([
            [['persona_doc_identidad' => '1712345670'] + $licencia, 'cédula'],
            [['persona_doc_identidad' => self::CED_NUEVA, 'conductor_licencia_validez' => '2023-01-01'] + $licencia, 'posterior'],
            [['persona_doc_identidad' => self::CED_NUEVA, 'conductor_licencia_emision' => date('Y-m-d', strtotime('+2 days')), 'conductor_licencia_validez' => '2035-01-01'] + $licencia, 'futura'],
            [['persona_doc_identidad' => self::CED_NUEVA, 'fk_licencia_id' => null] + $licencia, 'licencia'],
        ] as [$cuerpo, $texto]) {
            [$st, $r] = $this->api('POST', $base . 'setOperador.php', $cuerpo);
            $this->assertSame(422, $st, json_encode($r));
            $this->assertStringContainsString($texto, $r['msg']);
        }

        // 4. Cambiar la licencia exige un PDF nuevo; solo el estado, no
        $vencida = ['conductor_id' => $id, 'fk_licencia_id' => $this->licencia('B'), 'conductor_licencia_emision' => '2019-01-10', 'conductor_licencia_validez' => '2024-01-10'];
        [$st, $r] = $this->api('PUT', $base . 'setOperador.php', $vencida);
        $this->assertSame(422, $st);
        $this->assertStringContainsString('PDF', $r['msg']);
        [$st, $r, $t] = $this->api('PUT', $base . 'setOperador.php', ['conductor_id' => $id, 'conductor_estado' => 'ACTIVO'] + $licencia);
        $this->assertSame(200, $st, $t);
        // Licencia vencida (con su PDF): el selector lo muestra deshabilitado y movilización no lo acepta; el PDF anterior va al histórico
        [$st, $r, $t] = $this->multipart($base . 'setOperador.php', $vencida, self::PDF . 'B');
        $this->assertSame(200, $st, $t);
        $this->assertSame('licencias/LIC-B-' . self::CED_FUNCIONARIO . '.pdf', $r['conductor_pdf']);
        $this->assertFileDoesNotExist(self::$docs . '/licencias/LIC-C-' . self::CED_FUNCIONARIO . '.pdf');
        $this->assertCount(1, glob(self::$docs . '/historico/licencias/LIC-C-' . self::CED_FUNCIONARIO . '_*.pdf'));
        [, $o] = $this->api('GET', $base . 'getOperadores.php?id=' . $id);
        $this->assertSame('VENCIDA', $o['licencia_vigencia']);
        $this->assertSame('B', $o['licencia_categoria']);
        [, $conductores] = $this->api('GET', 'tthh/getConductores.php');
        $fila = array_values(array_filter($conductores, fn($c) => $c['conductor_id'] === $id))[0];
        $this->assertTrue($fila['disabled']);
        $this->assertStringContainsString('LICENCIA VENCIDA', $fila['nombre_completo']);
        $this->assertStringContainsString('Lic. B', $fila['nombre_completo']);
        [$st, $r] = $this->api('POST', 'administrativo/serv-generales/setOrden.php', ['fk_unidad_id' => 1, 'operador_id' => $id]);
        $this->assertSame(422, $st, json_encode($r));
        $this->assertStringContainsString('venció', $r['msg']);

        // 5. Renovada (POST con conductor_id y PDF): vuelve a estar habilitada
        [$st, , $t] = $this->multipart($base . 'setOperador.php', ['conductor_id' => $id] + $licencia, self::PDF);
        $this->assertSame(200, $st, $t);
        [, $conductores] = $this->api('GET', 'tthh/getConductores.php');
        $fila = array_values(array_filter($conductores, fn($c) => $c['conductor_id'] === $id))[0];
        $this->assertFalse($fila['disabled']);
    }

    public function testPermisos(): void
    {
        $base = 'administrativo/operadores/';
        [$st] = $this->api('GET', $base . 'getOperadores.php', null, 9302); // solo consulta
        $this->assertSame(200, $st);
        [$st] = $this->api('POST', $base . 'setOperador.php', ['persona_doc_identidad' => self::CED_NUEVA, 'fk_licencia_id' => 1,
            'conductor_licencia_emision' => '2024-01-01', 'conductor_licencia_validez' => '2029-01-01'], 9302);
        $this->assertSame(403, $st);
        [$st] = $this->api('GET', $base . 'getPersonaOperador.php');
        $this->assertSame(400, $st);
    }
}
