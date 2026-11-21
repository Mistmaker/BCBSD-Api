-- =============================================================================
-- IMPORTACIÓN DESDE EL SISTEMA ANTERIOR (db_cbsd) - institución y mantenimiento
--
-- Ejecutar en la base NUEVA, después de 01 y 02, con psql:
--   psql -d db_bcbsd -v ON_ERROR_STOP=1 \
--        -v legacy_conn="dbname=db_cbsd host=localhost user=postgres password=XXXX" \
--        -f 03-importacion-db_cbsd.sql
--
-- La cadena de conexión NO se guarda en el repositorio.
-- Requisitos: vehículos, personal (tthh.tb_personal_puestos) y usuarios ya importados
-- con script-2.sql (conservan los mismos IDs del sistema anterior).
-- Es re-ejecutable: los registros ya importados se omiten (ON CONFLICT DO NOTHING).
-- =============================================================================
\set ON_ERROR_STOP on
CREATE EXTENSION IF NOT EXISTS dblink;
SELECT dblink_connect('legacy', :'legacy_conn');

BEGIN;

-- INSTITUCIÓN ------------------------------------------------------------------
INSERT INTO admin.tb_sistema (
    sistema_id,
    sistema_ruc,
    sistema_nombre,
    sistema_slogan,
    sistema_descripcion,
    sistema_header,
    sistema_footer,
    sistema_mision,
    sistema_vision,
    sistema_historia,
    sistema_ciudad,
    sistema_direccion,
    sistema_telefono,
    sistema_celular,
    sistema_correo,
    sistema_sitioweb,
    sistema_path_img,
    sistema_ip,
    fecha_constitucion,
    sistema_msgcontacto
)
SELECT t.sistema_id, t.sistema_ruc, t.sistema_nombre, t.sistema_slogan, t.sistema_descripcion, t.sistema_header, t.sistema_footer, t.sistema_mision, t.sistema_vision, t.sistema_historia, t.sistema_ciudad, t.sistema_direccion, t.sistema_telefono, t.sistema_celular, t.sistema_correo, t.sistema_sitioweb, t.sistema_path_img, t.sistema_ip, t.fecha_constitucion, t.sistema_msgcontacto
FROM dblink('legacy', $$
    SELECT sistema_id, sistema_ruc, sistema_nombre, sistema_slogan, sistema_descripcion, sistema_header, sistema_footer, sistema_mision, sistema_vision, sistema_historia, sistema_ciudad, sistema_direccion, sistema_telefono, sistema_celular, sistema_correo, sistema_sitioweb, sistema_path_img, sistema_ip, fecha_constitucion, sistema_msgcontacto FROM admin.tb_sistema
$$) AS t (
    sistema_id integer,
    sistema_ruc text,
    sistema_nombre text,
    sistema_slogan text,
    sistema_descripcion text,
    sistema_header text,
    sistema_footer text,
    sistema_mision text,
    sistema_vision text,
    sistema_historia text,
    sistema_ciudad text,
    sistema_direccion text,
    sistema_telefono text,
    sistema_celular text,
    sistema_correo text,
    sistema_sitioweb text,
    sistema_path_img text,
    sistema_ip text,
    fecha_constitucion text,
    sistema_msgcontacto text
)
ON CONFLICT (sistema_id) DO NOTHING;
INSERT INTO admin.tb_params (
    param_key,
    param_value,
    param_type,
    param_name,
    param_modulo
)
SELECT t.param_key, t.param_value, t.param_type, t.param_name, t.param_modulo
FROM dblink('legacy', $$
    SELECT param_key, param_value, param_type, param_name, param_modulo FROM admin.tb_params
$$) AS t (
    param_key text,
    param_value text,
    param_type text,
    param_name text,
    param_modulo text
)
ON CONFLICT (param_key) DO NOTHING;

-- PLANES, REGLAS Y RECURSOS --------------------------------------------------
INSERT INTO logistica.tb_planesmantenimiento (
    plan_id,
    plan_registro,
    plan_estado,
    fk_usuario_id,
    plan_modelo,
    plan_observaciones
)
SELECT t.plan_id, t.plan_registro, t.plan_estado, t.fk_usuario_id, t.plan_modelo, t.plan_observaciones
FROM dblink('legacy', $$
    SELECT plan_id, plan_registro, plan_estado, fk_usuario_id, plan_modelo, plan_observaciones FROM logistica.tb_planesmantenimiento
$$) AS t (
    plan_id integer,
    plan_registro timestamp,
    plan_estado text,
    fk_usuario_id integer,
    plan_modelo text,
    plan_observaciones text
)
WHERE t.fk_usuario_id IS NULL OR EXISTS (SELECT 1 FROM admin.tb_usuarios u WHERE u.usuario_id = t.fk_usuario_id)
ON CONFLICT (plan_id) DO NOTHING;
INSERT INTO logistica.tb_reglasmantenimiento (
    mantenimiento_id,
    mantenimiento_registro,
    mantenimiento_estado,
    fk_usuario_id,
    fk_plan_id,
    mantenimiento_km_inicio,
    mantenimiento_km_intervalo
)
SELECT t.mantenimiento_id, t.mantenimiento_registro, t.mantenimiento_estado, t.fk_usuario_id, t.fk_plan_id, t.mantenimiento_km_inicio, t.mantenimiento_km_intervalo
FROM dblink('legacy', $$
    SELECT mantenimiento_id, mantenimiento_registro, mantenimiento_estado, fk_usuario_id, fk_plan_id, COALESCE(mantenimiento_km_inicio, 0), mantenimiento_km_intervalo FROM logistica.tb_reglasmantenimiento WHERE mantenimiento_km_intervalo > 0
$$) AS t (
    mantenimiento_id integer,
    mantenimiento_registro timestamp,
    mantenimiento_estado text,
    fk_usuario_id integer,
    fk_plan_id integer,
    mantenimiento_km_inicio integer,
    mantenimiento_km_intervalo integer
)
WHERE EXISTS (SELECT 1 FROM logistica.tb_planesmantenimiento p WHERE p.plan_id = t.fk_plan_id)
ON CONFLICT (mantenimiento_id) DO NOTHING;
INSERT INTO logistica.tb_recursosmantenimiento (
    recurso_id,
    recurso_registro,
    recurso_estado,
    fk_usuario_id,
    recurso_tipo,
    recurso_codigo,
    recurso_descripcion
)
SELECT t.recurso_id, t.recurso_registro, t.recurso_estado, t.fk_usuario_id, t.recurso_tipo, t.recurso_codigo, t.recurso_descripcion
FROM dblink('legacy', $$
    SELECT recurso_id, recurso_registro, recurso_estado, fk_usuario_id, recurso_tipo, recurso_codigo, recurso_descripcion FROM logistica.tb_recursosmantenimiento
$$) AS t (
    recurso_id integer,
    recurso_registro timestamp,
    recurso_estado text,
    fk_usuario_id integer,
    recurso_tipo text,
    recurso_codigo text,
    recurso_descripcion text
)
ON CONFLICT DO NOTHING;
INSERT INTO logistica.tb_mantenimiento_recursos (
    regla_id,
    fk_mantenimiento_id,
    fk_recurso_id
)
SELECT t.regla_id, t.fk_mantenimiento_id, t.fk_recurso_id
FROM dblink('legacy', $$
    SELECT regla_id, fk_mantenimiento_id, fk_recurso_id FROM logistica.tb_mantenimiento_recursos
$$) AS t (
    regla_id integer,
    fk_mantenimiento_id integer,
    fk_recurso_id integer
)
WHERE EXISTS (SELECT 1 FROM logistica.tb_reglasmantenimiento r WHERE r.mantenimiento_id = t.fk_mantenimiento_id) AND EXISTS (SELECT 1 FROM logistica.tb_recursosmantenimiento r WHERE r.recurso_id = t.fk_recurso_id)
ON CONFLICT DO NOTHING;

-- Plan asignado a cada vehículo (antes en logistica.tb_unidades)
UPDATE administrativo.tb_vehiculos v
   SET fk_plan_id = t.fk_plan_id
  FROM dblink('legacy', $$ SELECT fk_vehiculo_id, fk_plan_id FROM logistica.tb_unidades WHERE fk_plan_id IS NOT NULL $$)
       AS t (fk_vehiculo_id integer, fk_plan_id integer)
 WHERE v.vehiculo_id = t.fk_vehiculo_id
   AND v.fk_plan_id IS NULL
   AND EXISTS (SELECT 1 FROM logistica.tb_planesmantenimiento p WHERE p.plan_id = t.fk_plan_id);

-- ÓRDENES DE MANTENIMIENTO (unidad -> vehículo) ----------------------------------
INSERT INTO logistica.tb_ordenesmantenimiento (
    orden_id,
    orden_registro,
    orden_estado,
    fk_usuario_id,
    fk_vehiculo_id,
    personal_solicita,
    director_administrativo,
    tecnico_servicios,
    tecnico_puesto,
    orden_codigo,
    orden_serie,
    orden_tipomantenimiento,
    orden_fecha_mantenimiento_tipo,
    orden_fecha_mantenimiento,
    orden_km_mantenimiento,
    ultimo_km_mantenimiento,
    ultimo_fecha_mantenimiento,
    orden_proximomantenimiento,
    orden_fecha_entrega,
    orden_observaciones,
    orden_fecha_recepcion,
    orden_quien_recepcion,
    orden_cargo_recepcion
)
SELECT t.orden_id, t.orden_registro, t.orden_estado, t.fk_usuario_id, t.fk_vehiculo_id, t.personal_solicita, t.director_administrativo, t.tecnico_servicios, t.tecnico_puesto, t.orden_codigo, t.orden_serie, t.orden_tipomantenimiento, t.orden_fecha_mantenimiento_tipo, t.orden_fecha_mantenimiento, t.orden_km_mantenimiento, t.ultimo_km_mantenimiento, t.ultimo_fecha_mantenimiento, t.orden_proximomantenimiento, t.orden_fecha_entrega, t.orden_observaciones, t.orden_fecha_recepcion, t.orden_quien_recepcion, t.orden_cargo_recepcion
FROM dblink('legacy', $$
    SELECT o.orden_id, o.orden_registro, o.orden_estado, o.fk_usuario_id, u.fk_vehiculo_id, o.personal_solicita, o.director_administrativo,
           o.tecnico_servicios, o.tecnico_puesto, o.orden_codigo, COALESCE(o.orden_serie, 0), o.orden_tipomantenimiento, o.orden_fecha_mantenimiento_tipo,
           o.orden_fecha_mantenimiento, o.orden_km_mantenimiento, o.ultimo_km_mantenimiento, o.ultimo_fecha_mantenimiento, o.orden_proximomantenimiento,
           o.orden_fecha_entrega, o.orden_observaciones, o.orden_fecha_recepcion, o.orden_quien_recepcion, o.orden_cargo_recepcion
      FROM logistica.tb_ordenesmantenimiento o
      JOIN logistica.tb_unidades u ON u.unidad_id = o.fk_unidad_id
$$) AS t (
    orden_id integer,
    orden_registro timestamp,
    orden_estado text,
    fk_usuario_id integer,
    fk_vehiculo_id integer,
    personal_solicita integer,
    director_administrativo integer,
    tecnico_servicios integer,
    tecnico_puesto text,
    orden_codigo text,
    orden_serie integer,
    orden_tipomantenimiento text,
    orden_fecha_mantenimiento_tipo text,
    orden_fecha_mantenimiento timestamp,
    orden_km_mantenimiento numeric(10,2),
    ultimo_km_mantenimiento numeric(10,2),
    ultimo_fecha_mantenimiento date,
    orden_proximomantenimiento numeric(10,2),
    orden_fecha_entrega date,
    orden_observaciones text,
    orden_fecha_recepcion date,
    orden_quien_recepcion text,
    orden_cargo_recepcion text
)
WHERE EXISTS (SELECT 1 FROM administrativo.tb_vehiculos v WHERE v.vehiculo_id = t.fk_vehiculo_id)
  AND EXISTS (SELECT 1 FROM admin.tb_usuarios x WHERE x.usuario_id = t.fk_usuario_id)
  AND EXISTS (SELECT 1 FROM tthh.tb_personal_puestos x WHERE x.ppersonal_id = t.personal_solicita)
  AND EXISTS (SELECT 1 FROM tthh.tb_personal_puestos x WHERE x.ppersonal_id = t.director_administrativo)
  AND EXISTS (SELECT 1 FROM tthh.tb_personal_puestos x WHERE x.ppersonal_id = t.tecnico_servicios)
ON CONFLICT DO NOTHING;
INSERT INTO logistica.tb_mantenimiento_trabajos (
    trabajo_id,
    trabajo_registro,
    trabajo_estado,
    fk_usuario_id,
    fk_orden_id,
    trabajo_descripcion
)
SELECT t.trabajo_id, t.trabajo_registro, t.trabajo_estado, t.fk_usuario_id, t.fk_orden_id, t.trabajo_descripcion
FROM dblink('legacy', $$
    SELECT trabajo_id, trabajo_registro, trabajo_estado, fk_usuario_id, fk_orden_id, trabajo_descripcion FROM logistica.tb_mantenimiento_trabajos
$$) AS t (
    trabajo_id integer,
    trabajo_registro timestamp,
    trabajo_estado text,
    fk_usuario_id integer,
    fk_orden_id integer,
    trabajo_descripcion text
)
WHERE EXISTS (SELECT 1 FROM logistica.tb_ordenesmantenimiento o WHERE o.orden_id = t.fk_orden_id)
ON CONFLICT (trabajo_id) DO NOTHING;
INSERT INTO logistica.tb_mantenimiento_sugeridos (
    trabajo_id,
    trabajo_registro,
    trabajo_estado,
    fk_usuario_id,
    fk_orden_id,
    trabajo_descripcion
)
SELECT t.trabajo_id, t.trabajo_registro, t.trabajo_estado, t.fk_usuario_id, t.fk_orden_id, t.trabajo_descripcion
FROM dblink('legacy', $$
    SELECT trabajo_id, trabajo_registro, trabajo_estado, fk_usuario_id, fk_orden_id, trabajo_descripcion FROM logistica.tb_mantenimiento_sugeridos
$$) AS t (
    trabajo_id integer,
    trabajo_registro timestamp,
    trabajo_estado text,
    fk_usuario_id integer,
    fk_orden_id integer,
    trabajo_descripcion text
)
WHERE EXISTS (SELECT 1 FROM logistica.tb_ordenesmantenimiento o WHERE o.orden_id = t.fk_orden_id)
ON CONFLICT (trabajo_id) DO NOTHING;
INSERT INTO logistica.tb_mantenimiento_facturas (
    factura_id,
    factura_registro,
    factura_estado,
    fk_personal_id,
    fk_orden_id,
    factura_tipo,
    factura_numero,
    factura_valor,
    factura_descripcion
)
SELECT t.factura_id, t.factura_registro, t.factura_estado, t.fk_personal_id, t.fk_orden_id, t.factura_tipo, t.factura_numero, t.factura_valor, t.factura_descripcion
FROM dblink('legacy', $$
    SELECT factura_id, factura_registro, factura_estado, fk_personal_id, fk_orden_id, factura_tipo, factura_numero, factura_valor, factura_descripcion FROM logistica.tb_mantenimiento_facturas
$$) AS t (
    factura_id integer,
    factura_registro timestamp,
    factura_estado text,
    fk_personal_id integer,
    fk_orden_id integer,
    factura_tipo text,
    factura_numero text,
    factura_valor numeric(10,2),
    factura_descripcion text
)
WHERE EXISTS (SELECT 1 FROM logistica.tb_ordenesmantenimiento o WHERE o.orden_id = t.fk_orden_id)
ON CONFLICT (factura_id) DO NOTHING;
INSERT INTO logistica.tb_mantenimiento_anexos (
    anexo_id,
    anexo_registro,
    fk_usuario_id,
    fk_orden_id,
    anexo_descripcion
)
SELECT t.anexo_id, t.anexo_registro, t.fk_usuario_id, t.fk_orden_id, t.anexo_descripcion
FROM dblink('legacy', $$
    SELECT anexo_id, anexo_registro, fk_usuario_id, fk_orden_id, anexo_descripcion FROM logistica.tb_mantenimiento_anexos
$$) AS t (
    anexo_id integer,
    anexo_registro timestamp,
    fk_usuario_id integer,
    fk_orden_id integer,
    anexo_descripcion text
)
WHERE EXISTS (SELECT 1 FROM logistica.tb_ordenesmantenimiento o WHERE o.orden_id = t.fk_orden_id)
ON CONFLICT (anexo_id) DO NOTHING;

-- INFORMES ---------------------------------------------------------------------
INSERT INTO logistica.tb_informemantenimiento (
    informe_id,
    informe_registro,
    informe_estado,
    fk_usuario_id,
    tecnico_servicios,
    tecnico_cargo,
    director_administrativo,
    informe_numero,
    informe_fecha,
    informe_taller,
    informe_detalle
)
SELECT t.informe_id, t.informe_registro, t.informe_estado, t.fk_usuario_id, t.tecnico_servicios, t.tecnico_cargo, t.director_administrativo, t.informe_numero, t.informe_fecha, t.informe_taller, t.informe_detalle
FROM dblink('legacy', $$
    SELECT informe_id, informe_registro, informe_estado, fk_usuario_id, tecnico_servicios, tecnico_cargo, director_administrativo, informe_numero, COALESCE(informe_fecha, informe_registro::date), informe_taller, informe_detalle FROM logistica.tb_informemantenimiento
$$) AS t (
    informe_id integer,
    informe_registro timestamp,
    informe_estado text,
    fk_usuario_id integer,
    tecnico_servicios integer,
    tecnico_cargo text,
    director_administrativo integer,
    informe_numero text,
    informe_fecha date,
    informe_taller text,
    informe_detalle text
)
WHERE EXISTS (SELECT 1 FROM admin.tb_usuarios x WHERE x.usuario_id = t.fk_usuario_id)
  AND EXISTS (SELECT 1 FROM tthh.tb_personal_puestos x WHERE x.ppersonal_id = t.tecnico_servicios)
  AND EXISTS (SELECT 1 FROM tthh.tb_personal_puestos x WHERE x.ppersonal_id = t.director_administrativo)
ON CONFLICT (informe_id) DO NOTHING;
INSERT INTO logistica.tb_informe_ordenesmantenimiento (
    fk_informe_id,
    fk_orden_id
)
SELECT t.fk_informe_id, t.fk_orden_id
FROM dblink('legacy', $$
    SELECT fk_informe_id, fk_orden_id FROM logistica.tb_informe_ordenesmantenimiento
$$) AS t (
    fk_informe_id integer,
    fk_orden_id integer
)
WHERE EXISTS (SELECT 1 FROM logistica.tb_informemantenimiento i WHERE i.informe_id = t.fk_informe_id) AND EXISTS (SELECT 1 FROM logistica.tb_ordenesmantenimiento o WHERE o.orden_id = t.fk_orden_id)
ON CONFLICT DO NOTHING;

-- SECUENCIAS --------------------------------------------------------------------
SELECT setval(pg_get_serial_sequence('admin.tb_sistema', 'sistema_id'), COALESCE((SELECT MAX(sistema_id) FROM admin.tb_sistema), 0) + 1, false);
SELECT setval(pg_get_serial_sequence('admin.tb_params', 'param_id'), COALESCE((SELECT MAX(param_id) FROM admin.tb_params), 0) + 1, false);
SELECT setval(pg_get_serial_sequence('logistica.tb_planesmantenimiento', 'plan_id'), COALESCE((SELECT MAX(plan_id) FROM logistica.tb_planesmantenimiento), 0) + 1, false);
SELECT setval(pg_get_serial_sequence('logistica.tb_reglasmantenimiento', 'mantenimiento_id'), COALESCE((SELECT MAX(mantenimiento_id) FROM logistica.tb_reglasmantenimiento), 0) + 1, false);
SELECT setval(pg_get_serial_sequence('logistica.tb_recursosmantenimiento', 'recurso_id'), COALESCE((SELECT MAX(recurso_id) FROM logistica.tb_recursosmantenimiento), 0) + 1, false);
SELECT setval(pg_get_serial_sequence('logistica.tb_mantenimiento_recursos', 'regla_id'), COALESCE((SELECT MAX(regla_id) FROM logistica.tb_mantenimiento_recursos), 0) + 1, false);
SELECT setval(pg_get_serial_sequence('logistica.tb_ordenesmantenimiento', 'orden_id'), COALESCE((SELECT MAX(orden_id) FROM logistica.tb_ordenesmantenimiento), 0) + 1, false);
SELECT setval(pg_get_serial_sequence('logistica.tb_mantenimiento_trabajos', 'trabajo_id'), COALESCE((SELECT MAX(trabajo_id) FROM logistica.tb_mantenimiento_trabajos), 0) + 1, false);
SELECT setval(pg_get_serial_sequence('logistica.tb_mantenimiento_sugeridos', 'trabajo_id'), COALESCE((SELECT MAX(trabajo_id) FROM logistica.tb_mantenimiento_sugeridos), 0) + 1, false);
SELECT setval(pg_get_serial_sequence('logistica.tb_mantenimiento_facturas', 'factura_id'), COALESCE((SELECT MAX(factura_id) FROM logistica.tb_mantenimiento_facturas), 0) + 1, false);
SELECT setval(pg_get_serial_sequence('logistica.tb_mantenimiento_anexos', 'anexo_id'), COALESCE((SELECT MAX(anexo_id) FROM logistica.tb_mantenimiento_anexos), 0) + 1, false);
SELECT setval(pg_get_serial_sequence('logistica.tb_informemantenimiento', 'informe_id'), COALESCE((SELECT MAX(informe_id) FROM logistica.tb_informemantenimiento), 0) + 1, false);

COMMIT;

-- Resumen: registros del sistema anterior que NO se importaron (vehículo, personal o usuario inexistente)
SELECT 'ordenes omitidas' AS concepto,
       (SELECT n FROM dblink('legacy', $$ SELECT count(*) FROM logistica.tb_ordenesmantenimiento $$) AS t(n bigint))
       - (SELECT count(*) FROM logistica.tb_ordenesmantenimiento) AS cantidad
UNION ALL
SELECT 'informes omitidos',
       (SELECT n FROM dblink('legacy', $$ SELECT count(*) FROM logistica.tb_informemantenimiento $$) AS t(n bigint))
       - (SELECT count(*) FROM logistica.tb_informemantenimiento);

SELECT dblink_disconnect('legacy');
