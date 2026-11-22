<?php
require_once __DIR__ . '/../../../classes/auth.php';
$auth = requireAuth();
require_once __DIR__ . '/../../../classes/operadores.php';
// GET -> catálogos para el ingreso rápido: licencias activas, puestos (para quien aún no tiene uno) y parámetros
apiMetodo(['GET']);
try {
    $db = new Database();
    requirePermiso($db, 'ADM_OPERADORES', 'ADM_OPERADOR_GESTIONAR');
    $dias = (int) parametro($db, 'OPER_DIAS_AVISO_LICENCIA', 30);
    $db->query("SELECT licencia_id, licencia_tipo, licencia_categoria, licencia_descripcion FROM resources.tb_licenciasdeconducir
                 WHERE COALESCE(licencia_estado, 'ACTIVO') = 'ACTIVO' ORDER BY licencia_tipo DESC, licencia_categoria");
    $licencias = $db->resultset();
    $db->query("SELECT puesto_id, puesto_nombre, puesto_modalidad FROM tthh.tb_puestos
                 WHERE COALESCE(puesto_estado, 'ACTIVO') NOT IN ('INACTIVO', 'ELIMINADO') ORDER BY puesto_modalidad, puesto_nombre");
    jsonResponse(['licencias' => $licencias, 'puestos' => $db->resultset(), 'dias_aviso' => $dias]);
} catch (Throwable $e) {
    apiError($e, 'Error al obtener los catálogos');
}
