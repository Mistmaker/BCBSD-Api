<?php

use PHPUnit\Framework\TestCase;

/**
 * Bitácora del vehículo contra una base PostgreSQL real (mismas condiciones que MantenimientoApiTest).
 * Requiere 05-bitacora.sql. Datos de prueba con IDs 9100-9199, borrados al terminar.
 *
 * Escenario (período 2026-01-01 a 2026-06-30), tres camionetas TOYOTA HILUX 2018:
 *  - 9101: carga de referencia en diciembre (10000 km) y tres cargas en el período: 900 km con 37 gal (24.32 km/gal);
 *          dos cambios de motor de arranque en 3 meses (trabajo repetido), una movilización y una emergencia.
 *  - 9102: 900 km con 30 gal (30 km/gal). 9103: sin datos.
 */
final class BitacoraApiTest extends TestCase
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
        $carga = fn($id, $v, $fecha, $km, $gal, $valor) =>
            "($id, 9101, $v, '$fecha', $km, $gal, $valor, 'DIESEL', 'VALIDADA', 'TST-ABS-$id', 0, 0, 9101, 9101, 9101, 'TST')";
        self::$pdo->exec("SET session_replication_role = replica;
            INSERT INTO admin.tb_usuarios (usuario_id, fk_persona_id, fk_perfil_id, usuario_login, usuario_pass) VALUES (9101, 1, 1, 'prueba_bit', 'x'), (9102, 1, 1, 'prueba_bit2', 'x');
            INSERT INTO administrativo.tb_vehiculos (vehiculo_id, fk_usuario_id, fk_marca_id, vehiculo_placa, vehiculo_tipo, vehiculo_combustible, vehiculo_sigla,
                 vehiculo_marca, vehiculo_modelo, vehiculo_anio, vehiculo_estado)
                 VALUES (9101, 9101, 1, 'TST-9101', 'CAMIONETA', 'DIESEL', 'PRUEBA-B1', 'TOYOTA', 'HILUX', 2018, 'ACTIVO'),
                        (9102, 9101, 1, 'TST-9102', 'CAMIONETA', 'DIESEL', 'PRUEBA-B2', 'Toyota ', 'hilux', 2018, 'ACTIVO'),
                        (9103, 9101, 1, 'TST-9103', 'CAMIONETA', 'DIESEL', 'PRUEBA-B3', 'TOYOTA', 'HILUX', 2018, 'ACTIVO'),
                        (9104, 9101, 1, 'TST-9104', 'CAMIONETA', 'DIESEL', 'PRUEBA-B4', 'TOYOTA', 'HILUX', 2020, 'ACTIVO');
            INSERT INTO logistica.tb_ordenesabastecimiento (orden_id, fk_usuario_id, fk_unidad_id, orden_fecha, orden_kilometraje, orden_cantidad_galones, orden_precio_total,
                 orden_tipo_combustible, orden_estado, orden_codigo, orden_serie, orden_codigo_serie, director_administrativo, personal_solicita, operador_id, orden_codigo_institucion)
                 VALUES " . implode(',', [
                    $carga(9101, 9101, '2025-12-20', 10000, 14, 25), $carga(9102, 9101, '2026-02-01', 10300, 10.5, 18.9),
                    $carga(9103, 9101, '2026-03-01', 10600, 12, 21.6), $carga(9104, 9101, '2026-04-01', 10900, 14.5, 26.1),
                    $carga(9105, 9102, '2026-01-10', 5000, 10, 18), $carga(9106, 9102, '2026-02-10', 5450, 15, 27), $carga(9107, 9102, '2026-03-10', 5900, 15, 27),
                 ]) . ";
            INSERT INTO logistica.tb_ordenesabastecimiento (orden_id, fk_usuario_id, fk_unidad_id, orden_fecha, orden_kilometraje, orden_cantidad_galones, orden_precio_total,
                 orden_estado, orden_codigo, orden_serie, orden_codigo_serie, director_administrativo, personal_solicita, operador_id, orden_codigo_institucion)
                 VALUES (9108, 9101, 9101, '2026-04-15', 11000, 5, 9, 'EMITIDA', 'TST-ABS-9108', 0, 0, 9101, 9101, 9101, 'TST');
            INSERT INTO logistica.tb_ordenesmantenimiento (orden_id, fk_usuario_id, fk_vehiculo_id, personal_solicita, director_administrativo, tecnico_servicios, orden_codigo,
                 orden_fecha_mantenimiento, orden_km_mantenimiento, orden_tipomantenimiento, orden_estado)
                 VALUES (9101, 9101, 9101, 9101, 9101, 9101, 'TST-MANT-9101', '2026-01-15', 10150, 'CORRECTIVO', 'ENTREGADO'),
                        (9102, 9101, 9101, 9101, 9101, 9101, 'TST-MANT-9102', '2026-04-20', 11050, 'CORRECTIVO', 'RECIBIDO'),
                        (9103, 9101, 9101, 9101, 9101, 9101, 'TST-MANT-9103', '2026-05-01', 11100, 'CORRECTIVO', 'ANULADA');
            INSERT INTO logistica.tb_mantenimiento_trabajos (fk_usuario_id, fk_orden_id, trabajo_descripcion)
                 VALUES (9101, 9101, 'Cambio de motor de arranque'), (9101, 9102, 'CAMBIO MOTOR DE ARRANQUE'), (9101, 9103, 'Cambio de motor de arranque');
            INSERT INTO logistica.tb_mantenimiento_facturas (fk_usuario_id, fk_orden_id, factura_tipo, factura_valor, factura_estado)
                 VALUES (9101, 9101, 'REPUESTOS', 250, 'ACTIVO'), (9101, 9101, 'MANO DE OBRA', 40, 'ACTIVO'), (9101, 9101, 'REPUESTOS', 999, 'ANULADO'),
                        (9101, 9102, 'REPUESTOS', 260, 'ACTIVO'), (9101, 9102, 'MANO DE OBRA', 45, 'ACTIVO');
            INSERT INTO logistica.tb_ordenesmovilizacion (orden_id, fk_usuario_id, fk_unidad_id, operador_id, director_administrativo, orden_codigo, orden_codigo_serie, orden_serie,
                 orden_destino, orden_motivo_salida, personal_solicita, orden_hora_salida, orden_kilometraje_salida, orden_kilometraje_entrada, orden_estado)
                 VALUES (9101, 9101, 9101, 9101, 9101, 'TST-MOV-9101', 0, 0, 'QUITO', 'TRAMITE', 9101, '2026-05-10 08:00', 11200, 11500, 'ESTACION');
            SET session_replication_role = origin;
            INSERT INTO admin.tb_usuario_rol (fk_usuario_id, fk_rol_id) SELECT 9101, rol_id FROM admin.tb_roles WHERE rol_codigo = 'ADM_BITACORA_VEHICULOS';");

        $socket = stream_socket_server('tcp://127.0.0.1:0');
        self::$puerto = (int) substr(strrchr(stream_socket_get_name($socket, false), ':'), 1);
        fclose($socket);
        $env = array_merge(getenv(), [
            'BCBSD_JWT_SECRET' => self::SECRETO, 'BCBSD_DB_HOST' => $host, 'BCBSD_DB_PORT' => $port,
            'BCBSD_DB_NAME' => getenv('BCBSD_TEST_DB_NAME'), 'BCBSD_DB_USER' => getenv('BCBSD_TEST_DB_USER') ?: 'postgres',
            'BCBSD_DB_PASS' => getenv('BCBSD_TEST_DB_PASS') ?: '',
        ]);
        self::$servidor = proc_open([PHP_BINARY, '-S', '127.0.0.1:' . self::$puerto, '-t', dirname(__DIR__, 2)],
            [1 => ['file', '/dev/null', 'w'], 2 => ['file', sys_get_temp_dir() . '/bcbsd-api-bitacora.log', 'w']], $pipes, dirname(__DIR__, 2), $env);
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
            DELETE FROM logistica.tb_ordenesmantenimiento WHERE fk_vehiculo_id BETWEEN 9101 AND 9199;
            DELETE FROM logistica.tb_ordenesabastecimiento WHERE orden_id BETWEEN 9101 AND 9199;
            DELETE FROM logistica.tb_ordenesmovilizacion WHERE orden_id BETWEEN 9101 AND 9199;
            DELETE FROM administrativo.tb_vehiculos WHERE vehiculo_id BETWEEN 9101 AND 9199;
            DELETE FROM admin.tb_usuario_rol WHERE fk_usuario_id BETWEEN 9101 AND 9199;
            DELETE FROM admin.tb_usuarios WHERE usuario_id BETWEEN 9101 AND 9199;");
    }

    protected function setUp(): void
    {
        if (!self::$pdo) {
            $this->markTestSkipped('Defina BCBSD_TEST_DB_NAME para ejecutar las pruebas de integración');
        }
    }

    private function api(string $ruta, int $usuario = 9101): array
    {
        $token = jwtEmitir(['sub' => $usuario, 'tipo' => 'usuario'], 600, self::SECRETO);
        $ctx = stream_context_create(['http' => ['method' => 'GET', 'ignore_errors' => true, 'timeout' => 30, 'header' => "Authorization: Bearer $token"]]);
        $texto = file_get_contents('http://127.0.0.1:' . self::$puerto . '/servicios/administrativo/bitacora/' . $ruta, false, $ctx);
        return [(int) explode(' ', $http_response_header[0])[1], json_decode($texto, true), $texto];
    }

    public function testVehiculo(): void
    {
        [$st, $r, $t] = $this->api('getBitacoraVehiculo.php?id=9101&desde=2026-01-01&hasta=2026-06-30');
        $this->assertSame(200, $st, $t);
        $ind = $r['indicadores'];
        // km: menor lectura del período 10150 (mantenimiento), mayor 11500 (regreso de la movilización)
        $this->assertEquals(1350, $ind['km_recorridos']);
        $this->assertEquals(11500, $ind['km_actual']);
        // combustible: solo VALIDADAS del período (3 cargas); la de diciembre solo sirve de referencia para el primer tramo
        $this->assertSame(3, $ind['combustible']['cargas']);
        $this->assertEqualsWithDelta(37, $ind['combustible']['galones'], 0.001);
        $this->assertEqualsWithDelta(900 / 37, $ind['combustible']['rendimiento'], 0.01);
        $this->assertCount(3, $r['tramos']);
        $this->assertEquals(300, $r['tramos'][0]['km_recorridos']);
        // mantenimiento: la anulada y la factura anulada no cuentan
        $this->assertSame(2, $ind['mantenimiento']['ordenes']);
        $this->assertEqualsWithDelta(595, $ind['mantenimiento']['total'], 0.001);
        $this->assertEqualsWithDelta(510, $ind['mantenimiento']['por_rubro']['REPUESTOS'], 0.001);
        $this->assertSame(1, count($ind['trabajos_repetidos']));
        $this->assertSame(2, $ind['trabajos_repetidos'][0]['veces']);
        // comparación: solo 9102 tiene rendimiento (9103 sin datos, 9104 es de otro año)
        $this->assertCount(2, $r['pares']);
        $this->assertEqualsWithDelta(30, $r['comparacion']['rendimiento']['promedio_pares'], 0.01);
        $this->assertSame(1, $r['comparacion']['rendimiento']['pares_con_dato']);
        $codigos = array_column($r['alertas'], 'tipo');
        $this->assertContains('TRABAJO_REPETIDO', $codigos);
        $this->assertContains('RENDIMIENTO_BAJO', $codigos);
        // historial: más reciente primero, sin anuladas ni cargas no validadas
        $tipos = array_column($r['eventos'], 'tipo');
        $this->assertSame('MOVILIZACION', $tipos[0]);
        $this->assertEquals(['COMBUSTIBLE' => 3, 'MANTENIMIENTO' => 2, 'MOVILIZACION' => 1], array_count_values($tipos));
        // gasto mensual: 6 meses; enero = 290 de mantenimiento
        $this->assertCount(6, $r['gasto_mensual']);
        $this->assertEqualsWithDelta(290, $r['gasto_mensual'][0]['total'], 0.001);
    }

    public function testFlota(): void
    {
        [$st, $r, $t] = $this->api('getBitacoraFlota.php?desde=2026-01-01&hasta=2026-06-30');
        $this->assertSame(200, $st, $t);
        $filas = array_column($r['vehiculos'], null, 'vehiculo_id');
        $this->assertEqualsWithDelta(30, $filas[9102]['rendimiento'], 0.01);
        $this->assertSame(2, $filas[9101]['pares']);
        $this->assertSame(0, $filas[9104]['pares']);
        $this->assertNotEmpty($filas[9101]['alertas']);
        $this->assertNull($filas[9103]['rendimiento']);
    }

    public function testValidaciones(): void
    {
        [$st] = $this->api('getBitacoraVehiculo.php?desde=2026-01-01');
        $this->assertSame(400, $st);
        [$st] = $this->api('getBitacoraVehiculo.php?id=999999');
        $this->assertSame(404, $st);
        [$st] = $this->api('getBitacoraFlota.php?desde=2026-06-01&hasta=2026-01-01');
        $this->assertSame(400, $st);
        [$st] = $this->api('getBitacoraFlota.php', 9102); // sin el privilegio
        $this->assertSame(403, $st);
    }
}
