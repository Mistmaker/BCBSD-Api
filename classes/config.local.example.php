<?php
/*
 * Copie este archivo como classes/config.local.php en el servidor y complete los valores.
 * classes/config.local.php está en .gitignore: nunca lo suba al repositorio.
 */
define('DB_HOST', 'localhost');
define('DB_PORT', 5432);
define('DB_USER', 'postgres');
define('DB_PASS', 'CAMBIAR');
define('DB_NAME', 'db_bcbsd');

// Genere una clave aleatoria de al menos 32 caracteres, por ejemplo:
//   php -r "echo bin2hex(random_bytes(32)), PHP_EOL;"
define('JWT_SECPWD', 'CAMBIAR_POR_UNA_CLAVE_ALEATORIA_DE_64_CARACTERES_HEX');

// Duración de la sesión en segundos (8 horas = 28800).
define('JWT_EXP_SECONDS', 28800);

// Carpeta de documentos subidos (licencias, cédulas...). Recomendado fuera de la carpeta pública de Apache.
// define('DOCS_DIR', '/var/lib/bcbsd/documentos');
