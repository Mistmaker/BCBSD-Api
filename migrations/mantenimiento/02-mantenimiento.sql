-- =============================================================================
-- MÓDULO DE MANTENIMIENTO VEHICULAR
-- Basado en el esquema logistica del sistema anterior (db_cbsd). Diferencias:
--   * Las órdenes referencian administrativo.tb_vehiculos (antes logistica.tb_unidades).
--   * El plan de mantenimiento se asigna al vehículo (administrativo.tb_vehiculos.fk_plan_id).
--   * El kilometraje actual se calcula con administrativo.vw_vehiculos_kilometraje
--     (antes: seguimiento de flotas, que no existe en el sistema nuevo).
--   * Las validaciones de duplicados de los triggers se reemplazan por índices únicos.
-- Requiere: 01-institucion.sql, administrativo.tb_vehiculos, tthh.tb_personal_puestos, admin.tb_usuarios.
-- =============================================================================

-- PLANES PREVENTIVOS (uno por modelo de vehículo) ----------------------------
CREATE TABLE IF NOT EXISTS logistica.tb_planesmantenimiento (
    plan_id SERIAL NOT NULL PRIMARY KEY,
    plan_registro timestamp without time zone DEFAULT ('now'::text)::timestamp(0) with time zone,
    plan_estado text DEFAULT 'ACTIVO'::text,
    fk_usuario_id integer REFERENCES admin.tb_usuarios(usuario_id),
    plan_modelo text NOT NULL,
    plan_observaciones text
);
CREATE UNIQUE INDEX IF NOT EXISTS ux_planesmantenimiento_modelo ON logistica.tb_planesmantenimiento (upper(plan_modelo));

-- Reglas: cada cuántos km (desde un km inicial) se hace un mantenimiento
CREATE TABLE IF NOT EXISTS logistica.tb_reglasmantenimiento (
    mantenimiento_id SERIAL NOT NULL PRIMARY KEY,
    mantenimiento_registro timestamp without time zone DEFAULT ('now'::text)::timestamp(0) with time zone,
    mantenimiento_estado text DEFAULT 'ACTIVO'::text,
    fk_usuario_id integer REFERENCES admin.tb_usuarios(usuario_id),
    fk_plan_id integer NOT NULL REFERENCES logistica.tb_planesmantenimiento(plan_id) ON DELETE CASCADE,
    mantenimiento_km_inicio integer NOT NULL DEFAULT 0 CHECK (mantenimiento_km_inicio >= 0),
    mantenimiento_km_intervalo integer NOT NULL CHECK (mantenimiento_km_intervalo > 0)
);

-- Catálogo de recursos / repuestos / trabajos estándar
CREATE TABLE IF NOT EXISTS logistica.tb_recursosmantenimiento (
    recurso_id SERIAL NOT NULL PRIMARY KEY,
    recurso_registro timestamp without time zone DEFAULT ('now'::text)::timestamp(0) with time zone,
    recurso_estado text DEFAULT 'ACTIVO'::text,
    fk_usuario_id integer REFERENCES admin.tb_usuarios(usuario_id),
    recurso_tipo text,
    recurso_codigo text,
    recurso_descripcion text NOT NULL
);
CREATE UNIQUE INDEX IF NOT EXISTS ux_recursosmantenimiento_codigo ON logistica.tb_recursosmantenimiento (upper(recurso_codigo)) WHERE recurso_codigo IS NOT NULL AND recurso_codigo <> '';
CREATE UNIQUE INDEX IF NOT EXISTS ux_recursosmantenimiento_descripcion ON logistica.tb_recursosmantenimiento (upper(recurso_descripcion));

-- Recursos que incluye cada regla
CREATE TABLE IF NOT EXISTS logistica.tb_mantenimiento_recursos (
    regla_id SERIAL NOT NULL PRIMARY KEY,
    fk_mantenimiento_id integer NOT NULL REFERENCES logistica.tb_reglasmantenimiento(mantenimiento_id) ON DELETE CASCADE,
    fk_recurso_id integer NOT NULL REFERENCES logistica.tb_recursosmantenimiento(recurso_id),
    UNIQUE (fk_mantenimiento_id, fk_recurso_id)
);


-- CONTRATOS DE MANTENIMIENTO -------------------------------------------------
-- Contrato general anual del parque automotor y contratos por vigencia tecnológica (vehículos nuevos).
-- Cada contrato tiene un tope por rubro (partida presupuestaria) que no se puede superar.
CREATE TABLE IF NOT EXISTS logistica.tb_contratosmantenimiento (
    contrato_id SERIAL NOT NULL PRIMARY KEY,
    contrato_registro timestamp without time zone DEFAULT ('now'::text)::timestamp(0) with time zone,
    contrato_estado text NOT NULL DEFAULT 'VIGENTE'::text,             -- VIGENTE | FINALIZADO | ANULADO
    fk_usuario_id integer REFERENCES admin.tb_usuarios(usuario_id),
    contrato_codigo text NOT NULL,                                     -- código del proceso, ej. CB-GADM-SD-DA-2025-0008-OC
    contrato_tipo text NOT NULL DEFAULT 'GENERAL'::text,               -- GENERAL | VIGENCIA TECNOLÓGICA
    contrato_objeto text,
    contrato_fecha_inicio date,
    contrato_fecha_fin date,
    contrato_taller text NOT NULL,                                     -- taller / contratista
    contrato_ruc text,
    contrato_representante_legal text,
    administrador_contrato integer REFERENCES tthh.tb_personal_puestos(ppersonal_id),
    contrato_monto numeric(12,2) NOT NULL DEFAULT 0 CHECK (contrato_monto >= 0)
);
ALTER TABLE logistica.tb_contratosmantenimiento ADD COLUMN IF NOT EXISTS contrato_nombre_corto text;  -- ej. MANTENIMIENTO MOTOCICLETAS (número de bitácora)
CREATE UNIQUE INDEX IF NOT EXISTS ux_contratosmantenimiento_codigo ON logistica.tb_contratosmantenimiento (upper(contrato_codigo));

CREATE TABLE IF NOT EXISTS logistica.tb_contratosmantenimiento_partidas (
    partida_id SERIAL NOT NULL PRIMARY KEY,
    fk_contrato_id integer NOT NULL REFERENCES logistica.tb_contratosmantenimiento(contrato_id) ON DELETE CASCADE,
    partida_rubro text NOT NULL,                                       -- MANO DE OBRA | REPUESTOS | ACEITES Y LUBRICANTES
    partida_codigo text,                                               -- partida presupuestaria
    partida_monto numeric(12,2) NOT NULL CHECK (partida_monto >= 0),
    UNIQUE (fk_contrato_id, partida_rubro)
);

-- Vehículos cubiertos (contratos por vigencia tecnológica). Sin filas = cubre a todos los vehículos.
CREATE TABLE IF NOT EXISTS logistica.tb_contratosmantenimiento_vehiculos (
    fk_contrato_id integer NOT NULL REFERENCES logistica.tb_contratosmantenimiento(contrato_id) ON DELETE CASCADE,
    fk_vehiculo_id integer NOT NULL REFERENCES administrativo.tb_vehiculos(vehiculo_id),
    PRIMARY KEY (fk_contrato_id, fk_vehiculo_id)
);

ALTER TABLE administrativo.tb_vehiculos
    ADD COLUMN IF NOT EXISTS fk_plan_id integer REFERENCES logistica.tb_planesmantenimiento(plan_id);

-- ÓRDENES DE MANTENIMIENTO ---------------------------------------------------
CREATE TABLE IF NOT EXISTS logistica.tb_ordenesmantenimiento (
    orden_id SERIAL NOT NULL PRIMARY KEY,
    orden_registro timestamp without time zone DEFAULT ('now'::text)::timestamp(0) with time zone,
    orden_estado text DEFAULT 'MANTENIMIENTO'::text,          -- MANTENIMIENTO (en taller) | RECIBIDO (valores) | ENTREGADO (acta) | ANULADA
    fk_usuario_id integer NOT NULL REFERENCES admin.tb_usuarios(usuario_id),
    fk_vehiculo_id integer NOT NULL REFERENCES administrativo.tb_vehiculos(vehiculo_id),
    personal_solicita integer NOT NULL REFERENCES tthh.tb_personal_puestos(ppersonal_id),
    director_administrativo integer NOT NULL REFERENCES tthh.tb_personal_puestos(ppersonal_id),
    tecnico_servicios integer NOT NULL REFERENCES tthh.tb_personal_puestos(ppersonal_id),
    tecnico_puesto text,
    orden_codigo text NOT NULL UNIQUE,                          -- SIGLAS + año + ODM + serie (CBSD26ODM00010)
    orden_serie integer NOT NULL DEFAULT 0,                     -- número de orden ("ORDEN DE MANTENIMIENTO No. 005")
    orden_tipomantenimiento text DEFAULT 'CORRECTIVO'::text,  -- CORRECTIVO | PREVENTIVO | PREVENTIVO Y CORRECTIVO
    orden_fecha_mantenimiento_tipo text DEFAULT 'SISTEMA'::text,
    orden_fecha_mantenimiento timestamp without time zone NOT NULL,
    orden_km_mantenimiento numeric(10,2) NOT NULL,
    ultimo_km_mantenimiento numeric(10,2),
    ultimo_fecha_mantenimiento date,
    orden_proximomantenimiento numeric(10,2),
    orden_fecha_entrega date,                                   -- fecha de entrega del informe de pago
    orden_observaciones text,
    orden_fecha_recepcion date,                                 -- fecha del acta entrega-recepción
    orden_quien_recepcion text,
    orden_cargo_recepcion text
);
ALTER TABLE logistica.tb_ordenesmantenimiento ADD COLUMN IF NOT EXISTS orden_taller text;   -- taller (órdenes del sistema anterior; las nuevas usan el contrato)
ALTER TABLE logistica.tb_ordenesmantenimiento ADD COLUMN IF NOT EXISTS fk_contrato_id integer REFERENCES logistica.tb_contratosmantenimiento(contrato_id);
ALTER TABLE logistica.tb_ordenesmantenimiento ADD COLUMN IF NOT EXISTS orden_informe_numero text;            -- número del informe de pago
ALTER TABLE logistica.tb_ordenesmantenimiento ADD COLUMN IF NOT EXISTS orden_informe_serie integer NOT NULL DEFAULT 0;
UPDATE logistica.tb_ordenesmantenimiento SET orden_estado = 'ENTREGADO' WHERE orden_estado = 'FINALIZADA';
CREATE INDEX IF NOT EXISTS ix_ordenesmantenimiento_vehiculo ON logistica.tb_ordenesmantenimiento (fk_vehiculo_id, orden_fecha_mantenimiento DESC);

CREATE TABLE IF NOT EXISTS logistica.tb_mantenimiento_trabajos (     -- trabajos a realizar (novedades reportadas por el custodio)
    trabajo_id SERIAL NOT NULL PRIMARY KEY,
    trabajo_registro timestamp without time zone DEFAULT ('now'::text)::timestamp(0) with time zone,
    trabajo_estado text DEFAULT 'ACTIVO'::text,
    fk_usuario_id integer NOT NULL REFERENCES admin.tb_usuarios(usuario_id),
    fk_orden_id integer NOT NULL REFERENCES logistica.tb_ordenesmantenimiento(orden_id) ON DELETE CASCADE,
    trabajo_descripcion text NOT NULL
);

CREATE TABLE IF NOT EXISTS logistica.tb_mantenimiento_sugeridos (     -- trabajos sugeridos por el contratista (taller)
    trabajo_id SERIAL NOT NULL PRIMARY KEY,
    trabajo_registro timestamp without time zone DEFAULT ('now'::text)::timestamp(0) with time zone,
    trabajo_estado text DEFAULT 'ACTIVO'::text,
    fk_usuario_id integer NOT NULL REFERENCES admin.tb_usuarios(usuario_id),
    fk_orden_id integer NOT NULL REFERENCES logistica.tb_ordenesmantenimiento(orden_id) ON DELETE CASCADE,
    trabajo_descripcion text NOT NULL
);

CREATE TABLE IF NOT EXISTS logistica.tb_mantenimiento_facturas (
    factura_id SERIAL NOT NULL PRIMARY KEY,
    factura_registro timestamp without time zone DEFAULT ('now'::text)::timestamp(0) with time zone,
    factura_estado text DEFAULT 'ACTIVO'::text,
    fk_usuario_id integer REFERENCES admin.tb_usuarios(usuario_id),
    fk_personal_id integer,                                     -- histórico del sistema anterior
    fk_orden_id integer NOT NULL REFERENCES logistica.tb_ordenesmantenimiento(orden_id) ON DELETE CASCADE,
    factura_tipo text NOT NULL,                                 -- rubro: MANO DE OBRA | REPUESTOS | ACEITES Y LUBRICANTES (parámetro MANT_RUBROS)
    factura_numero text,
    factura_valor numeric(10,2),
    factura_descripcion text
);

CREATE TABLE IF NOT EXISTS logistica.tb_mantenimiento_anexos (
    anexo_id SERIAL NOT NULL PRIMARY KEY,
    anexo_registro timestamp without time zone DEFAULT ('now'::text)::timestamp(0) with time zone,
    fk_usuario_id integer NOT NULL REFERENCES admin.tb_usuarios(usuario_id),
    fk_orden_id integer NOT NULL REFERENCES logistica.tb_ordenesmantenimiento(orden_id) ON DELETE CASCADE,
    anexo_descripcion text NOT NULL
);

-- INFORMES DE MANTENIMIENTO (agrupan varias órdenes) -----------------------
CREATE TABLE IF NOT EXISTS logistica.tb_informemantenimiento (
    informe_id SERIAL NOT NULL PRIMARY KEY,
    informe_registro timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0),
    informe_estado text DEFAULT 'GENERADO'::text,              -- GENERADO | ANULADO
    fk_usuario_id integer NOT NULL REFERENCES admin.tb_usuarios(usuario_id),
    tecnico_servicios integer NOT NULL REFERENCES tthh.tb_personal_puestos(ppersonal_id),
    tecnico_cargo text,
    director_administrativo integer NOT NULL REFERENCES tthh.tb_personal_puestos(ppersonal_id),
    informe_numero text,
    informe_serie integer NOT NULL DEFAULT 0,
    informe_fecha date NOT NULL DEFAULT CURRENT_DATE,
    informe_taller text,
    informe_detalle text
);

ALTER TABLE logistica.tb_informemantenimiento ADD COLUMN IF NOT EXISTS informe_serie integer NOT NULL DEFAULT 0;
ALTER TABLE logistica.tb_informemantenimiento ADD COLUMN IF NOT EXISTS fk_contrato_id integer REFERENCES logistica.tb_contratosmantenimiento(contrato_id);
CREATE INDEX IF NOT EXISTS ix_informemantenimiento_numero ON logistica.tb_informemantenimiento (upper(informe_numero));

CREATE TABLE IF NOT EXISTS logistica.tb_informe_ordenesmantenimiento (
    fk_informe_id integer NOT NULL REFERENCES logistica.tb_informemantenimiento(informe_id) ON DELETE CASCADE,
    fk_orden_id integer NOT NULL REFERENCES logistica.tb_ordenesmantenimiento(orden_id),
    PRIMARY KEY (fk_informe_id, fk_orden_id)
);

-- KILOMETRAJE ACTUAL DE CADA VEHÍCULO --------------------------------------
-- Mayor kilometraje registrado en movilización, abastecimiento, partes y mantenimiento.
CREATE OR REPLACE VIEW administrativo.vw_vehiculos_kilometraje AS
SELECT v.vehiculo_id,
       GREATEST(
           COALESCE((SELECT MAX(GREATEST(COALESCE(m.orden_kilometraje_salida, 0), COALESCE(m.orden_kilometraje_entrada, 0)))
                       FROM logistica.tb_ordenesmovilizacion m
                      WHERE m.fk_unidad_id = v.vehiculo_id AND m.orden_estado <> 'ORDEN ANULADA'), 0),
           COALESCE((SELECT MAX(a.orden_kilometraje) FROM logistica.tb_ordenesabastecimiento a
                      WHERE a.fk_unidad_id = v.vehiculo_id), 0),
           COALESCE((SELECT MAX(d.orden_detalle_kilometraje) FROM logistica.tb_detalleordenesabastecimiento d
                      WHERE d.fk_unidad_id = v.vehiculo_id), 0),
           COALESCE((SELECT MAX(GREATEST(COALESCE(p.parte_unidad_kilometraje_salida, 0), COALESCE(p.parte_unidad_kilometraje_ingreso, 0)))
                       FROM operaciones.tb_parte_unidades p WHERE p.fk_vehiculo_id = v.vehiculo_id), 0),
           COALESCE((SELECT MAX(o.orden_km_mantenimiento) FROM logistica.tb_ordenesmantenimiento o
                      WHERE o.fk_vehiculo_id = v.vehiculo_id AND o.orden_estado <> 'ANULADA'), 0)
       )::numeric(12,2) AS vehiculo_kilometraje
FROM administrativo.tb_vehiculos v;

-- LISTADO DE ÓRDENES CON NOMBRES ------------------------------------------
DROP VIEW IF EXISTS logistica.vw_ordenesmantenimiento;
CREATE VIEW logistica.vw_ordenesmantenimiento AS
SELECT o.*,
       v.vehiculo_sigla, v.vehiculo_placa, v.vehiculo_marca, v.vehiculo_modelo, v.vehiculo_tipo, v.vehiculo_chasis, v.vehiculo_motor,
       s.nombre_completo AS s_nombre, s.puesto_nombre AS s_puesto, s.persona_doc_identidad AS s_cc,
       da.nombre_completo AS da_nombre, da.puesto_nombre AS da_puesto, da.persona_doc_identidad AS da_cc,
       t.nombre_completo AS psg_nombre, t.puesto_nombre AS psg_puesto, t.persona_doc_identidad AS psg_cc,
       (SELECT count(*) FROM logistica.tb_mantenimiento_trabajos tr WHERE tr.fk_orden_id = o.orden_id) AS trabajos,
       (SELECT COALESCE(sum(f.factura_valor), 0) FROM logistica.tb_mantenimiento_facturas f
         WHERE f.fk_orden_id = o.orden_id AND f.factura_estado = 'ACTIVO') AS total_facturas,
       (SELECT COALESCE(json_object_agg(r.factura_tipo, r.total), '{}'::json) FROM (
            SELECT f.factura_tipo, sum(COALESCE(f.factura_valor, 0)) AS total FROM logistica.tb_mantenimiento_facturas f
             WHERE f.fk_orden_id = o.orden_id AND f.factura_estado = 'ACTIVO' GROUP BY f.factura_tipo) r) AS totales_rubro,
       inf.informe_id, inf.informe_numero, inf.informe_fecha,
       c.contrato_codigo, c.contrato_tipo, COALESCE(c.contrato_taller, o.orden_taller) AS taller,
       u.usuario_login AS usuario
FROM logistica.tb_ordenesmantenimiento o
JOIN administrativo.tb_vehiculos v ON v.vehiculo_id = o.fk_vehiculo_id
LEFT JOIN logistica.tb_contratosmantenimiento c ON c.contrato_id = o.fk_contrato_id
LEFT JOIN tthh.vw_personal_simple s ON s.ppersonal_id = o.personal_solicita
LEFT JOIN tthh.vw_personal_simple da ON da.ppersonal_id = o.director_administrativo
LEFT JOIN tthh.vw_personal_simple t ON t.ppersonal_id = o.tecnico_servicios
LEFT JOIN admin.tb_usuarios u ON u.usuario_id = o.fk_usuario_id
LEFT JOIN LATERAL (
    SELECT im.informe_id, im.informe_numero, im.informe_fecha
      FROM logistica.tb_informe_ordenesmantenimiento io
      JOIN logistica.tb_informemantenimiento im ON im.informe_id = io.fk_informe_id AND im.informe_estado <> 'ANULADO'
     WHERE io.fk_orden_id = o.orden_id
     ORDER BY im.informe_id DESC LIMIT 1) inf ON true;

DROP VIEW IF EXISTS logistica.vw_informemantenimiento;
CREATE VIEW logistica.vw_informemantenimiento AS
SELECT i.*,
       t.nombre_completo AS psg_nombre, t.puesto_nombre AS psg_puesto, t.persona_doc_identidad AS psg_cc,
       da.nombre_completo AS da_nombre, da.puesto_nombre AS da_puesto, da.persona_doc_identidad AS da_cc,
       (SELECT count(*) FROM logistica.tb_informe_ordenesmantenimiento io WHERE io.fk_informe_id = i.informe_id) AS ordenes,
       (SELECT COALESCE(sum(f.factura_valor), 0) FROM logistica.tb_mantenimiento_facturas f
          JOIN logistica.tb_informe_ordenesmantenimiento io ON io.fk_orden_id = f.fk_orden_id
         WHERE io.fk_informe_id = i.informe_id AND f.factura_estado = 'ACTIVO') AS total,
       u.usuario_login AS usuario
FROM logistica.tb_informemantenimiento i
LEFT JOIN tthh.vw_personal_simple t ON t.ppersonal_id = i.tecnico_servicios
LEFT JOIN tthh.vw_personal_simple da ON da.ppersonal_id = i.director_administrativo
LEFT JOIN admin.tb_usuarios u ON u.usuario_id = i.fk_usuario_id;

-- SALDO DE CADA CONTRATO POR RUBRO --------------------------------------------
-- consumido = valores registrados en órdenes no anuladas del contrato
DROP VIEW IF EXISTS logistica.vw_contratosmantenimiento_saldo;
CREATE VIEW logistica.vw_contratosmantenimiento_saldo AS
SELECT p.fk_contrato_id AS contrato_id, p.partida_id, p.partida_rubro, p.partida_codigo, p.partida_monto AS asignado,
       COALESCE(sum(f.factura_valor) FILTER (WHERE o.orden_id IS NOT NULL), 0)::numeric(12,2) AS consumido,
       (p.partida_monto - COALESCE(sum(f.factura_valor) FILTER (WHERE o.orden_id IS NOT NULL), 0))::numeric(12,2) AS saldo
FROM logistica.tb_contratosmantenimiento_partidas p
LEFT JOIN logistica.tb_ordenesmantenimiento o ON o.fk_contrato_id = p.fk_contrato_id AND o.orden_estado <> 'ANULADA'
LEFT JOIN logistica.tb_mantenimiento_facturas f ON f.fk_orden_id = o.orden_id AND f.factura_estado = 'ACTIVO' AND f.factura_tipo = p.partida_rubro
GROUP BY p.fk_contrato_id, p.partida_id, p.partida_rubro, p.partida_codigo, p.partida_monto;

-- MENÚ Y PRIVILEGIOS: ver 04-privilegios.sql
