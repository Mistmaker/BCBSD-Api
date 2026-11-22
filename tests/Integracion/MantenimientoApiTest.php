<?php

use PHPUnit\Framework\TestCase;

/**
 * Pruebas de punta a punta del módulo de mantenimiento contra una base PostgreSQL real.
 *
 * Se OMITEN salvo que se defina BCBSD_TEST_DB_NAME (y opcionalmente BCBSD_TEST_DB_HOST,
 * BCBSD_TEST_DB_PORT, BCBSD_TEST_DB_USER, BCBSD_TEST_DB_PASS). Usar una base DESECHABLE con
 * script.sql, script-2.sql, script_sbj_temp.sql y las migraciones aplicadas. El usuario debe
 * poder usar session_replication_role (superusuario) para insertar datos de prueba. Requiere 04-privilegios.sql
 * (el usuario de prueba recibe todos los privilegios MANT_*).
 * Los datos de prueba usan IDs >= 9000 y se borran al terminar.
 * El log del servidor PHP queda en <temp>/bcbsd-api-integracion.log.
 */
final class MantenimientoApiTest extends TestCase
{
    private const SECRETO = 'secreto-de-prueba-integracion-de-al-menos-32-caracteres';
    private const USUARIO = 9001;
    private const PERSONAL = 9001;
    private const VEHICULO = 9001;

    private static ?PDO $pdo = null;
    private static int $contrato = 0;
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
            INSERT INTO admin.tb_usuarios (usuario_id, fk_persona_id, fk_perfil_id, usuario_login, usuario_pass) VALUES (9001, 1, 1, 'prueba_mant', 'x');
            INSERT INTO tthh.tb_personal_puestos (ppersonal_id, fk_personal_id, fk_puesto_id) VALUES (9001, 1, 1);
            INSERT INTO administrativo.tb_vehiculos (vehiculo_id, fk_usuario_id, fk_marca_id, vehiculo_placa, vehiculo_tipo, vehiculo_combustible, vehiculo_sigla)
                 VALUES (9001, 9001, 1, 'TST-9001', 'CAMIONETA', 'DIESEL', 'PRUEBA-1'), (9002, 9001, 1, 'TST-9002', 'CAMIONETA', 'DIESEL', 'PRUEBA-2');
            INSERT INTO logistica.tb_ordenesabastecimiento (orden_id, fk_usuario_id, fk_unidad_id, orden_kilometraje, orden_codigo, orden_serie, orden_codigo_serie,
                 director_administrativo, personal_solicita, operador_id, orden_codigo_institucion)
                 VALUES (9001, 9001, 9001, 31500, 'TST-ABS-9001', 0, 0, 9001, 9001, 9001, 'TST');
            SET session_replication_role = origin;
            INSERT INTO admin.tb_usuario_rol (fk_usuario_id, fk_rol_id) SELECT 9001, rol_id FROM admin.tb_roles WHERE rol_codigo LIKE 'MANT_%';");

        $socket = stream_socket_server('tcp://127.0.0.1:0');
        self::$puerto = (int) substr(strrchr(stream_socket_get_name($socket, false), ':'), 1);
        fclose($socket);
        $env = array_merge(getenv(), [
            'BCBSD_JWT_SECRET' => self::SECRETO, 'BCBSD_DB_HOST' => $host, 'BCBSD_DB_PORT' => $port,
            'BCBSD_DB_NAME' => getenv('BCBSD_TEST_DB_NAME'), 'BCBSD_DB_USER' => getenv('BCBSD_TEST_DB_USER') ?: 'postgres',
            'BCBSD_DB_PASS' => getenv('BCBSD_TEST_DB_PASS') ?: '',
        ]);
        self::$servidor = proc_open([PHP_BINARY, '-S', '127.0.0.1:' . self::$puerto, '-t', dirname(__DIR__, 2)],
            [1 => ['file', '/dev/null', 'w'], 2 => ['file', sys_get_temp_dir() . '/bcbsd-api-integracion.log', 'w']], $pipes, dirname(__DIR__, 2), $env);
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
            DELETE FROM logistica.tb_informe_ordenesmantenimiento WHERE fk_informe_id IN (SELECT informe_id FROM logistica.tb_informemantenimiento WHERE fk_usuario_id = 9001);
            DELETE FROM logistica.tb_informe_ordenesmantenimiento WHERE fk_orden_id IN (SELECT orden_id FROM logistica.tb_ordenesmantenimiento WHERE fk_vehiculo_id = 9001);
            DELETE FROM logistica.tb_informemantenimiento WHERE fk_usuario_id = 9001 OR informe_numero LIKE 'PRUEBA-%';
            DELETE FROM logistica.tb_ordenesmantenimiento WHERE fk_vehiculo_id = 9001;
            DELETE FROM logistica.tb_contratosmantenimiento WHERE contrato_codigo LIKE 'PRUEBA-%';
            UPDATE administrativo.tb_vehiculos SET fk_plan_id = NULL WHERE vehiculo_id = 9001;
            DELETE FROM logistica.tb_planesmantenimiento WHERE plan_modelo LIKE 'PRUEBA %';
            DELETE FROM logistica.tb_recursosmantenimiento WHERE recurso_descripcion LIKE 'PRUEBA %';
            DELETE FROM logistica.tb_ordenesabastecimiento WHERE orden_id = 9001;
            DELETE FROM logistica.tb_contratosmantenimiento_vehiculos WHERE fk_vehiculo_id IN (9001, 9002);
            DELETE FROM administrativo.tb_vehiculos WHERE vehiculo_id IN (9001, 9002);
            DELETE FROM tthh.tb_personal_puestos WHERE ppersonal_id = 9001;
            DELETE FROM admin.tb_usuario_rol WHERE fk_usuario_id = 9001;
            DELETE FROM admin.tb_usuarios WHERE usuario_id = 9001;");
    }

    protected function setUp(): void
    {
        if (!self::$pdo) {
            $this->markTestSkipped('Defina BCBSD_TEST_DB_NAME para ejecutar las pruebas de integración');
        }
    }

    /** Crea (una vez) un contrato de prueba con partidas y devuelve su id. */
    private function contrato(): int
    {
        if (!self::$contrato) {
            [$st, $r] = $this->api('POST', 'administrativo/mantenimiento/setContrato.php', [
                'contrato_codigo' => 'PRUEBA-CONTRATO-01', 'contrato_nombre_corto' => 'Mantenimiento motocicletas', 'contrato_tipo' => 'GENERAL', 'contrato_taller' => 'TALLER DE PRUEBA',
                'contrato_representante_legal' => 'Representante', 'contrato_monto' => 1000,
                'partidas' => [['partida_rubro' => 'MANO DE OBRA', 'partida_codigo' => '73.04.05', 'partida_monto' => 300],
                               ['partida_rubro' => 'REPUESTOS', 'partida_monto' => 600],
                               ['partida_rubro' => 'ACEITES Y LUBRICANTES', 'partida_monto' => 100]],
            ]);
            $this->assertSame(201, $st, json_encode($r));
            self::$contrato = $r['id'];
        }
        return self::$contrato;
    }

    private function api(string $metodo, string $ruta, $cuerpo = null, string $tipo = 'usuario'): array
    {
        $token = jwtEmitir(['sub' => self::USUARIO, 'tipo' => $tipo], 600, self::SECRETO);
        $ctx = stream_context_create(['http' => [
            'method' => $metodo, 'ignore_errors' => true, 'timeout' => 15,
            'header' => "Authorization: Bearer $token\r\nContent-Type: application/json",
            'content' => $cuerpo === null ? '' : json_encode($cuerpo),
        ]]);
        $texto = file_get_contents('http://127.0.0.1:' . self::$puerto . '/servicios/' . $ruta, false, $ctx);
        $estado = (int) explode(' ', $http_response_header[0])[1];
        return [$estado, json_decode($texto, true), $texto];
    }

    public function testFlujoCompleto(): void
    {
        $base = 'administrativo/mantenimiento/';

        // 1. Recursos y plan preventivo asignado al vehículo
        [$st, $r] = $this->api('POST', $base . 'setRecurso.php', ['recurso_codigo' => 'TST-1', 'recurso_descripcion' => 'prueba aceite 15w40']);
        $this->assertSame(201, $st, json_encode($r));
        $recurso = $r['id'];
        [$st] = $this->api('POST', $base . 'setRecurso.php', ['recurso_descripcion' => 'PRUEBA ACEITE 15W40']);
        $this->assertSame(409, $st, 'Descripción duplicada debe rechazarse');

        [$st, $r] = $this->api('POST', $base . 'setPlan.php', [
            'plan_modelo' => 'prueba hilux',
            'reglas' => [['mantenimiento_km_inicio' => 5000, 'mantenimiento_km_intervalo' => 10000, 'recursos' => [$recurso]]],
            'vehiculos' => [self::VEHICULO],
        ]);
        $this->assertSame(201, $st, json_encode($r));
        $plan = $r['id'];
        [$st, $r] = $this->api('GET', $base . "getPlanes.php?id=$plan");
        $this->assertSame('PRUEBA HILUX', $r['plan_modelo']);
        $this->assertSame('PRUEBA ACEITE 15W40', $r['reglas'][0]['recursos'][0]['recurso_descripcion']);
        $this->assertSame(self::VEHICULO, $r['vehiculos'][0]['vehiculo_id']);

        // 2. Estado: km 31500 (del abastecimiento) -> próximo 35000, AL DIA (tolerancia 1000)
        [$st, $v] = $this->api('GET', $base . 'getEstadoVehiculos.php?id=' . self::VEHICULO);
        $this->assertSame(200, $st, json_encode($v));
        $this->assertEquals(31500, $v['vehiculo_kilometraje']);
        $this->assertSame(35000, $v['proximo']['km_proximo']);
        $this->assertSame('AL DIA', $v['estado_mantenimiento']);

        // 3. Orden correctiva con detalles
        $orden = [
            'fk_vehiculo_id' => self::VEHICULO, 'personal_solicita' => self::PERSONAL, 'director_administrativo' => self::PERSONAL,
            'tecnico_servicios' => self::PERSONAL, 'orden_fecha_mantenimiento' => '2026-11-20 09:00', 'orden_km_mantenimiento' => 34500,
            'orden_tipomantenimiento' => 'PREVENTIVO', 'fk_contrato_id' => $this->contrato(),
            'trabajos' => [['trabajo_descripcion' => 'Cambio de aceite y filtro']],
            'sugeridos' => [['trabajo_descripcion' => 'Revisar frenos']],
            'facturas' => [['factura_tipo' => 'MANO DE OBRA', 'factura_descripcion' => '001-001-123', 'factura_valor' => '51.10'],
                           ['factura_tipo' => 'REPUESTOS', 'factura_descripcion' => '001-001-124', 'factura_valor' => '34.30'],
                           ['factura_tipo' => 'ACEITES Y LUBRICANTES', 'factura_valor' => '']],
            'anexos' => [['anexo_descripcion' => 'Fotos del taller']],
        ];
        [$st, $r] = $this->api('POST', $base . 'setOrdenMantenimiento.php', $orden);
        $this->assertSame(201, $st, json_encode($r));
        $this->assertMatchesRegularExpression('/^[A-Z]+\d{2}ODM\d{5}$/', $r['orden_codigo']);
        $this->assertSame(45000, $r['proximo']['km_proximo'], 'Tras el preventivo en 34500 el siguiente punto es 45000');
        $ordenId = $r['id'];

        [$st, $o] = $this->api('GET', $base . "getOrdenesMantenimiento.php?id=$ordenId");
        $this->assertSame('PRUEBA-1', $o['vehiculo_sigla']);
        $this->assertCount(1, $o['trabajos']);
        $this->assertCount(3, $o['facturas']);
        $this->assertNull($o['facturas'][2]['factura_valor']);
        $this->assertEquals(85.40, $o['total_facturas']);
        $totales = json_decode($o['totales_rubro'], true);
        $this->assertEquals(51.10, $totales['MANO DE OBRA']);
        $this->assertEquals(34.30, $totales['REPUESTOS']);

        // El km de la orden pasa a ser el km actual del vehículo
        [, $v] = $this->api('GET', $base . 'getEstadoVehiculos.php?id=' . self::VEHICULO);
        $this->assertEquals(34500, $v['vehiculo_kilometraje']);
        $this->assertEquals(34500, $v['ultimo_km_preventivo']);

        // 4. Edición: reemplaza trabajos, conserva lo no enviado
        $o['trabajos'] = [['trabajo_descripcion' => 'Cambio de aceite'], ['trabajo_descripcion' => 'Cambio de filtro de aire']];
        unset($o['facturas']);
        $o['orden_estado'] = 'ENTREGADO';
        [$st, $r] = $this->api('PUT', $base . 'setOrdenMantenimiento.php', $o);
        $this->assertSame(422, $st, 'De MANTENIMIENTO no se pasa directo a ENTREGADO');
        $o['orden_estado'] = 'RECIBIDO';
        [$st, $r] = $this->api('PUT', $base . 'setOrdenMantenimiento.php', $o);
        $this->assertSame(200, $st, json_encode($r));
        [, $o2] = $this->api('GET', $base . "getOrdenesMantenimiento.php?id=$ordenId");
        $this->assertCount(2, $o2['trabajos']);
        $this->assertCount(3, $o2['facturas'], 'Las facturas no enviadas se conservan');
        $this->assertSame('RECIBIDO', $o2['orden_estado']);
        $this->assertSame('TALLER DE PRUEBA', $o2['taller'], 'El taller sale del contrato');

        // 5. Informe con la orden; la orden ya no aparece como disponible
        $informe = ['tecnico_servicios' => self::PERSONAL, 'director_administrativo' => self::PERSONAL, 'informe_taller' => 'Taller de prueba', 'ordenes' => [$ordenId]];
        [$st, $r] = $this->api('POST', $base . 'setInformeMantenimiento.php', $informe);
        $this->assertSame(201, $st, json_encode($r));
        $this->assertMatchesRegularExpression('/INF\d{5}$/', $r['informe_numero']);
        $informeId = $r['id'];
        [, $libres] = $this->api('GET', $base . 'getOrdenesMantenimiento.php?sin_informe=1&vehiculo_id=' . self::VEHICULO);
        $this->assertSame([], $libres);

        [$st, $r] = $this->api('POST', $base . 'setInformeMantenimiento.php', $informe);
        $this->assertSame(422, $st, 'Una orden no puede estar en dos informes');
        $this->assertStringContainsString('ya está en el informe', $r['msg']);

        [$st, $r] = $this->api('PUT', $base . 'setOrdenMantenimiento.php', array_merge($o2, ['orden_estado' => 'ANULADA']));
        $this->assertSame(422, $st, 'No se anula una orden incluida en un informe');

        [$st, $inf] = $this->api('GET', $base . "getInformesMantenimiento.php?id=$informeId");
        $this->assertSame(1, $inf['ordenes']);
        $this->assertSame('Cambio de aceite', $inf['ordenes_detalle'][0]['trabajos'][0]['trabajo_descripcion']);

        // 6. Anular informe libera la orden
        [$st] = $this->api('PUT', $base . 'setInformeMantenimiento.php', array_merge($informe, ['informe_id' => $informeId, 'informe_estado' => 'ANULADO']));
        $this->assertSame(200, $st);
        [, $libres] = $this->api('GET', $base . 'getOrdenesMantenimiento.php?sin_informe=1&vehiculo_id=' . self::VEHICULO);
        $this->assertCount(1, $libres);
    }

    public function testNumeroDeInformeIndividualYReportes(): void
    {
        $base = 'administrativo/mantenimiento/';
        [$st, $sig] = $this->api('GET', $base . 'getOrdenesMantenimiento.php?siguiente_serie=1');
        $this->assertSame(200, $st);
        $this->assertGreaterThanOrEqual(1, $sig['orden_serie']);

        $orden = [
            'fk_vehiculo_id' => self::VEHICULO, 'personal_solicita' => self::PERSONAL, 'director_administrativo' => self::PERSONAL,
            'tecnico_servicios' => self::PERSONAL, 'orden_fecha_mantenimiento' => '2026-11-21 10:00', 'orden_km_mantenimiento' => 36000,
            'orden_tipomantenimiento' => 'PREVENTIVO Y CORRECTIVO', 'orden_serie' => $sig['orden_serie'], 'fk_contrato_id' => $this->contrato(),
            'orden_informe_numero' => 'PRUEBA-INF-007', 'orden_informe_serie' => 7,
            'orden_fecha_recepcion' => '2026-12-01',
            'trabajos' => [['trabajo_descripcion' => 'Revisión de frenos']],
            'sugeridos' => [['trabajo_descripcion' => 'Cambio de pastillas']],
            'facturas' => [['factura_tipo' => 'MANO DE OBRA', 'factura_descripcion' => '001-001-1', 'factura_valor' => '51.10']],
        ];
        [$st, $r] = $this->api('POST', $base . 'setOrdenMantenimiento.php', $orden);
        $this->assertSame(201, $st, json_encode($r));
        $this->assertMatchesRegularExpression('/^[A-Z]+\d{2}ODM\d{5}$/', $r['orden_codigo']);
        [, $o] = $this->api('GET', $base . 'getOrdenesMantenimiento.php?id=' . $r['id']);
        $this->assertSame($sig['orden_serie'], $o['orden_serie']);
        $this->assertSame('TALLER DE PRUEBA', $o['taller']);
        $this->assertSame('PRUEBA-INF-007', $o['orden_informe_numero']);
        $this->assertSame('2026-12-01', $o['orden_fecha_recepcion']);
        [$st, $si] = $this->api('GET', $base . 'getOrdenesMantenimiento.php?siguiente_informe=1');
        $this->assertSame(200, $st);
        $this->assertArrayHasKey('orden_informe_numero', $si);

        // A la bitácora solo entran órdenes RECIBIDO o ENTREGADO
        [$st, $err] = $this->api('POST', $base . 'setInformeMantenimiento.php', [
            'informe_numero' => 'PRUEBA-BITACORA-00', 'tecnico_servicios' => self::PERSONAL, 'director_administrativo' => self::PERSONAL, 'ordenes' => [$r['id']]]);
        $this->assertSame(422, $st);
        $this->assertStringContainsString('RECIBIDO', $err['msg']);
        $o['orden_estado'] = 'RECIBIDO';
        [$st] = $this->api('PUT', $base . 'setOrdenMantenimiento.php', $o);
        $this->assertSame(200, $st);
        $o['orden_estado'] = 'ENTREGADO';
        [$st, $rr] = $this->api('PUT', $base . 'setOrdenMantenimiento.php', $o);
        $this->assertSame(200, $st, json_encode($rr));

        [$st, $sig2] = $this->api('GET', $base . 'getOrdenesMantenimiento.php?siguiente_serie=1');
        $this->assertSame($sig['orden_serie'] + 1, $sig2['orden_serie']);

        // Bitácora con la orden y los cuatro PDF
        [$st, $sb] = $this->api('GET', $base . 'getInformesMantenimiento.php?siguiente=1&contrato_id=' . $this->contrato());
        $this->assertSame('BITÁCORA 01-MANTENIMIENTO MOTOCICLETAS PRUEBA-CONTRATO-01', $sb['informe_numero']);
        [$st, $inf] = $this->api('POST', $base . 'setInformeMantenimiento.php', [
            'informe_numero' => 'PRUEBA-BITACORA-01', 'tecnico_servicios' => self::PERSONAL, 'director_administrativo' => self::PERSONAL,
            'fk_contrato_id' => $this->contrato(), 'ordenes' => [$r['id']],
        ]);
        $this->assertSame(201, $st, json_encode($inf));
        foreach (['orden', 'informe', 'acta'] as $doc) {
            [$st, , $pdf] = $this->api('GET', '../reportes/mantenimiento/ordenMantenimiento.php?doc=' . $doc . '&id=' . $r['id']);
            $this->assertSame(200, $st, "PDF $doc");
            $this->assertStringStartsWith('%PDF', $pdf, "PDF $doc");
        }
        [$st, , $pdf] = $this->api('GET', '../reportes/mantenimiento/informeMantenimiento.php?id=' . $inf['id']);
        $this->assertSame(200, $st);
        $this->assertStringStartsWith('%PDF', $pdf);
        [$st] = $this->api('GET', '../reportes/mantenimiento/ordenMantenimiento.php?doc=otro&id=' . $r['id']);
        $this->assertSame(400, $st);
    }

    public function testContratoSaldoYTope(): void
    {
        $base = 'administrativo/mantenimiento/';
        $contrato = $this->contrato();
        // La suma de partidas no puede superar el monto
        [$st, $r] = $this->api('POST', $base . 'setContrato.php', ['contrato_codigo' => 'PRUEBA-CONTRATO-02', 'contrato_taller' => 'X', 'contrato_monto' => 10,
            'partidas' => [['partida_rubro' => 'REPUESTOS', 'partida_monto' => 11]]]);
        $this->assertSame(422, $st);
        [$st, $r] = $this->api('POST', $base . 'setContrato.php', ['contrato_codigo' => 'PRUEBA-CONTRATO-03', 'contrato_taller' => 'X', 'contrato_monto' => 10,
            'vehiculos' => [999999999]]);
        $this->assertSame(422, $st, 'Vehículo inexistente');

        // Contrato de vigencia tecnológica que no cubre al vehículo de prueba
        [$st, $vt] = $this->api('POST', $base . 'setContrato.php', ['contrato_codigo' => 'PRUEBA-CONTRATO-VT', 'contrato_tipo' => 'VIGENCIA TECNOLÓGICA',
            'contrato_taller' => 'CONCESIONARIO', 'contrato_monto' => 500, 'partidas' => [['partida_rubro' => 'REPUESTOS', 'partida_monto' => 500]], 'vehiculos' => [9002]]);
        $this->assertSame(201, $st, json_encode($vt));
        [, $aplicables] = $this->api('GET', $base . 'getContratos.php?vigentes=1&vehiculo_id=' . self::VEHICULO);
        $codigos = array_column($aplicables, 'contrato_codigo');
        $this->assertContains('PRUEBA-CONTRATO-01', $codigos);
        $this->assertNotContains('PRUEBA-CONTRATO-VT', $codigos);

        $orden = ['fk_vehiculo_id' => self::VEHICULO, 'personal_solicita' => self::PERSONAL, 'director_administrativo' => self::PERSONAL,
            'tecnico_servicios' => self::PERSONAL, 'orden_fecha_mantenimiento' => '2026-11-22 10:00', 'orden_km_mantenimiento' => 37000];
        [$st, $r] = $this->api('POST', $base . 'setOrdenMantenimiento.php', array_merge($orden, ['fk_contrato_id' => $vt['id']]));
        $this->assertSame(422, $st, 'El contrato de vigencia tecnológica no cubre a este vehículo');

        [, $antes] = $this->api('GET', $base . "getContratos.php?id=$contrato");
        $saldo = array_column($antes['partidas'], 'saldo', 'partida_rubro');
        // Supera el saldo de mano de obra
        [$st, $r] = $this->api('POST', $base . 'setOrdenMantenimiento.php', array_merge($orden, ['fk_contrato_id' => $contrato,
            'facturas' => [['factura_tipo' => 'MANO DE OBRA', 'factura_valor' => (float) $saldo['MANO DE OBRA'] + 0.01]]]));
        $this->assertSame(422, $st);
        $this->assertStringContainsString('supera el saldo', $r['msg']);
        // Justo el saldo disponible: se acepta y el saldo queda en 0
        [$st, $r] = $this->api('POST', $base . 'setOrdenMantenimiento.php', array_merge($orden, ['fk_contrato_id' => $contrato,
            'facturas' => [['factura_tipo' => 'MANO DE OBRA', 'factura_valor' => $saldo['MANO DE OBRA']]]]));
        $this->assertSame(201, $st, json_encode($r));
        [, $despues] = $this->api('GET', $base . "getContratos.php?id=$contrato");
        $this->assertEquals(0, array_column($despues['partidas'], 'saldo', 'partida_rubro')['MANO DE OBRA']);
        // No se puede bajar la partida por debajo de lo consumido
        [$st, $r2] = $this->api('PUT', $base . 'setContrato.php', ['contrato_id' => $contrato, 'contrato_codigo' => 'PRUEBA-CONTRATO-01',
            'contrato_taller' => 'TALLER DE PRUEBA', 'contrato_monto' => 1000, 'partidas' => [['partida_rubro' => 'MANO DE OBRA', 'partida_monto' => 1]]]);
        $this->assertSame(422, $st);
        $this->assertStringContainsString('consumidos', $r2['msg']);
        // Anular la orden libera el saldo
        [, $o] = $this->api('GET', $base . 'getOrdenesMantenimiento.php?id=' . $r['id']);
        [$st] = $this->api('PUT', $base . 'setOrdenMantenimiento.php', array_merge($o, ['orden_estado' => 'ANULADA']));
        $this->assertSame(200, $st);
        [, $liberado] = $this->api('GET', $base . "getContratos.php?id=$contrato");
        $this->assertEquals($saldo['MANO DE OBRA'], array_column($liberado['partidas'], 'saldo', 'partida_rubro')['MANO DE OBRA']);
    }

    public function testPrivilegios(): void
    {
        $base = 'administrativo/mantenimiento/';
        $quitar = fn(string $codigo) => self::$pdo->exec("DELETE FROM admin.tb_usuario_rol WHERE fk_usuario_id = 9001
            AND fk_rol_id = (SELECT rol_id FROM admin.tb_roles WHERE rol_codigo = '$codigo')");
        $dar = fn(string $codigo) => self::$pdo->exec("INSERT INTO admin.tb_usuario_rol (fk_usuario_id, fk_rol_id)
            SELECT 9001, rol_id FROM admin.tb_roles WHERE rol_codigo = '$codigo'");

        $orden = ['fk_vehiculo_id' => self::VEHICULO, 'personal_solicita' => self::PERSONAL, 'director_administrativo' => self::PERSONAL,
            'tecnico_servicios' => self::PERSONAL, 'orden_fecha_mantenimiento' => '2026-11-22 11:00', 'orden_km_mantenimiento' => 38000,
            'fk_contrato_id' => $this->contrato()];
        $quitar('MANT_ORDEN_CREAR');
        [$st, $r] = $this->api('POST', $base . 'setOrdenMantenimiento.php', $orden);
        $this->assertSame(403, $st, 'Sin MANT_ORDEN_CREAR no se crean órdenes');
        $this->assertStringContainsString('MANT_ORDEN_CREAR', $r['msg']);
        $dar('MANT_ORDEN_CREAR');
        [$st, $r] = $this->api('POST', $base . 'setOrdenMantenimiento.php', $orden);
        $this->assertSame(201, $st, json_encode($r));
        [, $o] = $this->api('GET', $base . 'getOrdenesMantenimiento.php?id=' . $r['id']);

        $quitar('MANT_ORDEN_RECIBIR');
        [$st] = $this->api('PUT', $base . 'setOrdenMantenimiento.php', array_merge($o, ['orden_estado' => 'RECIBIDO']));
        $this->assertSame(403, $st, 'Sin MANT_ORDEN_RECIBIR no se recibe el vehículo');
        $dar('MANT_ORDEN_RECIBIR');

        $quitar('MANT_ORDEN_ANULAR');
        [$st] = $this->api('PUT', $base . 'setOrdenMantenimiento.php', array_merge($o, ['orden_estado' => 'ANULADA']));
        $this->assertSame(403, $st, 'Sin MANT_ORDEN_ANULAR no se anula');
        $dar('MANT_ORDEN_ANULAR');
        [$st] = $this->api('PUT', $base . 'setOrdenMantenimiento.php', array_merge($o, ['orden_estado' => 'ANULADA']));
        $this->assertSame(200, $st);

        $quitar('MANT_CONTRATO_GESTIONAR');
        [$st] = $this->api('POST', $base . 'setContrato.php', ['contrato_codigo' => 'PRUEBA-SIN-PERMISO', 'contrato_taller' => 'X']);
        $this->assertSame(403, $st);
        $dar('MANT_CONTRATO_GESTIONAR');
        // Privilegios actuales (sin volver a iniciar sesión)
        $quitar('MANT_PLAN_GESTIONAR');
        [$st, $p] = $this->api('GET', 'auth/getPermisos.php');
        $this->assertSame(200, $st);
        $this->assertContains('MANT_ORDEN_CREAR', $p['permisos']);
        $this->assertNotContains('MANT_PLAN_GESTIONAR', $p['permisos']);
        $this->assertContains('/admin/ordenes-mantenimiento', $p['rutas']);
        $dar('MANT_PLAN_GESTIONAR');
        [, $p] = $this->api('GET', 'auth/getPermisos.php');
        $this->assertContains('MANT_PLAN_GESTIONAR', $p['permisos'], 'Un privilegio asignado se ve de inmediato');
        [, $pv] = $this->api('GET', 'auth/getPermisos.php', null, 'voluntario');
        $this->assertSame([], $pv['permisos']);

        // Menú: solo pantallas asignadas, con el usuario del token (se ignora ?id de otro usuario)
        [$st, $menu] = $this->api('GET', 'auth/getMenuUsuario.php?id=113');
        $this->assertSame(200, $st);
        $urls = array_merge(...array_map(fn($m) => array_column($m['children'], 'url'), $menu));
        $this->assertContains('/admin/ordenes-mantenimiento', $urls);
        $this->assertNotContains('/admin/ordenes-movilizacion', $urls, 'Movilización no está asignada al usuario de prueba');
        $quitar('MANT_CONTRATOS');
        [, $menu] = $this->api('GET', 'auth/getMenuUsuario.php?id=9001');
        $urls = array_merge(...array_map(fn($m) => array_column($m['children'], 'url'), $menu));
        $this->assertNotContains('/admin/contratos-mantenimiento', $urls, 'Una pantalla quitada desaparece del menú');
        $dar('MANT_CONTRATOS');

        // Las consultas no requieren privilegio de acción
        [$st] = $this->api('GET', $base . 'getContratos.php');
        $this->assertSame(200, $st);
    }

    public function testValidacionesYPermisos(): void
    {
        $base = 'administrativo/mantenimiento/';
        [$st, $r] = $this->api('POST', $base . 'setOrdenMantenimiento.php', ['fk_vehiculo_id' => self::VEHICULO], 'voluntario');
        $this->assertSame(403, $st, 'Un voluntario no registra órdenes');

        [$st, $r] = $this->api('POST', $base . 'setOrdenMantenimiento.php', ['fk_vehiculo_id' => self::VEHICULO]);
        $this->assertSame(422, $st);

        // Sin contrato no se crea la orden
        $sinContrato = ['fk_vehiculo_id' => self::VEHICULO, 'personal_solicita' => self::PERSONAL, 'director_administrativo' => self::PERSONAL,
            'tecnico_servicios' => self::PERSONAL, 'orden_fecha_mantenimiento' => '2026-11-21 10:00', 'orden_km_mantenimiento' => 1];
        [$st, $r2] = $this->api('POST', $base . 'setOrdenMantenimiento.php', $sinContrato);
        $this->assertSame(422, $st);
        $this->assertStringContainsString('contrato', $r2['msg']);
        $this->assertStringContainsString('Falta el campo', $r['msg']);

        [$st] = $this->api('GET', $base . 'getOrdenesMantenimiento.php?id=abc');
        $this->assertSame(400, $st);
        [$st] = $this->api('GET', $base . 'getOrdenesMantenimiento.php?id=99999999');
        $this->assertSame(404, $st);
        [$st] = $this->api('DELETE', $base . 'setOrdenMantenimiento.php');
        $this->assertSame(405, $st);

        [$st, $r] = $this->api('POST', $base . 'setPlan.php', ['plan_modelo' => 'PRUEBA SIN REGLAS', 'reglas' => []]);
        $this->assertSame(422, $st);

        [$st, $s] = $this->api('GET', 'admin/getSistema.php?modulo=MANTENIMIENTO');
        $this->assertSame(200, $st);
        $this->assertArrayHasKey('sistema_siglas', $s);
        $this->assertContains('MANT_RUBROS', array_column($s['parametros'], 'param_key'));
        $this->assertArrayHasKey('director_administrativo', $s);
    }
}
