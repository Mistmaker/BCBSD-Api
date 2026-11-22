<?php
require_once __DIR__ . '/../../../classes/auth.php';
$auth = requireAuth();
require_once __DIR__ . '/../../../classes/peticionMateriales.php';
// GET            -> peticiones de materiales (?anio=AAAA, por defecto todas)
// GET ?id=N      -> una, con sus ítems
// GET ?config=1  -> datos para el formulario: unidades sugeridas, quien autoriza por defecto, ciudad de la institución
apiMetodo(['GET']);
try {
    $db = new Database();
    requirePermiso($db, 'ADM_PETICIONES_MATERIALES', 'ADM_PETICION_MATERIALES_GESTIONAR');
    if (!empty($_GET['config'])) {
        $unidades = mantLista(parametro($db, 'PDM_UNIDADES', 'UNIDAD|CAJA|PAQUETE|RESMA|ROLLO|METRO|LITRO|GALÓN|KILOGRAMO'));
        $autoriza = pdmAutorizaPorDefecto($db);
        $ciudad = institucion($db)['sistema_ciudad'] ?? '';
        jsonResponse(['unidades' => $unidades, 'autoriza' => $autoriza, 'ciudad' => $ciudad]);
    }
    $id = apiParamId();
    if ($id !== null) {
        $p = pdmListar($db, 'AND p.peticion_id = :id', [':id' => $id])[0] ?? null;
        $p ? jsonResponse($p + ['detalle' => pdmDetalle($db, $id)]) : jsonResponse(['error' => 'Petición no encontrada'], 404);
    }
    $anio = isset($_GET['anio']) && ctype_digit((string) $_GET['anio']) ? (int) $_GET['anio'] : null;
    jsonResponse($anio ? pdmListar($db, 'AND p.peticion_anio = :a', [':a' => $anio]) : pdmListar($db));
} catch (Throwable $e) {
    apiError($e, 'Error al obtener las peticiones de materiales');
}
