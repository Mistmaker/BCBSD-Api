<?php
/*
 * Autenticación con JSON Web Token (HS256).
 *
 * Uso en un endpoint protegido (primera instrucción después de <?php):
 *     require_once __DIR__ . '/../../classes/auth.php';
 *     $auth = requireAuth();   // responde 401 y termina si el token no es válido
 *
 * Los endpoints de login emiten el token con jwtEmitir().
 */
require_once __DIR__ . '/../vendor/autoload.php';
require_once __DIR__ . '/dbconfig.php';

use Firebase\JWT\JWT;
use Firebase\JWT\Key;

const JWT_ALG = 'HS256';
const JWT_ISSUER = 'cbsd-login-api';
const JWT_MIN_KEY_LENGTH = 32;

class AuthException extends RuntimeException
{
}

function jwtClave(?string $clave = null): string
{
    $clave = $clave ?? JWT_SECPWD;
    if (strlen($clave) < JWT_MIN_KEY_LENGTH) {
        throw new AuthException('La clave JWT no está configurada o tiene menos de ' . JWT_MIN_KEY_LENGTH . ' caracteres.', 500);
    }
    return $clave;
}

/**
 * Emite un token firmado. $claims debe incluir 'sub' (id del usuario o voluntario).
 */
function jwtEmitir(array $claims, ?int $duracion = null, ?string $clave = null, ?int $ahora = null): string
{
    $ahora = $ahora ?? time();
    $duracion = $duracion ?? JWT_EXP_SECONDS;
    $payload = array_merge([
        'iss' => JWT_ISSUER,
        'iat' => $ahora,
        'nbf' => $ahora,
        'exp' => $ahora + $duracion,
    ], $claims);
    return JWT::encode($payload, jwtClave($clave), JWT_ALG);
}

/**
 * Valida firma, emisor y vigencia. Devuelve los claims o lanza AuthException (401).
 */
function jwtValidar(string $token, ?string $clave = null): object
{
    $clave = jwtClave($clave);
    try {
        $claims = JWT::decode($token, new Key($clave, JWT_ALG));
    } catch (Firebase\JWT\ExpiredException $e) {
        throw new AuthException('La sesión expiró, inicie sesión nuevamente.', 401);
    } catch (Throwable $e) {
        throw new AuthException('Token inválido.', 401);
    }
    if (($claims->iss ?? null) !== JWT_ISSUER || !isset($claims->sub)) {
        throw new AuthException('Token inválido.', 401);
    }
    return $claims;
}

/**
 * Extrae el token del encabezado "Authorization: Bearer <token>".
 * Apache puede exponerlo como HTTP_AUTHORIZATION o REDIRECT_HTTP_AUTHORIZATION (ver .htaccess).
 */
function obtenerBearerToken(array $server): ?string
{
    $encabezado = $server['HTTP_AUTHORIZATION'] ?? $server['REDIRECT_HTTP_AUTHORIZATION'] ?? null;
    if ($encabezado === null && function_exists('apache_request_headers')) {
        foreach (apache_request_headers() as $nombre => $valor) {
            if (strcasecmp($nombre, 'Authorization') === 0) {
                $encabezado = $valor;
                break;
            }
        }
    }
    if ($encabezado && preg_match('/^\s*Bearer\s+(\S+)\s*$/i', $encabezado, $m)) {
        return $m[1];
    }
    return null;
}

function enviarCabecerasCors(): void
{
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Headers: Origin, Content-Type, Accept, Authorization');
    header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
}

/**
 * Protege el endpoint: responde la preflight OPTIONS y exige un token válido.
 * Devuelve los claims del token; también quedan en $GLOBALS['BCBSD_AUTH'].
 */
function requireAuth(): object
{
    enviarCabecerasCors();
    if (($_SERVER['REQUEST_METHOD'] ?? '') === 'OPTIONS') {
        http_response_code(200);
        exit;
    }
    try {
        $token = obtenerBearerToken($_SERVER);
        if ($token === null) {
            throw new AuthException('No autorizado: falta el token de acceso.', 401);
        }
        $claims = jwtValidar($token);
    } catch (AuthException $e) {
        http_response_code($e->getCode() ?: 401);
        header('Content-Type: application/json');
        echo json_encode(['error' => 'No autorizado', 'msg' => $e->getMessage()], JSON_UNESCAPED_UNICODE);
        exit;
    }
    $GLOBALS['BCBSD_AUTH'] = $claims;
    return $claims;
}

/** Id del usuario autenticado (solo para tokens de usuarios administrativos). */
function authUsuarioId(): ?int
{
    $claims = $GLOBALS['BCBSD_AUTH'] ?? null;
    if (!$claims || ($claims->tipo ?? 'usuario') !== 'usuario') {
        return null;
    }
    return (int) $claims->sub;
}
