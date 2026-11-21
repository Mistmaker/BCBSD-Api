<?php

use PHPUnit\Framework\TestCase;

/**
 * Prueba de punta a punta: levanta el API con el servidor embebido de PHP
 * (la configuración se pasa por variables de entorno, como haría Apache con SetEnv)
 * y verifica las respuestas HTTP de un endpoint protegido.
 */
final class HttpAuthTest extends TestCase
{
    private const SECRETO = 'secreto-de-prueba-http-de-al-menos-32-caracteres';
    private const ENDPOINT = '/servicios/auth/getRoles.php?id=1';

    /** @var resource|null */
    private static $proceso = null;
    private static int $puerto = 0;

    public static function setUpBeforeClass(): void
    {
        $socket = stream_socket_server('tcp://127.0.0.1:0');
        self::$puerto = (int) substr(strrchr(stream_socket_get_name($socket, false), ':'), 1);
        fclose($socket);

        $env = array_merge(getenv(), ['BCBSD_JWT_SECRET' => self::SECRETO, 'BCBSD_DB_HOST' => '127.0.0.1', 'BCBSD_DB_PASS' => 'x']);
        $cmd = [PHP_BINARY, '-S', '127.0.0.1:' . self::$puerto, '-t', dirname(__DIR__)];
        self::$proceso = proc_open($cmd, [1 => ['file', '/dev/null', 'w'], 2 => ['file', '/dev/null', 'w']], $pipes, dirname(__DIR__), $env);

        for ($i = 0; $i < 50; $i++) {
            if (@fsockopen('127.0.0.1', self::$puerto)) {
                return;
            }
            usleep(100000);
        }
        self::fail('No se pudo iniciar el servidor PHP embebido');
    }

    public static function tearDownAfterClass(): void
    {
        if (self::$proceso) {
            proc_terminate(self::$proceso);
            proc_close(self::$proceso);
        }
    }

    /** @return array{0:int,1:array<string,string>,2:string} */
    private function solicitar(string $metodo, array $encabezados = []): array
    {
        $contexto = stream_context_create(['http' => [
            'method' => $metodo,
            'header' => implode("\r\n", $encabezados),
            'ignore_errors' => true,
            'timeout' => 10,
        ]]);
        $cuerpo = (string) file_get_contents('http://127.0.0.1:' . self::$puerto . self::ENDPOINT, false, $contexto);
        $estado = (int) explode(' ', $http_response_header[0])[1];
        $cabeceras = [];
        foreach (array_slice($http_response_header, 1) as $linea) {
            [$k, $v] = array_map('trim', explode(':', $linea, 2)) + [1 => ''];
            $cabeceras[strtolower($k)] = $v;
        }
        return [$estado, $cabeceras, $cuerpo];
    }

    private function token(int $duracion = 3600, ?int $ahora = null): string
    {
        return jwtEmitir(['sub' => 1, 'tipo' => 'usuario'], $duracion, self::SECRETO, $ahora);
    }

    public function testPreflightPermiteEncabezadoAuthorization(): void
    {
        [$estado, $cabeceras] = $this->solicitar('OPTIONS');
        $this->assertSame(200, $estado);
        $this->assertStringContainsString('Authorization', $cabeceras['access-control-allow-headers'] ?? '');
        $this->assertSame('*', $cabeceras['access-control-allow-origin'] ?? null);
    }

    public function testSinTokenResponde401(): void
    {
        [$estado, $cabeceras, $cuerpo] = $this->solicitar('GET');
        $this->assertSame(401, $estado);
        $this->assertSame('*', $cabeceras['access-control-allow-origin'] ?? null, 'El front debe poder leer el 401');
        $this->assertSame('No autorizado', json_decode($cuerpo, true)['error'] ?? null);
    }

    public function testTokenExpiradoResponde401(): void
    {
        [$estado, , $cuerpo] = $this->solicitar('GET', ['Authorization: Bearer ' . $this->token(60, time() - 7200)]);
        $this->assertSame(401, $estado);
        $this->assertStringContainsString('expiró', json_decode($cuerpo, true)['msg'] ?? '');
    }

    public function testTokenConOtraFirmaResponde401(): void
    {
        $falso = jwtEmitir(['sub' => 1], 3600, str_repeat('z', 64));
        [$estado] = $this->solicitar('GET', ['Authorization: Bearer ' . $falso]);
        $this->assertSame(401, $estado);
    }

    public function testTokenValidoPasaLaAutenticacion(): void
    {
        // Sin base de datos el endpoint puede fallar después, pero nunca con 401.
        [$estado] = $this->solicitar('GET', ['Authorization: Bearer ' . $this->token()]);
        $this->assertNotSame(401, $estado);
    }
}
