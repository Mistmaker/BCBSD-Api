<?php
require_once __DIR__ . '/../../classes/auth.php';
$auth = requireAuth();
// Compatibilidad: antes devolvía SELECT * (incluidas las claves). Ahora usa el mismo listado seguro de servicios/admin.
require __DIR__ . '/../admin/getUsuarios.php';
