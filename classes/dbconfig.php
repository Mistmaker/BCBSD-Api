<?php
/*
 * Configuración del API.
 *
 * Los valores sensibles NO se guardan en el repositorio. Se toman, en este orden:
 *   1. classes/config.local.php (no versionado; ver config.local.example.php)
 *   2. Variables de entorno (en Apache: SetEnv BCBSD_DB_PASS "..." en el VirtualHost)
 *   3. Valores por defecto no sensibles definidos abajo
 */
$__configLocal = __DIR__ . '/config.local.php';
if (is_file($__configLocal)) {
    require_once $__configLocal;
}
unset($__configLocal);

if (!function_exists('bcbsdEnv')) {
    function bcbsdEnv(string $nombre, $porDefecto = null)
    {
        $valor = getenv($nombre);
        if ($valor === false && isset($_SERVER[$nombre])) {
            $valor = $_SERVER[$nombre];
        }
        return ($valor === false || $valor === null || $valor === '') ? $porDefecto : $valor;
    }
}

defined('DB_HOST') || define('DB_HOST', bcbsdEnv('BCBSD_DB_HOST', 'localhost'));
defined('DB_USER') || define('DB_USER', bcbsdEnv('BCBSD_DB_USER', 'postgres'));
defined('DB_PASS') || define('DB_PASS', bcbsdEnv('BCBSD_DB_PASS', ''));
defined('DB_NAME') || define('DB_NAME', bcbsdEnv('BCBSD_DB_NAME', 'db_bcbsd'));

// Clave para firmar los JSON Web Token (HS256). Mínimo 32 caracteres (exigido por firebase/php-jwt v7).
defined('JWT_SECPWD') || define('JWT_SECPWD', bcbsdEnv('BCBSD_JWT_SECRET', ''));
// Duración de la sesión en segundos. Por defecto 8 horas (28800).
defined('JWT_EXP_SECONDS') || define('JWT_EXP_SECONDS', (int) bcbsdEnv('BCBSD_JWT_EXP_SECONDS', 28800));
