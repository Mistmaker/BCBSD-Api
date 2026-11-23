<?php

use PHPUnit\Framework\TestCase;

/**
 * Partes de servicio: registro con numeración por estación y año, validaciones, edición, anulación y estadística.
 * Mismas condiciones que MantenimientoApiTest. IDs 9801-9899 (estación T-98), borrados al terminar.
 */
final class PartesApiTest extends TestCase
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
            INSERT INTO admin.tb_usuarios (usuario_id, fk_persona_id, fk_perfil_id, usuario_login, usuario_pass)
                 VALUES (9801, 1, 1, 'prueba.partes1', 'x'), (9802, 1, 1, 'prueba.partes2', 'x'), (9803, 1, 1, 'prueba.partes3', 'x');
            INSERT INTO operaciones.tb_estaciones (estacion_id, estacion_nombre) VALUES (9801, 'T-98');
            INSERT INTO tthh.tb_personal (personal_id, fk_persona_id, fk_estacion_id) VALUES (9801, 1, 9801), (9802, 1, 9801), (9803, 1, 9801);
            INSERT INTO administrativo.tb_vehiculos (vehiculo_id, fk_usuario_id, fk_marca_id, vehiculo_placa, vehiculo_sigla, vehiculo_tipo, vehiculo_combustible, vehiculo_estado, fk_estacion_id)
                 VALUES (9801, 1, 1, 'PRB-9801', 'R-98', 'AUTOBOMBA', 'DIESEL', 'ACTIVO', 9801), (9802, 1, 1, 'PRB-9802', 'A-98', 'AMBULANCIA', 'DIESEL', 'ACTIVO', 9801);
            SET session_replication_role = origin;
            INSERT INTO admin.tb_usuario_rol (fk_usuario_id, fk_rol_id) SELECT 9801, rol_id FROM admin.tb_roles
             WHERE rol_codigo IN ('OPE_PARTES', 'OPE_PARTE_REGISTRAR', 'OPE_PARTE_ANULAR', 'OPE_PARTES_ESTADISTICAS', 'ADM_BITACORA_VEHICULOS');
            INSERT INTO admin.tb_usuario_rol (fk_usuario_id, fk_rol_id) SELECT 9802, rol_id FROM admin.tb_roles
             WHERE rol_codigo IN ('OPE_PARTES', 'OPE_PARTE_REGISTRAR');
            INSERT INTO admin.tb_usuario_rol (fk_usuario_id, fk_rol_id) SELECT 9803, rol_id FROM admin.tb_roles WHERE rol_codigo = 'OPE_PARTES';");

        $socket = stream_socket_server('tcp://127.0.0.1:0');
        self::$puerto = (int) substr(strrchr(stream_socket_get_name($socket, false), ':'), 1);
        fclose($socket);
        $env = array_merge(getenv(), [
            'BCBSD_JWT_SECRET' => self::SECRETO, 'BCBSD_DB_HOST' => $host, 'BCBSD_DB_PORT' => $port,
            'BCBSD_DB_NAME' => getenv('BCBSD_TEST_DB_NAME'), 'BCBSD_DB_USER' => getenv('BCBSD_TEST_DB_USER') ?: 'postgres',
            'BCBSD_DB_PASS' => getenv('BCBSD_TEST_DB_PASS') ?: '',
        ]);
        self::$servidor = proc_open([PHP_BINARY, '-S', '127.0.0.1:' . self::$puerto, '-t', dirname(__DIR__, 2)],
            [1 => ['file', '/dev/null', 'w'], 2 => ['file', sys_get_temp_dir() . '/bcbsd-api-partes.log', 'w']], $pipes, dirname(__DIR__, 2), $env);
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
            DELETE FROM operaciones.tb_partes WHERE fk_estacion_id = 9801;
            DELETE FROM operaciones.tb_partes_catalogo_recursos WHERE recurso_descripcion LIKE 'PRUEBA %';
            DELETE FROM administrativo.tb_vehiculos WHERE vehiculo_id IN (9801, 9802);
            DELETE FROM tthh.tb_personal WHERE personal_id IN (9801, 9802, 9803);
            DELETE FROM operaciones.tb_estaciones WHERE estacion_id = 9801;
            DELETE FROM admin.tb_usuario_rol WHERE fk_usuario_id IN (9801, 9802, 9803);
            DELETE FROM admin.tb_usuarios WHERE usuario_id IN (9801, 9802, 9803);");
    }

    protected function setUp(): void
    {
        if (!self::$pdo) {
            $this->markTestSkipped('Defina BCBSD_TEST_DB_NAME para ejecutar las pruebas de integración');
        }
    }

    private function api(string $metodo, string $ruta, $cuerpo = null, int $usuario = 9801): array
    {
        $ctx = stream_context_create(['http' => [
            'method' => $metodo, 'ignore_errors' => true, 'timeout' => 30,
            'header' => 'Authorization: Bearer ' . jwtEmitir(['sub' => $usuario, 'tipo' => 'usuario'], 600, self::SECRETO) . "\r\nContent-Type: application/json",
            'content' => $cuerpo === null ? '' : json_encode($cuerpo),
        ]]);
        $texto = file_get_contents('http://127.0.0.1:' . self::$puerto . '/servicios/' . $ruta, false, $ctx);
        return [(int) explode(' ', $http_response_header[0])[1], json_decode($texto, true), $texto];
    }

    private function parte(array $cambios = []): array
    {
        return array_merge([
            'parte_tipo' => 'AUXILIO', 'parte_fecha' => '2025-03-10', 'fk_estacion_id' => 9801, 'parte_hora_aviso' => '22:05',
            'parte_tipo_dia' => 'LABORABLE', 'parte_forma_aviso' => 'Cabina de radio', 'parte_calle_principal' => 'Av. Del Cooperativismo',
            'parte_calle_secundaria' => 'Sin nombre', 'parte_descripcion_operaciones' => "A nuestra llegada...\nSe evacuó el menaje.",
            'personal' => [
                ['fk_personal_id' => 9801, 'parte_personal_rol' => 'PERSONA AL MANDO DE LA EMERGENCIA', 'parte_personal_rango' => 'Bro. V.', 'parte_personal_grupo' => 'Pelotón 1'],
                ['fk_personal_id' => 9802, 'parte_personal_rol' => 'PERSONAL OPERATIVO', 'parte_personal_rango' => 'Bro. 2', 'parte_personal_grupo' => 'Pelotón 1'],
                ['fk_personal_id' => null, 'parte_personal_rol' => '', 'parte_personal_rango' => '', 'parte_personal_grupo' => ''], // fila vacía: se ignora
            ],
            'vehiculos' => [[
                'fk_vehiculo_id' => 9801, 'parte_vehiculo_km_salida' => 23337, 'parte_vehiculo_km_retorno' => 23343,
                'parte_vehiculo_hora_despacho' => '2025-03-10T22:10', 'parte_vehiculo_hora_salida' => '2025-03-10T22:14',
                'parte_vehiculo_hora_arribo' => '2025-03-10T22:20', 'parte_vehiculo_hora_fin_operaciones' => '2025-03-10T23:20',
                'parte_vehiculo_apoyo' => 'Apoyo interno',
            ]],
            'tipos_auxilio' => [['parte_auxilio_clave' => '10-1', 'parte_auxilio_clasificacion' => 'Auxilio', 'parte_auxilio_subclasificacion' => 'Evacuación',
                'parte_auxilio_uso_tipo' => 'Menaje + personas']],
            'causas' => [['parte_causa_clave' => '10-1', 'parte_causa_clasificacion' => 'Materiales peligrosos (MATPEL)', 'parte_causa_descripcion' => 'Negligencia']],
            'equipos_herramientas' => [['fk_estacion_id' => 9801, 'parte_recurso_descripcion' => 'Prueba EPP estructural', 'parte_recurso_cantidad' => 2]],
            'materiales_descartables' => [], 'insumos' => [],
            'victimas' => [['parte_victima_nombres' => 'Cordoba Jessica', 'parte_victima_edad' => 35, 'parte_victima_tipo_edad' => 'años', 'parte_victima_sexo' => 'F']],
            'fallecidos' => [['parte_fallecido_tipo_edad' => 'años']], // solo el valor por defecto: fila vacía
        ], $cambios);
    }

    public function testRegistroNumeracionYDetalles(): void
    {
        [$st] = $this->api('POST', 'operaciones/setParte.php', $this->parte(), 9803); // sin OPE_PARTE_REGISTRAR
        $this->assertSame(403, $st);

        [$st, $r, $t] = $this->api('POST', 'operaciones/setParte.php', $this->parte());
        $this->assertSame(201, $st, $t);
        $this->assertMatchesRegularExpression('/^[A-Z0-9]+-PA-T98-2025-0001$/', $r['parte_numero']);
        $id = $r['id'];

        [$st, $p, $t] = $this->api('GET', "operaciones/getPartes.php?id=$id");
        $this->assertSame(200, $st, $t);
        $this->assertSame(9801, (int) $p['fk_personal_id'], 'la persona al mando queda en la cabecera');
        $this->assertSame('22:14:00', $p['parte_hora_salida']);
        $this->assertSame('22:20:00', $p['parte_hora_arribo']);
        $this->assertSame('Av. Del Cooperativismo y Sin nombre', $p['parte_direccion']);
        $this->assertCount(2, $p['personal']);
        $this->assertSame('PRB-9801', $p['vehiculos'][0]['parte_vehiculo_placa'], 'placa tomada del registro del vehículo');
        $this->assertSame('R-98', $p['vehiculos'][0]['parte_vehiculo_siglas']);
        $this->assertSame('2025-03-10T22:20', $p['vehiculos'][0]['parte_vehiculo_hora_arribo']);
        $this->assertNotNull($p['tipos_auxilio'][0]['fk_tipo_auxilio_id'], 'tipo de auxilio enlazado al catálogo');
        $this->assertNotNull($p['causas'][0]['fk_causa_id'], 'causa enlazada al catálogo');
        $this->assertNotNull($p['equipos_herramientas'][0]['fk_recurso_id'], 'herramienta nueva agregada al catálogo');
        $this->assertSame('PRUEBA EPP ESTRUCTURAL', $p['equipos_herramientas'][0]['parte_recurso_descripcion']);
        $this->assertSame(1, (int) $p['parte_total_heridos']);
        $this->assertCount(0, $p['fallecidos']);

        // Mismo recurso escrito distinto: reutiliza el catálogo; secuencia +1 en la misma estación; incendio numera aparte
        $segundo = $this->parte(['equipos_herramientas' => [['parte_recurso_descripcion' => 'prueba epp estructural', 'parte_recurso_cantidad' => 1]]]);
        [$st, $r2, $t] = $this->api('POST', 'operaciones/setParte.php', $segundo, 9802);
        $this->assertSame(201, $st, $t);
        $this->assertStringEndsWith('-PA-T98-2025-0002', $r2['parte_numero']);
        $this->assertSame(1, (int) self::$pdo->query("SELECT count(*) FROM operaciones.tb_partes_catalogo_recursos WHERE recurso_descripcion = 'PRUEBA EPP ESTRUCTURAL'")->fetchColumn());
        [$st, $r3, $t] = $this->api('POST', 'operaciones/setParte.php', $this->parte(['parte_tipo' => 'INCENDIO', 'parte_fecha' => '2026-01-02',
            'vehiculos' => [['fk_vehiculo_id' => 9802, 'parte_vehiculo_km_salida' => 100, 'parte_vehiculo_km_retorno' => 130,
                'parte_vehiculo_hora_salida' => '2026-01-02T22:15', 'parte_vehiculo_hora_arribo' => '2026-01-02T22:35',
                'parte_vehiculo_hora_fin_operaciones' => '2026-01-03T00:35']]]));
        $this->assertSame(201, $st, $t);
        $this->assertStringEndsWith('-PI-T98-2026-0001', $r3['parte_numero'], 'otro año y tipo: reinicia');

        // Listado con filtros
        [$st, $lista] = $this->api('GET', 'operaciones/getPartes.php?estacion=9801&tipo=AUXILIO&q=evacu', null, 9803);
        $this->assertSame(200, $st);
        $this->assertCount(2, $lista);
        $this->assertSame('R-98', $lista[0]['vehiculos']);

        // PDF para imprimir: con OPE_PARTES (también solo consulta); 404 si no existe
        $ctx = fn(int $u) => stream_context_create(['http' => ['ignore_errors' => true, 'timeout' => 60,
            'header' => 'Authorization: Bearer ' . jwtEmitir(['sub' => $u, 'tipo' => 'usuario'], 600, self::SECRETO)]]);
        $pdf = file_get_contents('http://127.0.0.1:' . self::$puerto . "/reportes/operaciones/parte.php?id=$id", false, $ctx(9803));
        $this->assertStringContainsString('200', $http_response_header[0]);
        $this->assertStringStartsWith('%PDF', $pdf);
        file_get_contents('http://127.0.0.1:' . self::$puerto . '/reportes/operaciones/parte.php?id=999999', false, $ctx(9803));
        $this->assertStringContainsString('404', $http_response_header[0]);
        $sinPermiso = self::$pdo->query("SELECT 1 FROM admin.tb_usuarios WHERE usuario_id = 9804")->fetchColumn();
        $this->assertFalse($sinPermiso);
        file_get_contents('http://127.0.0.1:' . self::$puerto . "/reportes/operaciones/parte.php?id=$id", false, $ctx(9804));
        $this->assertStringContainsString('403', $http_response_header[0]);

        // La bitácora del vehículo muestra la emergencia con sus km
        [$st, $b, $t] = $this->api('GET', 'administrativo/bitacora/getBitacoraVehiculo.php?id=9801&desde=2025-03-01&hasta=2025-03-31');
        $this->assertSame(200, $st, $t);
        $emergencias = array_values(array_filter($b['eventos'], fn($ev) => $ev['tipo'] === 'EMERGENCIA'));
        $this->assertCount(2, $emergencias);
        $this->assertSame(23343.0, (float) $emergencias[0]['km_fin']);
        $this->assertStringContainsString('Evacuación', $emergencias[0]['detalle']);

        // Kilometraje del vehículo (bitácora / mantenimiento)
        $this->assertSame(23343.0, (float) self::$pdo->query('SELECT vehiculo_kilometraje FROM administrativo.vw_vehiculos_kilometraje WHERE vehiculo_id = 9801')->fetchColumn());
    }

    public function testValidaciones(): void
    {
        $sinMando = $this->parte();
        $sinMando['personal'][0]['parte_personal_rol'] = 'PERSONAL OPERATIVO';
        [$st, $r] = $this->api('POST', 'operaciones/setParte.php', $sinMando);
        $this->assertSame(422, $st);
        $this->assertStringContainsString('al mando', $r['msg']);

        $km = $this->parte();
        $km['vehiculos'][0]['parte_vehiculo_km_retorno'] = 100;
        [$st, $r] = $this->api('POST', 'operaciones/setParte.php', $km);
        $this->assertSame(422, $st);
        $this->assertStringContainsString('km de ingreso', $r['msg']);

        $horas = $this->parte();
        $horas['vehiculos'][0]['parte_vehiculo_hora_arribo'] = '2025-03-10T22:00';
        [$st, $r] = $this->api('POST', 'operaciones/setParte.php', $horas);
        $this->assertSame(422, $st);
        $this->assertStringContainsString('orden', $r['msg']);

        [$st] = $this->api('POST', 'operaciones/setParte.php', $this->parte(['vehiculos' => []]));
        $this->assertSame(422, $st);
        [$st] = $this->api('POST', 'operaciones/setParte.php', $this->parte(['parte_fecha' => date('Y-m-d', strtotime('+2 days'))]));
        $this->assertSame(422, $st);
    }

    public function testEdicionAnulacionYEstadistica(): void
    {
        [$st, $r, $t] = $this->api('POST', 'operaciones/setParte.php', $this->parte(['parte_fecha' => '2025-04-01', 'parte_estado' => 'FINALIZADO']));
        $this->assertSame(201, $st, $t);
        $id = $r['id'];
        $edicion = $this->parte(['parte_id' => $id, 'parte_fecha' => '2025-04-01', 'parte_novedades' => 'Ninguna']);
        // Finalizado: solo quien tiene OPE_PARTE_ANULAR lo corrige
        [$st] = $this->api('PUT', 'operaciones/setParte.php', $edicion, 9802);
        $this->assertSame(422, $st);
        [$st, , $t] = $this->api('PUT', 'operaciones/setParte.php', $edicion);
        $this->assertSame(200, $st, $t);
        [$st] = $this->api('PUT', 'operaciones/setParte.php', array_merge($edicion, ['parte_tipo' => 'INCENDIO']));
        $this->assertSame(422, $st, 'no cambia el tipo de un parte numerado');

        // Estadística del período
        [$st, $e, $t] = $this->api('GET', 'operaciones/getEstadisticasPartes.php?desde=2025-03-01&hasta=2025-04-30&estacion=9801');
        $this->assertSame(200, $st, $t);
        $partes = $e['resumen']['partes'];
        $this->assertGreaterThanOrEqual(1, $partes);
        $this->assertSame(15.0, (float) $e['resumen']['respuesta_prom_min'], 'aviso 22:05 -> arribo 22:20');
        $this->assertCount(2, $e['por_mes']);
        $vehiculo = array_values(array_filter($e['por_vehiculo'], fn($v) => $v['vehiculo_id'] === 9801))[0];
        $this->assertSame($partes, $vehiculo['salidas']);
        $this->assertSame(6.0 * $partes, (float) $vehiculo['km']);
        $this->assertEqualsWithDelta(1.1, $vehiculo['horas'] / $partes, 0.01);
        $bombero = array_values(array_filter($e['por_bombero'], fn($b) => $b['personal_id'] === 9801))[0];
        $this->assertSame($partes, $bombero['al_mando']);
        $this->assertContains('PRUEBA EPP ESTRUCTURAL', array_column($e['por_recurso'], 'descripcion'));
        $this->assertSame($partes, $e['por_hora'][22]);
        [$st] = $this->api('GET', 'operaciones/getEstadisticasPartes.php', null, 9802);
        $this->assertSame(403, $st);

        // Anular: requiere privilegio y motivo; el parte sale de la estadística y no se edita
        [$st] = $this->api('PUT', 'operaciones/setParte.php', ['parte_id' => $id, 'parte_estado' => 'ANULADO', 'parte_anulado_motivo' => 'Duplicado'], 9802);
        $this->assertSame(403, $st);
        [$st] = $this->api('PUT', 'operaciones/setParte.php', ['parte_id' => $id, 'parte_estado' => 'ANULADO']);
        $this->assertSame(422, $st);
        [$st] = $this->api('PUT', 'operaciones/setParte.php', ['parte_id' => $id, 'parte_estado' => 'ANULADO', 'parte_anulado_motivo' => 'Duplicado']);
        $this->assertSame(200, $st);
        [, $e2] = $this->api('GET', 'operaciones/getEstadisticasPartes.php?desde=2025-03-01&hasta=2025-04-30&estacion=9801');
        $this->assertSame($partes - 1, $e2['resumen']['partes']);
        [$st] = $this->api('PUT', 'operaciones/setParte.php', $edicion);
        $this->assertSame(422, $st);
    }

    public function testCatalogos(): void
    {
        [$st, $c, $t] = $this->api('GET', 'operaciones/getCatalogosParte.php', null, 9803);
        $this->assertSame(200, $st, $t);
        $this->assertContains('Evacuación', array_column($c['tipos_auxilio'], 'subclasificacion'));
        $this->assertContains('Bro. V.', $c['rangos']);
        $this->assertContains('10-1', $c['claves']);
        $this->assertContains(9801, array_map('intval', array_column($c['vehiculos'], 'vehiculo_id')));
        $this->assertContains('Apoyo interno', $c['apoyos']);
    }
}
