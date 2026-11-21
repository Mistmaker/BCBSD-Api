<?php

use Firebase\JWT\JWT;
use PHPUnit\Framework\TestCase;

final class AuthTest extends TestCase
{
    public function testEmiteTokenConDuracionDeOchoHorasPorDefecto(): void
    {
        $ahora = time();
        $claims = jwtValidar(jwtEmitir(['sub' => 7, 'tipo' => 'usuario'], null, null, $ahora));

        $this->assertSame(7, $claims->sub);
        $this->assertSame('usuario', $claims->tipo);
        $this->assertSame(JWT_ISSUER, $claims->iss);
        $this->assertSame(28800, $claims->exp - $claims->iat);
    }

    public function testDuracionEsParametrizable(): void
    {
        $claims = jwtValidar(jwtEmitir(['sub' => 1], 600));
        $this->assertSame(600, $claims->exp - $claims->iat);
    }

    public function testRechazaTokenExpirado(): void
    {
        $token = jwtEmitir(['sub' => 1], 60, null, time() - 3600);

        $this->expectException(AuthException::class);
        $this->expectExceptionCode(401);
        $this->expectExceptionMessage('expiró');
        jwtValidar($token);
    }

    public function testRechazaTokenFirmadoConOtraClave(): void
    {
        $token = jwtEmitir(['sub' => 1], null, str_repeat('x', 64));

        $this->expectException(AuthException::class);
        $this->expectExceptionCode(401);
        jwtValidar($token);
    }

    public function testRechazaTokenAlterado(): void
    {
        [$h, $p, $s] = explode('.', jwtEmitir(['sub' => 1]));
        $payload = json_decode(base64_decode(strtr($p, '-_', '+/')), true);
        $payload['sub'] = 113; // intento de suplantar al administrador
        $p = rtrim(strtr(base64_encode(json_encode($payload)), '+/', '-_'), '=');

        $this->expectException(AuthException::class);
        jwtValidar("$h.$p.$s");
    }

    public function testRechazaTokenDeOtroEmisor(): void
    {
        $token = JWT::encode(['iss' => 'otro', 'sub' => 1, 'exp' => time() + 60], JWT_SECPWD, 'HS256');

        $this->expectException(AuthException::class);
        jwtValidar($token);
    }

    public function testRechazaTokenSinSub(): void
    {
        $token = JWT::encode(['iss' => JWT_ISSUER, 'exp' => time() + 60], JWT_SECPWD, 'HS256');

        $this->expectException(AuthException::class);
        jwtValidar($token);
    }

    public function testRechazaAlgoritmoNone(): void
    {
        $h = rtrim(strtr(base64_encode('{"alg":"none","typ":"JWT"}'), '+/', '-_'), '=');
        $p = rtrim(strtr(base64_encode(json_encode(['iss' => JWT_ISSUER, 'sub' => 1, 'exp' => time() + 60])), '+/', '-_'), '=');

        $this->expectException(AuthException::class);
        jwtValidar("$h.$p.");
    }

    public function testExigeClaveDeAlMenos32Caracteres(): void
    {
        $this->expectException(AuthException::class);
        $this->expectExceptionCode(500);
        jwtEmitir(['sub' => 1], null, 'corta');
    }

    /** @dataProvider encabezados */
    public function testExtraeBearerToken(array $server, ?string $esperado): void
    {
        $this->assertSame($esperado, obtenerBearerToken($server));
    }

    public static function encabezados(): array
    {
        return [
            'estándar' => [['HTTP_AUTHORIZATION' => 'Bearer abc.def.ghi'], 'abc.def.ghi'],
            'redirección de Apache' => [['REDIRECT_HTTP_AUTHORIZATION' => 'Bearer abc.def.ghi'], 'abc.def.ghi'],
            'minúsculas' => [['HTTP_AUTHORIZATION' => 'bearer abc'], 'abc'],
            'sin encabezado' => [[], null],
            'esquema Basic' => [['HTTP_AUTHORIZATION' => 'Basic dXNlcjpwYXNz'], null],
            'Bearer vacío' => [['HTTP_AUTHORIZATION' => 'Bearer '], null],
        ];
    }

    public function testAuthUsuarioIdSoloParaUsuariosAdministrativos(): void
    {
        $GLOBALS['BCBSD_AUTH'] = (object) ['sub' => '25', 'tipo' => 'usuario'];
        $this->assertSame(25, authUsuarioId());

        $GLOBALS['BCBSD_AUTH'] = (object) ['sub' => 9, 'tipo' => 'voluntario'];
        $this->assertNull(authUsuarioId());

        unset($GLOBALS['BCBSD_AUTH']);
        $this->assertNull(authUsuarioId());
    }
}
