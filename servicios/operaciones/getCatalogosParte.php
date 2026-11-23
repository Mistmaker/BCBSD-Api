<?php
require_once __DIR__ . '/../../classes/auth.php';
$auth = requireAuth();
require_once __DIR__ . '/../../classes/partes.php';
// GET -> listas del formulario de partes: estaciones, vehículos, personal operativo (personal_id), tipos de auxilio,
// causas, recursos (equipos, materiales, insumos), formas de aviso, apoyos, tipos de incendio, naturalezas,
// rangos, pelotones y claves (parámetros) y la ubicación por defecto (parámetro OPE_PARTE_PARROQUIA_ID).
apiMetodo(['GET']);
try {
    $db = new Database();
    requirePermiso($db, 'OPE_PARTES', 'OPE_PARTES_ESTADISTICAS');
    // Parámetros antes de preparar otras consultas (la clase Database comparte una sentencia)
    $rangos = parteLista(parametro($db, 'OPE_PARTE_RANGOS', ''));
    $pelotones = parteLista(parametro($db, 'OPE_PARTE_PELOTONES', ''));
    $claves = parteLista(parametro($db, 'OPE_PARTE_CLAVES', ''));
    $parroquia = (int) parametro($db, 'OPE_PARTE_PARROQUIA_ID', 0);
    $lista = function (string $sql) use ($db): array {
        $db->query($sql);
        return $db->resultset();
    };
    $ubicacion = null;
    if ($parroquia > 0) {
        $db->query('SELECT pa.parish_id AS parroquia, t.town_id AS canton, t.fk_state_id AS provincia
                      FROM resources.parishes pa JOIN resources.towns t ON t.town_id = pa.fk_town_id WHERE pa.parish_id = :p');
        $db->bind(':p', $parroquia);
        $ubicacion = $db->single() ?: null;
    }
    jsonResponse([
        'estaciones' => $lista("SELECT estacion_id, estacion_nombre FROM operaciones.tb_estaciones
                                 WHERE COALESCE(estacion_estado, 'ACTIVO') NOT IN ('INACTIVO', 'ELIMINADO') ORDER BY estacion_nombre"),
        'vehiculos' => $lista("SELECT vehiculo_id, vehiculo_placa, vehiculo_sigla, vehiculo_tipo, fk_estacion_id
                                 FROM administrativo.tb_vehiculos WHERE COALESCE(vehiculo_estado, 'ACTIVO') NOT IN ('INACTIVO', 'BAJA', 'ELIMINADO')
                                ORDER BY vehiculo_sigla, vehiculo_placa"),
        'personal' => $lista("SELECT * FROM (SELECT DISTINCT ON (p.personal_id) p.personal_id, pe.persona_doc_identidad, pe.persona_apellidos, pe.persona_nombres, pu.puesto_nombre,
                                     concat(pe.persona_apellidos, ' ', pe.persona_nombres) AS nombre, p.fk_estacion_id
                                FROM tthh.tb_personal p
                                JOIN resources.tb_personas pe ON pe.persona_id = p.fk_persona_id
                                LEFT JOIN tthh.tb_personal_puestos pp ON pp.fk_personal_id = p.personal_id AND pp.ppersonal_estado = 'EN FUNCIONES'
                                LEFT JOIN tthh.tb_puestos pu ON pu.puesto_id = pp.fk_puesto_id
                               WHERE COALESCE(p.personal_estado, 'EN FUNCIONES') = 'EN FUNCIONES'
                               ORDER BY p.personal_id, (pu.puesto_modalidad = 'OPERATIVO') DESC NULLS LAST) x ORDER BY nombre"),
        'tipos_auxilio' => $lista("SELECT tipo_auxilio_id, tipo_auxilio_clasificacion AS clasificacion, tipo_auxilio_subclasificacion AS subclasificacion,
                                          tipo_auxilio_uso_tipo AS uso_tipo FROM operaciones.tb_partes_catalogo_tipos_auxilio
                                    WHERE tipo_auxilio_estado = 'ACTIVO' ORDER BY tipo_auxilio_orden, tipo_auxilio_id"),
        'causas' => $lista("SELECT causa_id, causa_clasificacion AS clasificacion, causa_descripcion AS descripcion
                              FROM operaciones.tb_partes_catalogo_causas WHERE causa_estado = 'ACTIVO' ORDER BY causa_orden, causa_id"),
        'recursos' => $lista("SELECT recurso_id, recurso_tipo, recurso_descripcion FROM operaciones.tb_partes_catalogo_recursos
                               WHERE recurso_estado = 'ACTIVO' ORDER BY recurso_tipo, recurso_descripcion"),
        'formas_aviso' => array_column($lista("SELECT forma_aviso_descripcion AS d FROM operaciones.tb_partes_catalogo_forma_aviso
                                                WHERE forma_aviso_estado = 'ACTIVO' ORDER BY forma_aviso_id"), 'd'),
        'apoyos' => array_column($lista("SELECT apoyo_descripcion AS d FROM operaciones.tb_partes_catalogo_apoyo WHERE apoyo_estado = 'ACTIVO' ORDER BY apoyo_id"), 'd'),
        'tipos_incendio' => $lista("SELECT tipo_incendio_id AS id, tipo_incendio_descripcion AS descripcion FROM operaciones.tb_partes_catalogo_tipos_incendio
                                     WHERE tipo_incendio_estado = 'ACTIVO' ORDER BY tipo_incendio_id"),
        'naturalezas' => $lista("SELECT naturaleza_id AS id, naturaleza_descripcion AS descripcion FROM operaciones.tb_partes_catalogo_naturalezas
                                  WHERE naturaleza_estado = 'ACTIVO' ORDER BY naturaleza_id"),
        'rangos' => $rangos, 'pelotones' => $pelotones, 'claves' => $claves,
        'ubicacion' => $ubicacion,
    ]);
} catch (Throwable $e) {
    apiError($e, 'Error al consultar los catálogos del parte');
}
