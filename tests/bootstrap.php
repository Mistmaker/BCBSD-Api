<?php
// Configuración fija para las pruebas: no depende de config.local.php ni de la base de datos.
define('DB_HOST', 'localhost');
define('DB_USER', 'test');
define('DB_PASS', 'test');
define('DB_NAME', 'test');
define('JWT_SECPWD', str_repeat('k', 64));
define('JWT_EXP_SECONDS', 28800);
// Documentos de las pruebas en una carpeta temporal (nunca en documentos/ del repositorio)
define('DOCS_DIR', sys_get_temp_dir() . '/bcbsd-docs-unit-' . getmypid());

require_once __DIR__ . '/../classes/auth.php';
