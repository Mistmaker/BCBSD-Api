-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- SCRIPT 3: cambios posteriores a script.sql, script-2.sql y script_sbj_temp.sql
--   combustible, institución, mantenimiento vehicular, contratos, menús y privilegios, bitácora del vehículo, operadores, usuarios y perfiles, petición de materiales, importación de db_cbsd.
--
-- CÓMO USARLO (pgAdmin): abra el Query Tool sobre la base NUEVA (db_bcbsd), pegue TODO el archivo y ejecútelo.
--   * Se puede ejecutar varias veces: no borra tablas ni datos; lo que ya existe se omite.
--   * No toca operaciones.tb_estaciones.
--   * La importación (sección 11) solo corre si edita la línea "conexion" con la clave de la base anterior.
--   * Después: asigne los privilegios nuevos a los usuarios en Administración > Usuarios > Privilegios.
--
-- ARCHIVO GENERADO por migrations/generar-script-3.py a partir de migrations/. No lo edite a mano:
-- edite los archivos de migrations/ y vuelva a generarlo.
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


-- ======================================================================================================
-- 1. ÓRDENES DE ABASTECIMIENTO DE COMBUSTIBLE (rama joshua)
-- ======================================================================================================
-- Crear el esquema si no existe
CREATE SCHEMA IF NOT EXISTS logistica;

-- Crear la secuencia para el ID
CREATE SEQUENCE IF NOT EXISTS logistica.tb_ordenesabastecimiento_orden_id_seq
    AS INTEGER
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- Crear la tabla
CREATE TABLE IF NOT EXISTS logistica.tb_ordenesabastecimiento (
    orden_id INTEGER NOT NULL
        DEFAULT nextval('logistica.tb_ordenesabastecimiento_orden_id_seq'::regclass),

    orden_registro TIMESTAMP WITHOUT TIME ZONE
        DEFAULT LOCALTIMESTAMP(0),

    orden_estado TEXT DEFAULT 'EMITIDA',

    fk_usuario_id INTEGER NOT NULL,
    fk_unidad_id INTEGER DEFAULT NULL,
    operador_id INTEGER DEFAULT NULL,
    director_administrativo INTEGER DEFAULT NULL,
    tecnico_servicios INTEGER,

    orden_codigo TEXT NOT NULL,
    orden_codigo_serie INTEGER NOT NULL,
    orden_serie INTEGER NOT NULL DEFAULT 0,
    personal_solicita INTEGER NOT NULL,

    orden_codigo_institucion TEXT NOT null,
    orden_nro_vales INTEGER DEFAULT null,
    orden_caneca TEXT DEFAULT null,
    
    orden_fecha DATE DEFAULT NULL,
	orden_estacion_servicio TEXT default 'SINDICATO DE CHOFERES',

    orden_nro_canecas int4 DEFAULT NULL,
	orden_kilometraje int4 DEFAULT NULL,
	orden_tipo_combustible VARCHAR(30) DEFAULT NULL,
	orden_cantidad_galones int4 DEFAULT NULL,
	orden_precio_total DECIMAL(10,2) DEFAULT 0,
 	
    orden_observaciones TEXT,

    CONSTRAINT pk_tb_ordenesabastecimiento
        PRIMARY KEY (orden_id)
);

-- Vincular la secuencia con la columna orden_id
ALTER SEQUENCE logistica.tb_ordenesabastecimiento_orden_id_seq
    OWNED BY logistica.tb_ordenesabastecimiento.orden_id;

CREATE TABLE IF NOT EXISTS logistica.tb_detalleordenesabastecimiento (
	orden_detalle_id serial4 NOT NULL,
	orden_id int4 NOT NULL,
	orden_detalle_linea int4 NOT NULL,
	fk_unidad_id int4 DEFAULT NULL,
	orden_detalle_nro_canecas int4 DEFAULT NULL,
	orden_detalle_kilometraje int4 DEFAULT NULL,
	orden_detalle_tipo_combustible VARCHAR(30) DEFAULT NULL,
	orden_detalle_cantidad_galones int4 DEFAULT NULL,
	orden_detalle_precio_total DECIMAL(10,2) DEFAULT 0,
	CONSTRAINT tb_detalleordenesabastecimiento_pk PRIMARY KEY (orden_detalle_id, orden_id, orden_detalle_linea),
	CONSTRAINT tb_detalleordenesabastecimiento_fk_orden_id_fkey FOREIGN KEY (orden_id) 
	REFERENCES logistica.tb_ordenesabastecimiento(orden_id) ON DELETE RESTRICT ON UPDATE RESTRICT 
);


-- ======================================================================================================
-- 2. PARAMETRIZACIÓN DE LA INSTITUCIÓN (admin.tb_sistema, admin.tb_params)
-- ======================================================================================================
-- =============================================================================
-- PARAMETRIZACIÓN DE LA INSTITUCIÓN
-- Permite usar el sistema en distintos cuerpos de bomberos: los reportes y los
-- códigos de documentos toman nombre, siglas, logo y datos de contacto de aquí.
-- Basado en admin.tb_sistema y admin.tb_params del sistema anterior (db_cbsd).
-- =============================================================================

CREATE TABLE IF NOT EXISTS admin.tb_sistema (
    sistema_id SERIAL NOT NULL PRIMARY KEY,
    sistema_ruc text,
    sistema_nombre text NOT NULL,
    sistema_siglas text NOT NULL DEFAULT 'CBSD',            -- prefijo de códigos de documentos
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
    sistema_path_img text,                                   -- logo (ruta relativa al API)
    sistema_ip text,
    fecha_constitucion text,
    sistema_msgcontacto text,
    sistema_latitud numeric(10,6),                           -- centro por defecto de los mapas
    sistema_longitud numeric(10,6)
);
-- Datos usados en el encabezado y pie de los reportes PDF
ALTER TABLE admin.tb_sistema ADD COLUMN IF NOT EXISTS sistema_siglas text NOT NULL DEFAULT 'CBSD';
ALTER TABLE admin.tb_sistema ADD COLUMN IF NOT EXISTS sistema_facebook text;
ALTER TABLE admin.tb_sistema ADD COLUMN IF NOT EXISTS sistema_twitter text;
ALTER TABLE admin.tb_sistema ADD COLUMN IF NOT EXISTS sistema_latitud numeric(10,6);
ALTER TABLE admin.tb_sistema ADD COLUMN IF NOT EXISTS sistema_longitud numeric(10,6);

CREATE TABLE IF NOT EXISTS admin.tb_params (
    param_id SERIAL NOT NULL PRIMARY KEY,
    param_key text NOT NULL UNIQUE,
    param_value text NOT NULL,
    param_type text,
    param_name text NOT NULL,
    param_modulo text
);

-- Administradores del sistema (parametrizable por institución): reciben todos los privilegios al ejecutar script-3.
-- SIS_ADMINISTRADORES: usuario_id o login separados por | (p. ej. 113|jperez). SIS_PERFILES_ADMINISTRADOR: nombres de perfil.
INSERT INTO admin.tb_params (param_key, param_value, param_type, param_name, param_modulo) VALUES
    ('SIS_ADMINISTRADORES', '113', 'list', 'Usuarios administradores del sistema: usuario_id o login separados por |. Reciben todos los privilegios al ejecutar script-3', 'ADMINISTRACION'),
    ('SIS_PERFILES_ADMINISTRADOR', 'ADMINISTRADOR|ADMINISTRADOR DEL SISTEMA|ADMINISTRADOR SISTEMA|SUPER ADMINISTRADOR|SUPERADMINISTRADOR|SUPERADMIN|ADMIN',
     'list', 'Nombres de los perfiles de administrador (separados por |): el perfil y sus usuarios reciben todos los privilegios', 'ADMINISTRACION')
ON CONFLICT (param_key) DO NOTHING;

-- ¿El perfil es de administrador? (nombre en SIS_PERFILES_ADMINISTRADOR, sin importar mayúsculas ni espacios)
CREATE OR REPLACE FUNCTION admin.fn_perfil_es_administrador(p_perfil_id integer) RETURNS boolean LANGUAGE sql STABLE AS $f$
    SELECT EXISTS (
        SELECT 1 FROM admin.tb_perfiles p
         WHERE p.perfil_id = p_perfil_id
           AND regexp_replace(upper(trim(p.perfil_nombre)), '\s+', ' ', 'g') IN (
               SELECT regexp_replace(upper(trim(x)), '\s+', ' ', 'g')
                 FROM admin.tb_params, unnest(string_to_array(param_value, '|')) AS x
                WHERE param_key = 'SIS_PERFILES_ADMINISTRADOR' AND trim(x) <> ''));
$f$;
-- ¿El usuario es administrador? (su id o login está en SIS_ADMINISTRADORES, o su perfil es de administrador)
CREATE OR REPLACE FUNCTION admin.fn_es_administrador(p_usuario_id integer) RETURNS boolean LANGUAGE sql STABLE AS $f$
    SELECT EXISTS (
        SELECT 1 FROM admin.tb_usuarios u
         WHERE u.usuario_id = p_usuario_id
           AND (EXISTS (SELECT 1 FROM admin.tb_params, unnest(string_to_array(param_value, '|')) AS x
                         WHERE param_key = 'SIS_ADMINISTRADORES'
                           AND (trim(x) = u.usuario_id::text OR lower(trim(x)) = lower(trim(u.usuario_login))))
                OR admin.fn_perfil_es_administrador(u.fk_perfil_id)));
$f$;

-- Parámetros usados por el módulo de mantenimiento (no se sobrescriben si ya existen)
INSERT INTO admin.tb_params (param_key, param_value, param_type, param_name, param_modulo) VALUES
    ('MANT_TOLERANCIA_KM', '1000', 'integer', 'Km de anticipación para alertar un mantenimiento preventivo', 'MANTENIMIENTO'),
    ('MANT_TECNICO_PUESTO', 'ANALISTA DE SERVICIOS GENERALES', 'text', 'Cargo del técnico que firma las órdenes de mantenimiento', 'MANTENIMIENTO'),
    ('MANT_INFORME_CARGO', 'ADMINISTRADOR DE CONTRATO', 'text', 'Cargo de quien firma los informes de mantenimiento', 'MANTENIMIENTO'),
    ('MANT_RUBROS', 'MANO DE OBRA|REPUESTOS|ACEITES Y LUBRICANTES', 'list', 'Rubros presupuestarios del desglose de pago (separados por |)', 'MANTENIMIENTO'),
    ('MANT_CARGOS_RESPONSABLE', 'ADMINISTRADOR DE LA ORDEN DE COMPRA|ANALISTA DE SERVICIOS GENERALES|ADMINISTRADOR DE CONTRATO', 'list', 'Cargos posibles del responsable del registro (separados por |)', 'MANTENIMIENTO'),
    ('MANT_FORMATO_INFORME', '{SIGLAS}-DA-{AAAA}-{NNNN}-I', 'text', 'Sugerencia (+1) del número de informe de pago: es texto libre con la secuencia documental institucional ({SIGLAS} {AA} {AAAA} {N} {NNN} {NNNN})', 'MANTENIMIENTO'),
    ('MANT_FORMATO_BITACORA', 'BITÁCORA {NN}-{NOMBRE} {CONTRATO}', 'text', 'Número sugerido de bitácora ({NN} correlativo del contrato, {NOMBRE} nombre corto, {CONTRATO} código)', 'MANTENIMIENTO'),
    ('MANT_TIPOS_CONTRATO', 'GENERAL|VIGENCIA TECNOLÓGICA', 'list', 'Tipos de contrato de mantenimiento (separados por |)', 'MANTENIMIENTO'),
    ('MANT_DIRECTOR_PUESTO_ID', '4', 'integer', 'ID del puesto (tthh.tb_puestos.puesto_id) del director administrativo: firma quien tenga ese puesto EN FUNCIONES (titular o subrogante)', 'MANTENIMIENTO')
ON CONFLICT (param_key) DO NOTHING;

-- Ajustes a parámetros ya creados (re-ejecutable): el cargo pasó a llamarse ANALISTA DE SERVICIOS GENERALES
-- y el director administrativo ya no se elige: es quien tiene el puesto MANT_DIRECTOR_PUESTO_ID EN FUNCIONES.
UPDATE admin.tb_params SET param_value = replace(param_value, 'PROFESIONAL TÉCNICO EN SERVICIOS GENERALES', 'ANALISTA DE SERVICIOS GENERALES')
 WHERE param_key IN ('MANT_TECNICO_PUESTO', 'MANT_CARGOS_RESPONSABLE') AND param_value LIKE '%PROFESIONAL TÉCNICO EN SERVICIOS GENERALES%';
UPDATE admin.tb_params SET param_name = 'ID del puesto (tthh.tb_puestos.puesto_id) del director administrativo: firma quien tenga ese puesto EN FUNCIONES (titular o subrogante)'
 WHERE param_key = 'MANT_DIRECTOR_PUESTO_ID';


-- ======================================================================================================
-- 3. MANTENIMIENTO VEHICULAR (planes, contratos, órdenes, bitácoras, vistas)
-- ======================================================================================================
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


-- ======================================================================================================
-- 4. MENÚS Y PRIVILEGIOS (admin.tb_roles con rol_codigo)
-- ======================================================================================================
-- =============================================================================
-- PRIVILEGIOS (admin.tb_roles) - re-ejecutable
--
-- Lógica de la tabla de roles:
--   * rol_path con valor  -> ACCESO: abre una pantalla y aparece en el menú (ej. /admin/ordenes-movilizacion).
--   * rol_path NULL       -> PERMISO DE ACCIÓN dentro de una pantalla (ej. "Ingresar nuevo vehiculo").
-- Mejora: rol_codigo es una clave fija que usa el sistema (front y API) para verificar privilegios,
-- en lugar del rol_id, que cambia de una base de datos a otra.
-- Todos los roles aparecen en Administración > Usuarios > Privilegios para asignarlos.
-- =============================================================================

ALTER TABLE admin.tb_roles ADD COLUMN IF NOT EXISTS rol_codigo text;
CREATE UNIQUE INDEX IF NOT EXISTS ux_roles_codigo ON admin.tb_roles (rol_codigo) WHERE rol_codigo IS NOT NULL;
COMMENT ON COLUMN admin.tb_roles.rol_path IS 'Con ruta: acceso a una pantalla (menú). Sin ruta: permiso de acción dentro de una pantalla.';
COMMENT ON COLUMN admin.tb_roles.rol_codigo IS 'Clave fija usada por el sistema para verificar el privilegio (no depende del rol_id).';

-- Submódulos de la Dirección Administrativa (modulo "Dir. Administrativa")
INSERT INTO admin.tb_submodulos (fk_modulo_id, submodulo_nombre)
SELECT m.modulo_id, s.nombre
  FROM admin.tb_modulos m, (VALUES ('Ordenes de combustible'), ('Mantenimiento vehicular')) AS s(nombre)
 WHERE m.modulo_nombre = 'Dir. Administrativa'
   AND NOT EXISTS (SELECT 1 FROM admin.tb_submodulos x WHERE x.submodulo_nombre = s.nombre);

-- Códigos para los roles que ya existen (por ruta o por nombre)
UPDATE admin.tb_roles r SET rol_codigo = c.codigo
  FROM (VALUES
        ('/admin/vehiculos', 'ADM_VEHICULOS'),
        ('/admin/ordenes-movilizacion', 'ADM_MOVILIZACION'),
        ('/admin/ordenes-abastecimiento', 'ADM_COMBUSTIBLE'),
        ('/admin/ordenes-mantenimiento', 'MANT_ORDENES'),
        ('/admin/informes-mantenimiento', 'MANT_BITACORAS'),
        ('/admin/planes-mantenimiento', 'MANT_PLANES'),
        ('/admin/contratos-mantenimiento', 'MANT_CONTRATOS'),
        ('/sbj/dashboard', 'SBJ_ESTADISTICAS'),
        ('/sbj/intervenciones', 'SBJ_INTERVENCIONES'),
        ('/sbj/ausencias', 'SBJ_AUSENCIAS'),
        ('/sbj/ubv-voluntarios', 'SBJ_VOLUNTARIOS'),
        ('/sbj/ubv-actividades', 'SBJ_UBV_ACTIVIDADES'),
        ('/sbj/ubv-eventos', 'SBJ_UBV_EVENTOS'),
        ('/operaciones/distributivo', 'OPE_DISTRIBUTIVO'),
        ('/operaciones/partes', 'OPE_PARTES')) AS c(ruta, codigo)
 WHERE r.rol_path = c.ruta AND r.rol_codigo IS NULL
   AND NOT EXISTS (SELECT 1 FROM admin.tb_roles y WHERE y.rol_codigo = c.codigo);
UPDATE admin.tb_roles SET rol_codigo = 'ADM_VEHICULO_CREAR'
 WHERE rol_path IS NULL AND rol_nombre = 'Ingresar nuevo vehiculo' AND rol_codigo IS NULL
   AND NOT EXISTS (SELECT 1 FROM admin.tb_roles y WHERE y.rol_codigo = 'ADM_VEHICULO_CREAR');

-- Roles nuevos: accesos (con ruta) y permisos de acción (sin ruta)
INSERT INTO admin.tb_roles (rol_nombre, rol_descripcion, fk_submodulo_id, rol_path, rol_codigo)
SELECT v.nombre, v.descripcion, s.submodulo_id, v.ruta, v.codigo
  FROM (VALUES
        -- Combustible
        ('Ordenes de Combustible', 'Acceso a las ordenes de abastecimiento de combustible', 'Ordenes de combustible', '/admin/ordenes-abastecimiento', 'ADM_COMBUSTIBLE'),
        ('Crear ordenes de combustible', 'Permite registrar nuevas ordenes de combustible', 'Ordenes de combustible', NULL, 'ADM_COMBUSTIBLE_CREAR'),
        -- Movilización
        ('Crear ordenes de movilizacion', 'Permite registrar nuevas ordenes de movilizacion', 'Ordenes de movilización', NULL, 'ADM_MOVILIZACION_CREAR'),
        -- Mantenimiento vehicular: accesos
        ('Ordenes de Mantenimiento', 'Acceso a las ordenes de mantenimiento y estado de la flota', 'Mantenimiento vehicular', '/admin/ordenes-mantenimiento', 'MANT_ORDENES'),
        ('Informes de Mantenimiento', 'Acceso a las bitacoras (informes de grupo)', 'Mantenimiento vehicular', '/admin/informes-mantenimiento', 'MANT_BITACORAS'),
        ('Planes de Mantenimiento', 'Acceso a planes preventivos y catalogo de recursos', 'Mantenimiento vehicular', '/admin/planes-mantenimiento', 'MANT_PLANES'),
        ('Contratos de Mantenimiento', 'Acceso a contratos, partidas presupuestarias y saldos', 'Mantenimiento vehicular', '/admin/contratos-mantenimiento', 'MANT_CONTRATOS'),
        -- Mantenimiento vehicular: permisos de acción
        ('Registrar ordenes de mantenimiento', 'Crear y editar ordenes en estado MANTENIMIENTO', 'Mantenimiento vehicular', NULL, 'MANT_ORDEN_CREAR'),
        ('Recibir vehiculo y registrar valores', 'Pasar la orden a RECIBIDO y registrar informe de pago y valores por rubro', 'Mantenimiento vehicular', NULL, 'MANT_ORDEN_RECIBIR'),
        ('Generar acta de entrega', 'Generar el acta (ENTREGADO) y reabrir ordenes entregadas', 'Mantenimiento vehicular', NULL, 'MANT_ORDEN_ACTA'),
        ('Anular ordenes de mantenimiento', 'Anular ordenes de mantenimiento', 'Mantenimiento vehicular', NULL, 'MANT_ORDEN_ANULAR'),
        ('Registrar bitacoras', 'Crear, editar y anular bitacoras de mantenimiento', 'Mantenimiento vehicular', NULL, 'MANT_BITACORA_GESTIONAR'),
        ('Administrar contratos de mantenimiento', 'Crear y editar contratos, partidas y vehiculos cubiertos', 'Mantenimiento vehicular', NULL, 'MANT_CONTRATO_GESTIONAR'),
        ('Administrar planes de mantenimiento', 'Crear y editar planes preventivos y recursos', 'Mantenimiento vehicular', NULL, 'MANT_PLAN_GESTIONAR')
       ) AS v(nombre, descripcion, submodulo, ruta, codigo)
  JOIN admin.tb_submodulos s ON s.submodulo_nombre = v.submodulo
 WHERE NOT EXISTS (SELECT 1 FROM admin.tb_roles r WHERE r.rol_codigo = v.codigo)
   AND NOT EXISTS (SELECT 1 FROM admin.tb_roles r WHERE v.ruta IS NOT NULL AND r.rol_path = v.ruta);

-- Ruta de combustible: si el rol ya existía sin código, completar
UPDATE admin.tb_roles SET rol_codigo = 'ADM_COMBUSTIBLE'
 WHERE rol_path = '/admin/ordenes-abastecimiento' AND rol_codigo IS NULL
   AND NOT EXISTS (SELECT 1 FROM admin.tb_roles y WHERE y.rol_codigo = 'ADM_COMBUSTIBLE');

-- Asignaciones iniciales (no quitan nada, solo agregan lo que falte) ------------------
-- 1. Quien ya accede a movilización conserva la posibilidad de crear órdenes y recibe combustible.
INSERT INTO admin.tb_usuario_rol (fk_usuario_id, fk_rol_id)
SELECT DISTINCT ur.fk_usuario_id, n.rol_id
  FROM admin.tb_usuario_rol ur
  JOIN admin.tb_roles m ON m.rol_id = ur.fk_rol_id AND m.rol_codigo = 'ADM_MOVILIZACION'
  JOIN admin.tb_roles n ON n.rol_codigo IN ('ADM_MOVILIZACION_CREAR', 'ADM_COMBUSTIBLE', 'ADM_COMBUSTIBLE_CREAR')
 WHERE NOT EXISTS (SELECT 1 FROM admin.tb_usuario_rol x WHERE x.fk_usuario_id = ur.fk_usuario_id AND x.fk_rol_id = n.rol_id);

-- 2. Administradores (parámetro SIS_ADMINISTRADORES / perfiles de administrador): privilegios de combustible y mantenimiento.
INSERT INTO admin.tb_usuario_rol (fk_usuario_id, fk_rol_id)
SELECT u.usuario_id, r.rol_id
  FROM admin.tb_usuarios u
  JOIN admin.tb_roles r ON r.rol_codigo LIKE 'MANT_%' OR r.rol_codigo LIKE 'ADM_%'
 WHERE admin.fn_es_administrador(u.usuario_id)
   AND NOT EXISTS (SELECT 1 FROM admin.tb_usuario_rol x WHERE x.fk_usuario_id = u.usuario_id AND x.fk_rol_id = r.rol_id);


-- ======================================================================================================
-- 5. BITÁCORA DEL VEHÍCULO (galones con decimales, índices, parámetros de alertas, privilegio)
-- ======================================================================================================
-- =============================================================================
-- BITÁCORA DEL VEHÍCULO - re-ejecutable
-- Historial por fecha y kilometraje (combustible, mantenimiento, movilización, partes) y estadísticas:
-- rendimiento de combustible, frecuencia y gasto de mantenimiento, trabajos repetidos y comparación
-- con vehículos de la misma marca, modelo y año.
-- =============================================================================

-- 1. Galones con decimales (antes int4: 12,35 galones se guardaba como 12 y distorsionaba el rendimiento).
--    Cambio de tipo seguro: los valores enteros existentes se conservan.
DO $$
BEGIN
    IF (SELECT data_type FROM information_schema.columns
         WHERE table_schema = 'logistica' AND table_name = 'tb_ordenesabastecimiento' AND column_name = 'orden_cantidad_galones') = 'integer' THEN
        ALTER TABLE logistica.tb_ordenesabastecimiento ALTER COLUMN orden_cantidad_galones TYPE numeric(10,3);
    END IF;
    IF (SELECT data_type FROM information_schema.columns
         WHERE table_schema = 'logistica' AND table_name = 'tb_detalleordenesabastecimiento' AND column_name = 'orden_detalle_cantidad_galones') = 'integer' THEN
        ALTER TABLE logistica.tb_detalleordenesabastecimiento ALTER COLUMN orden_detalle_cantidad_galones TYPE numeric(10,3);
    END IF;
END
$$;

-- 2. Índices para consultar el historial de un vehículo
CREATE INDEX IF NOT EXISTS ix_ordenesabastecimiento_unidad_fecha ON logistica.tb_ordenesabastecimiento (fk_unidad_id, orden_fecha);
CREATE INDEX IF NOT EXISTS ix_ordenesmovilizacion_unidad_salida ON logistica.tb_ordenesmovilizacion (fk_unidad_id, orden_hora_salida);
CREATE INDEX IF NOT EXISTS ix_parte_unidades_vehiculo ON operaciones.tb_parte_unidades (fk_vehiculo_id, parte_unidad_despacho);

-- 3. Parámetros de las alertas
INSERT INTO admin.tb_params (param_key, param_value, param_type, param_name, param_modulo) VALUES
    ('BIT_VENTANA_REPETICION_DIAS', '180', 'integer', 'Bitácora: días en los que un mismo trabajo repetido genera alerta', 'MANTENIMIENTO'),
    ('BIT_ALERTA_RENDIMIENTO_PCT', '15', 'integer', 'Bitácora: % por debajo del rendimiento (km/gal) de vehículos iguales que genera alerta', 'MANTENIMIENTO'),
    ('BIT_ALERTA_COSTO_PCT', '30', 'integer', 'Bitácora: % por encima del costo de mantenimiento por km de vehículos iguales que genera alerta', 'MANTENIMIENTO')
ON CONFLICT (param_key) DO NOTHING;

-- 4. Privilegio de acceso (pantalla) en el submódulo Unidades
ALTER TABLE admin.tb_roles ADD COLUMN IF NOT EXISTS rol_codigo text;
INSERT INTO admin.tb_roles (rol_nombre, rol_descripcion, fk_submodulo_id, rol_path, rol_codigo)
SELECT 'Bitacora de vehiculos', 'Historial, consumo de combustible, gasto de mantenimiento y alertas por vehiculo', s.submodulo_id,
       '/admin/bitacora-vehiculos', 'ADM_BITACORA_VEHICULOS'
  FROM admin.tb_submodulos s
 WHERE s.submodulo_nombre = 'Unidades'
   AND NOT EXISTS (SELECT 1 FROM admin.tb_roles r WHERE r.rol_codigo = 'ADM_BITACORA_VEHICULOS' OR r.rol_path = '/admin/bitacora-vehiculos')
 LIMIT 1;

-- Quien ya accede a vehículos o a órdenes de mantenimiento recibe la bitácora; también el administrador (parámetro SIS_ADMINISTRADORES)
INSERT INTO admin.tb_usuario_rol (fk_usuario_id, fk_rol_id)
SELECT DISTINCT u.usuario_id, b.rol_id
  FROM admin.tb_usuarios u
  JOIN admin.tb_roles b ON b.rol_codigo = 'ADM_BITACORA_VEHICULOS'
 WHERE (admin.fn_es_administrador(u.usuario_id)
        OR EXISTS (SELECT 1 FROM admin.tb_usuario_rol ur JOIN admin.tb_roles r ON r.rol_id = ur.fk_rol_id
                    WHERE ur.fk_usuario_id = u.usuario_id AND r.rol_codigo IN ('ADM_VEHICULOS', 'MANT_ORDENES')))
   AND NOT EXISTS (SELECT 1 FROM admin.tb_usuario_rol x WHERE x.fk_usuario_id = u.usuario_id AND x.fk_rol_id = b.rol_id);


-- ======================================================================================================
-- 6. OPERADORES (catálogo de licencias, parámetros y privilegios)
-- ======================================================================================================
-- =============================================================================
-- OPERADORES (conductores de vehículos institucionales) - re-ejecutable
-- Un operador es un funcionario (operativo o administrativo) con licencia de conducir registrada:
--   resources.tb_personas -> tthh.tb_personal -> tthh.tb_personal_puestos (EN FUNCIONES)
--   tthh.tb_conductores (licencia: categoría, emisión, validez, estado) -> resources.tb_licenciasdeconducir
-- Solo los operadores ACTIVOS, en funciones y con licencia vigente pueden asignarse en órdenes de movilización
-- y de combustible (parámetro OPER_BLOQUEAR_LICENCIA_VENCIDA).
-- Sustento: PDF escaneado de la licencia en documentos/licencias/LIC-{CATEGORÍA}-{CÉDULA}.pdf (tb_conductores.conductor_pdf).
-- =============================================================================

-- 1. Catálogo de licencias (Ecuador). Solo se carga si el catálogo está vacío: en una base migrada se usan las existentes.
INSERT INTO resources.tb_licenciasdeconducir (licencia_tipo, licencia_categoria, licencia_descripcion)
SELECT v.tipo, v.categoria, v.descripcion
  FROM (VALUES
        ('NO PROFESIONAL', 'A', 'Ciclomotores, motocicletas, tricimotos y cuadrones'),
        ('NO PROFESIONAL', 'B', 'Automóviles y camionetas hasta 3,5 toneladas'),
        ('NO PROFESIONAL', 'F', 'Vehículos adaptados para personas con discapacidad'),
        ('PROFESIONAL', 'A1', 'Mototaxis y tricimotos de transporte'),
        ('PROFESIONAL', 'C', 'Taxis, camionetas, furgonetas y vehículos livianos de hasta 3,5 toneladas'),
        ('PROFESIONAL', 'C1', 'Vehículos policiales, ambulancias y vehículos de emergencia livianos'),
        ('PROFESIONAL', 'D', 'Buses de pasajeros'),
        ('PROFESIONAL', 'D1', 'Buses escolares, institucionales y de turismo'),
        ('PROFESIONAL', 'E', 'Camiones pesados, extrapesados y tráileres'),
        ('PROFESIONAL', 'E1', 'Ambulancias, vehículos de emergencia y carga especial'),
        ('PROFESIONAL', 'G', 'Maquinaria agrícola y equipo caminero')
       ) AS v(tipo, categoria, descripcion)
 WHERE NOT EXISTS (SELECT 1 FROM resources.tb_licenciasdeconducir);

-- 2. Índices para buscar al operador por persona y por cédula
CREATE INDEX IF NOT EXISTS ix_conductores_personal ON tthh.tb_conductores (fk_personal_id);
CREATE INDEX IF NOT EXISTS ix_personas_doc_identidad ON resources.tb_personas (persona_doc_identidad);

-- 3. Parámetros
INSERT INTO admin.tb_params (param_key, param_value, param_type, param_name, param_modulo) VALUES
    ('OPER_DIAS_AVISO_LICENCIA', '30', 'integer', 'Operadores: días antes del vencimiento en que la licencia se marca POR VENCER', 'OPERADORES'),
    ('OPER_BLOQUEAR_LICENCIA_VENCIDA', 'SI', 'text', 'Operadores: SI = no se puede asignar en movilización/combustible un operador con licencia vencida o inactivo', 'OPERADORES'),
    ('OPER_EXIGIR_PDF_LICENCIA', 'SI', 'text', 'Operadores: SI = el PDF escaneado de la licencia es obligatorio al registrar y al actualizar la licencia', 'OPERADORES'),
    ('OPER_PDF_MAX_MB', '5', 'integer', 'Operadores: tamaño máximo del PDF de la licencia en MB (también limitado por upload_max_filesize de PHP)', 'OPERADORES'),
    ('OPER_BLOQUEAR_SIN_SUSTENTO', 'NO', 'text', 'Operadores: SI = tampoco se puede asignar en órdenes a un operador sin el PDF de su licencia (activar cuando todos lo tengan cargado)', 'OPERADORES')
ON CONFLICT (param_key) DO NOTHING;

-- 4. Menú y privilegios en la Dirección Administrativa
ALTER TABLE admin.tb_roles ADD COLUMN IF NOT EXISTS rol_codigo text;
INSERT INTO admin.tb_submodulos (fk_modulo_id, submodulo_nombre)
SELECT m.modulo_id, 'Operadores' FROM admin.tb_modulos m
 WHERE m.modulo_nombre = 'Dir. Administrativa'
   AND NOT EXISTS (SELECT 1 FROM admin.tb_submodulos x WHERE x.submodulo_nombre = 'Operadores');

INSERT INTO admin.tb_roles (rol_nombre, rol_descripcion, fk_submodulo_id, rol_path, rol_codigo)
SELECT v.nombre, v.descripcion, s.submodulo_id, v.ruta, v.codigo
  FROM (VALUES
        ('Operadores', 'Acceso al listado de operadores (conductores) y sus licencias', '/admin/operadores', 'ADM_OPERADORES'),
        ('Registrar y editar operadores', 'Ingreso rapido de operadores y actualizacion de su licencia', NULL, 'ADM_OPERADOR_GESTIONAR')
       ) AS v(nombre, descripcion, ruta, codigo)
  JOIN admin.tb_submodulos s ON s.submodulo_nombre = 'Operadores'
 WHERE NOT EXISTS (SELECT 1 FROM admin.tb_roles r WHERE r.rol_codigo = v.codigo)
   AND NOT EXISTS (SELECT 1 FROM admin.tb_roles r WHERE v.ruta IS NOT NULL AND r.rol_path = v.ruta);

-- Acceso de consulta para quien ya emite órdenes de movilización o combustible; ambos privilegios para el administrador (parámetro SIS_ADMINISTRADORES)
INSERT INTO admin.tb_usuario_rol (fk_usuario_id, fk_rol_id)
SELECT DISTINCT u.usuario_id, o.rol_id
  FROM admin.tb_usuarios u
  JOIN admin.tb_roles o ON o.rol_codigo IN ('ADM_OPERADORES', 'ADM_OPERADOR_GESTIONAR')
 WHERE (admin.fn_es_administrador(u.usuario_id)
        OR (o.rol_codigo = 'ADM_OPERADORES'
            AND EXISTS (SELECT 1 FROM admin.tb_usuario_rol ur JOIN admin.tb_roles r ON r.rol_id = ur.fk_rol_id
                         WHERE ur.fk_usuario_id = u.usuario_id AND r.rol_codigo IN ('ADM_MOVILIZACION', 'ADM_COMBUSTIBLE'))))
   AND NOT EXISTS (SELECT 1 FROM admin.tb_usuario_rol x WHERE x.fk_usuario_id = u.usuario_id AND x.fk_rol_id = o.rol_id);


-- ======================================================================================================
-- 7. USUARIOS Y PERFILES (privilegios por perfil, menú de administración, claves)
-- ======================================================================================================
-- =============================================================================
-- USUARIOS Y PERFILES - re-ejecutable
-- Usuario (admin.tb_usuarios) -> persona (resources.tb_personas); puede ser o no funcionario (tthh.tb_personal).
-- Perfil (admin.tb_perfiles) = grupo de privilegios predefinido (admin.tb_perfil_rol).
-- Privilegios efectivos de un usuario ACTIVO = los de su perfil (si está ACTIVO) + los adicionales del usuario
-- (admin.tb_usuario_rol). Vista admin.vw_usuario_privilegios: la usan el login, el menú, getPermisos y requirePermiso.
-- =============================================================================

-- 1. Privilegios de cada perfil
CREATE TABLE IF NOT EXISTS admin.tb_perfil_rol (
    fk_perfil_id integer NOT NULL REFERENCES admin.tb_perfiles(perfil_id) ON DELETE CASCADE,
    fk_rol_id integer NOT NULL REFERENCES admin.tb_roles(rol_id) ON DELETE CASCADE,
    PRIMARY KEY (fk_perfil_id, fk_rol_id)
);
COMMENT ON TABLE admin.tb_perfil_rol IS 'Privilegios predefinidos de cada perfil; los usuarios del perfil los reciben automáticamente';
COMMENT ON TABLE admin.tb_usuario_rol IS 'Privilegios adicionales de un usuario (además de los de su perfil)';

ALTER TABLE admin.tb_perfiles ADD COLUMN IF NOT EXISTS fk_usuario_id integer;
ALTER TABLE admin.tb_perfiles ADD COLUMN IF NOT EXISTS perfil_registro timestamp without time zone DEFAULT ('now'::text)::timestamp(0) with time zone;
-- Nombre de perfil único (solo si ya no hay duplicados; si los hay, el API igual impide crear nuevos repetidos)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM admin.tb_perfiles GROUP BY upper(trim(perfil_nombre)) HAVING count(*) > 1) THEN
        CREATE UNIQUE INDEX IF NOT EXISTS ux_perfiles_nombre ON admin.tb_perfiles (upper(trim(perfil_nombre)));
    ELSE
        RAISE NOTICE 'Hay perfiles con el mismo nombre: no se crea el índice único ux_perfiles_nombre';
    END IF;
END
$$;
ALTER TABLE admin.tb_usuarios ADD COLUMN IF NOT EXISTS usuario_ultimo_acceso timestamp without time zone;
CREATE INDEX IF NOT EXISTS ix_usuarios_persona ON admin.tb_usuarios (fk_persona_id);
CREATE INDEX IF NOT EXISTS ix_usuarios_login ON admin.tb_usuarios (lower(usuario_login));

-- Secuencias al día: las tablas se cargaron con IDs explícitos (migración desde db_cbsd) y el sistema nuevo empieza a
-- insertar usuarios, perfiles y personas desde sus pantallas. Solo se adelantan, nunca se retroceden.
SELECT setval(pg_get_serial_sequence('admin.tb_usuarios', 'usuario_id'),
              GREATEST((SELECT COALESCE(max(usuario_id), 1) FROM admin.tb_usuarios), (SELECT last_value FROM admin.tb_usuarios_usuario_id_seq)));
SELECT setval(pg_get_serial_sequence('admin.tb_perfiles', 'perfil_id'),
              GREATEST((SELECT COALESCE(max(perfil_id), 1) FROM admin.tb_perfiles), (SELECT last_value FROM admin.tb_perfiles_perfil_id_seq)));
SELECT setval(pg_get_serial_sequence('resources.tb_personas', 'persona_id'),
              GREATEST((SELECT COALESCE(max(persona_id), 1) FROM resources.tb_personas), (SELECT last_value FROM resources.tb_personas_persona_id_seq)));

-- Perfil por defecto para usuarios sin uno válido (tb_usuarios.fk_perfil_id es obligatorio)
INSERT INTO admin.tb_perfiles (perfil_nombre, perfil_descripcion)
SELECT 'SIN PERFIL', 'Usuarios sin privilegios predefinidos (solo los adicionales que se les asignen)'
 WHERE NOT EXISTS (SELECT 1 FROM admin.tb_perfiles WHERE upper(trim(perfil_nombre)) = 'SIN PERFIL');

-- 2. Privilegios efectivos
CREATE OR REPLACE VIEW admin.vw_usuario_privilegios AS
SELECT u.usuario_id, ur.fk_rol_id AS rol_id, 'USUARIO'::text AS origen
  FROM admin.tb_usuarios u JOIN admin.tb_usuario_rol ur ON ur.fk_usuario_id = u.usuario_id
 WHERE COALESCE(u.usuario_estado, 'ACTIVO') = 'ACTIVO'
UNION
SELECT u.usuario_id, pr.fk_rol_id, 'PERFIL'::text
  FROM admin.tb_usuarios u
  JOIN admin.tb_perfiles p ON p.perfil_id = u.fk_perfil_id AND COALESCE(p.perfil_estado, 'ACTIVO') = 'ACTIVO'
  JOIN admin.tb_perfil_rol pr ON pr.fk_perfil_id = p.perfil_id
 WHERE COALESCE(u.usuario_estado, 'ACTIVO') = 'ACTIVO';
COMMENT ON VIEW admin.vw_usuario_privilegios IS 'Privilegios efectivos: perfil + adicionales, solo usuarios y perfiles ACTIVOS';

-- 3. Menú y privilegios de la administración del sistema (antes el menú estaba fijo para un usuario)
ALTER TABLE admin.tb_roles ADD COLUMN IF NOT EXISTS rol_codigo text;
INSERT INTO admin.tb_modulos (modulo_nombre, modulo_descripcion)
SELECT 'Administración', 'Usuarios, perfiles y privilegios del sistema'
 WHERE NOT EXISTS (SELECT 1 FROM admin.tb_modulos WHERE modulo_nombre = 'Administración');
INSERT INTO admin.tb_submodulos (fk_modulo_id, submodulo_nombre)
SELECT m.modulo_id, 'Usuarios y perfiles' FROM admin.tb_modulos m
 WHERE m.modulo_nombre = 'Administración'
   AND NOT EXISTS (SELECT 1 FROM admin.tb_submodulos x WHERE x.submodulo_nombre = 'Usuarios y perfiles');

-- Si el menú anterior ya tenía estas pantallas (ruta sin código), se les completa el código en lugar de duplicarlas
UPDATE admin.tb_roles r SET rol_codigo = c.codigo
  FROM (VALUES ('/adm/usuarios', 'SIS_USUARIOS'), ('/adm/perfiles', 'SIS_PERFILES')) AS c(ruta, codigo)
 WHERE r.rol_path = c.ruta AND r.rol_codigo IS NULL
   AND NOT EXISTS (SELECT 1 FROM admin.tb_roles y WHERE y.rol_codigo = c.codigo);

INSERT INTO admin.tb_roles (rol_nombre, rol_descripcion, fk_submodulo_id, rol_path, rol_codigo)
SELECT v.nombre, v.descripcion, s.submodulo_id, v.ruta, v.codigo
  FROM (VALUES
        ('Usuarios', 'Acceso al listado de usuarios del sistema', '/adm/usuarios', 'SIS_USUARIOS'),
        ('Perfiles', 'Acceso a los perfiles (grupos de privilegios predefinidos)', '/adm/perfiles', 'SIS_PERFILES'),
        ('Registrar y editar usuarios', 'Crear usuarios, editar sus datos y su perfil, activarlos o inactivarlos y restablecer su clave', NULL, 'SIS_USUARIO_GESTIONAR'),
        ('Asignar privilegios adicionales', 'Dar a un usuario privilegios ademas de los de su perfil', NULL, 'SIS_USUARIO_PRIVILEGIOS'),
        ('Administrar perfiles', 'Crear y editar perfiles y sus privilegios predefinidos', NULL, 'SIS_PERFIL_GESTIONAR')
       ) AS v(nombre, descripcion, ruta, codigo)
  JOIN admin.tb_submodulos s ON s.submodulo_nombre = 'Usuarios y perfiles'
 WHERE NOT EXISTS (SELECT 1 FROM admin.tb_roles r WHERE r.rol_codigo = v.codigo)
   AND NOT EXISTS (SELECT 1 FROM admin.tb_roles r WHERE v.ruta IS NOT NULL AND r.rol_path = v.ruta);

-- 4. Asignaciones iniciales: el administrador (parámetro SIS_ADMINISTRADORES) y el perfil ADMINISTRADOR reciben toda la administración del sistema
INSERT INTO admin.tb_usuario_rol (fk_usuario_id, fk_rol_id)
SELECT u.usuario_id, r.rol_id FROM admin.tb_usuarios u JOIN admin.tb_roles r ON r.rol_codigo LIKE 'SIS\_%'
 WHERE admin.fn_es_administrador(u.usuario_id)
   AND NOT EXISTS (SELECT 1 FROM admin.tb_usuario_rol x WHERE x.fk_usuario_id = u.usuario_id AND x.fk_rol_id = r.rol_id);
INSERT INTO admin.tb_perfil_rol (fk_perfil_id, fk_rol_id)
SELECT p.perfil_id, r.rol_id FROM admin.tb_perfiles p JOIN admin.tb_roles r ON r.rol_codigo LIKE 'SIS\_%'
 WHERE admin.fn_perfil_es_administrador(p.perfil_id)
ON CONFLICT DO NOTHING;

-- 5. Contraseñas: password_hash (bcrypt, 60 caracteres). Las MD5 existentes se convierten solas en el siguiente login.
COMMENT ON COLUMN admin.tb_usuarios.usuario_pass IS 'password_hash() de PHP; las MD5 heredadas se reemplazan al iniciar sesión';


-- ======================================================================================================
-- 8. PETICIÓN DE MATERIALES Y RESUMEN GERENCIAL (servicios generales)
-- ======================================================================================================
-- =============================================================================
-- PETICIÓN DE MATERIALES (Servicios generales) - re-ejecutable
-- Documento simple que reemplaza el libretín: se digitan cantidad, unidad y descripción (sin stock ni catálogo de
-- productos), se imprime y se firma. Código {SIGLAS}{AA}PDM{NNNNN}, secuencia que reinicia cada año.
-- =============================================================================

CREATE TABLE IF NOT EXISTS logistica.tb_peticionesmateriales (
    peticion_id SERIAL NOT NULL PRIMARY KEY,
    peticion_registro timestamp without time zone DEFAULT ('now'::text)::timestamp(0) with time zone,
    fk_usuario_id integer NOT NULL REFERENCES admin.tb_usuarios(usuario_id),
    peticion_codigo text NOT NULL UNIQUE,
    peticion_anio integer NOT NULL,
    peticion_serie integer NOT NULL,
    peticion_fecha date NOT NULL DEFAULT CURRENT_DATE,
    peticion_lugar text,                                   -- "Lugar y fecha" (por defecto, la ciudad de la institución)
    peticion_destino text NOT NULL,                        -- "Sírvase autorizar ... para ser utilizados en:"
    peticion_autorizado_para text CHECK (peticion_autorizado_para IN ('ADQUISICION', 'BODEGA')),
    solicitante_id integer NOT NULL REFERENCES tthh.tb_personal_puestos(ppersonal_id),
    solicitante_cargo text,
    autoriza_id integer REFERENCES tthh.tb_personal_puestos(ppersonal_id),
    autoriza_cargo text,
    peticion_observaciones text,
    peticion_estado text NOT NULL DEFAULT 'EMITIDA' CHECK (peticion_estado IN ('EMITIDA', 'ANULADA')),
    UNIQUE (peticion_anio, peticion_serie)
);
CREATE INDEX IF NOT EXISTS ix_peticionesmateriales_fecha ON logistica.tb_peticionesmateriales (peticion_fecha DESC);

CREATE TABLE IF NOT EXISTS logistica.tb_peticionesmateriales_detalle (
    detalle_id SERIAL NOT NULL PRIMARY KEY,
    fk_peticion_id integer NOT NULL REFERENCES logistica.tb_peticionesmateriales(peticion_id) ON DELETE CASCADE,
    detalle_orden integer NOT NULL,
    detalle_cantidad numeric(12,2) NOT NULL CHECK (detalle_cantidad > 0),
    detalle_unidad text NOT NULL,
    detalle_descripcion text NOT NULL
);
CREATE INDEX IF NOT EXISTS ix_peticionesmateriales_detalle ON logistica.tb_peticionesmateriales_detalle (fk_peticion_id, detalle_orden);

-- Parámetros
INSERT INTO admin.tb_params (param_key, param_value, param_type, param_name, param_modulo) VALUES
    ('PDM_UNIDADES', 'UNIDAD|CAJA|PAQUETE|RESMA|ROLLO|METRO|LITRO|GALÓN|KILOGRAMO|LIBRA|PAR|JUEGO|FUNDA|CANECA|BIDÓN|FRASCO|SACO',
     'list', 'Petición de materiales: unidades sugeridas (se puede escribir otra)', 'SERVICIOS GENERALES'),
    ('PDM_AUTORIZA_PUESTO_ID', '4', 'integer',
     'Petición de materiales: puesto (tthh.tb_puestos.puesto_id) de quien autoriza; se precarga quien lo tenga EN FUNCIONES', 'SERVICIOS GENERALES'),
    ('PDM_FILAS_MINIMAS', '15', 'integer', 'Petición de materiales: filas que muestra la tabla del PDF aunque haya menos ítems (como el libretín)', 'SERVICIOS GENERALES')
ON CONFLICT (param_key) DO NOTHING;

-- Menú y privilegios: Dir. Administrativa > Servicios generales
ALTER TABLE admin.tb_roles ADD COLUMN IF NOT EXISTS rol_codigo text;
INSERT INTO admin.tb_submodulos (fk_modulo_id, submodulo_nombre)
SELECT m.modulo_id, 'Servicios generales' FROM admin.tb_modulos m
 WHERE m.modulo_nombre = 'Dir. Administrativa'
   AND NOT EXISTS (SELECT 1 FROM admin.tb_submodulos x WHERE x.submodulo_nombre = 'Servicios generales');

INSERT INTO admin.tb_roles (rol_nombre, rol_descripcion, fk_submodulo_id, rol_path, rol_codigo)
SELECT v.nombre, v.descripcion, s.submodulo_id, v.ruta, v.codigo
  FROM (VALUES
        ('Peticiones de materiales', 'Acceso a las peticiones de materiales y su impresion', '/admin/peticiones-materiales', 'ADM_PETICIONES_MATERIALES'),
        ('Registrar peticiones de materiales', 'Crear, editar y anular peticiones de materiales', NULL, 'ADM_PETICION_MATERIALES_GESTIONAR')
       ) AS v(nombre, descripcion, ruta, codigo)
  JOIN admin.tb_submodulos s ON s.submodulo_nombre = 'Servicios generales'
 WHERE NOT EXISTS (SELECT 1 FROM admin.tb_roles r WHERE r.rol_codigo = v.codigo)
   AND NOT EXISTS (SELECT 1 FROM admin.tb_roles r WHERE v.ruta IS NOT NULL AND r.rol_path = v.ruta);

-- Asignación inicial: el administrador (parámetro SIS_ADMINISTRADORES) y quienes ya emiten órdenes de movilización (servicios generales)
INSERT INTO admin.tb_usuario_rol (fk_usuario_id, fk_rol_id)
SELECT DISTINCT u.usuario_id, p.rol_id
  FROM admin.tb_usuarios u
  JOIN admin.tb_roles p ON p.rol_codigo IN ('ADM_PETICIONES_MATERIALES', 'ADM_PETICION_MATERIALES_GESTIONAR')
 WHERE (admin.fn_es_administrador(u.usuario_id)
        OR EXISTS (SELECT 1 FROM admin.tb_usuario_rol ur JOIN admin.tb_roles r ON r.rol_id = ur.fk_rol_id
                    WHERE ur.fk_usuario_id = u.usuario_id AND r.rol_codigo = 'ADM_MOVILIZACION_CREAR'))
   AND NOT EXISTS (SELECT 1 FROM admin.tb_usuario_rol x WHERE x.fk_usuario_id = u.usuario_id AND x.fk_rol_id = p.rol_id);
-- y el perfil ADMINISTRADOR
INSERT INTO admin.tb_perfil_rol (fk_perfil_id, fk_rol_id)
SELECT pf.perfil_id, r.rol_id FROM admin.tb_perfiles pf JOIN admin.tb_roles r ON r.rol_codigo IN ('ADM_PETICIONES_MATERIALES', 'ADM_PETICION_MATERIALES_GESTIONAR')
 WHERE admin.fn_perfil_es_administrador(pf.perfil_id)
ON CONFLICT DO NOTHING;

-- =============================================================================
-- RESUMEN GERENCIAL de la Dirección Administrativa (/admin/dashboard) - re-ejecutable
-- Vista simplificada para el director: flota, gasto, contratos, alertas y licencias. El detalle para analistas sigue
-- en la Bitácora de vehículos. Antes /admin/dashboard era la plantilla de ejemplo, sin privilegio.
-- =============================================================================
ALTER TABLE admin.tb_roles ADD COLUMN IF NOT EXISTS rol_codigo text;
INSERT INTO admin.tb_submodulos (fk_modulo_id, submodulo_nombre)
SELECT m.modulo_id, 'Servicios generales' FROM admin.tb_modulos m
 WHERE m.modulo_nombre = 'Dir. Administrativa'
   AND NOT EXISTS (SELECT 1 FROM admin.tb_submodulos x WHERE x.submodulo_nombre = 'Servicios generales');

INSERT INTO admin.tb_roles (rol_nombre, rol_descripcion, fk_submodulo_id, rol_path, rol_codigo)
SELECT 'Resumen gerencial', 'Resumen de flota, gasto, contratos, alertas y licencias para la direccion', s.submodulo_id, '/admin/dashboard', 'ADM_DASHBOARD'
  FROM admin.tb_submodulos s
 WHERE s.submodulo_nombre = 'Servicios generales'
   AND NOT EXISTS (SELECT 1 FROM admin.tb_roles r WHERE r.rol_codigo = 'ADM_DASHBOARD' OR r.rol_path = '/admin/dashboard')
 LIMIT 1;
-- Si ya existía un rol con esa ruta sin código, completarlo
UPDATE admin.tb_roles SET rol_codigo = 'ADM_DASHBOARD'
 WHERE rol_path = '/admin/dashboard' AND rol_codigo IS NULL AND NOT EXISTS (SELECT 1 FROM admin.tb_roles y WHERE y.rol_codigo = 'ADM_DASHBOARD');

-- Asignación inicial: el administrador (parámetro SIS_ADMINISTRADORES), el perfil ADMINISTRADOR y quienes ya ven la bitácora de vehículos
INSERT INTO admin.tb_usuario_rol (fk_usuario_id, fk_rol_id)
SELECT DISTINCT u.usuario_id, d.rol_id
  FROM admin.tb_usuarios u JOIN admin.tb_roles d ON d.rol_codigo = 'ADM_DASHBOARD'
 WHERE (admin.fn_es_administrador(u.usuario_id)
        OR EXISTS (SELECT 1 FROM admin.tb_usuario_rol ur JOIN admin.tb_roles r ON r.rol_id = ur.fk_rol_id
                    WHERE ur.fk_usuario_id = u.usuario_id AND r.rol_codigo = 'ADM_BITACORA_VEHICULOS'))
   AND NOT EXISTS (SELECT 1 FROM admin.tb_usuario_rol x WHERE x.fk_usuario_id = u.usuario_id AND x.fk_rol_id = d.rol_id);
INSERT INTO admin.tb_perfil_rol (fk_perfil_id, fk_rol_id)
SELECT pf.perfil_id, r.rol_id FROM admin.tb_perfiles pf JOIN admin.tb_roles r ON r.rol_codigo = 'ADM_DASHBOARD'
 WHERE admin.fn_perfil_es_administrador(pf.perfil_id)
ON CONFLICT DO NOTHING;


-- ======================================================================================================
-- 9. REVISIÓN: borrado lógico de documentos de archivo
-- ======================================================================================================
-- =============================================================================
-- REVISIÓN: borrado lógico de documentos de archivo - re-ejecutable
-- El front ya tenía "Eliminar" pero el endpoint no existía. Un documento eliminado se conserva con su estado, quién y
-- cuándo lo eliminó (se puede recuperar cambiando documento_estado a ACTIVO).
-- Voluntarios, actividades y asignaciones usan sus columnas de estado existentes (valor ELIMINADO/ELIMINADA).
-- =============================================================================
ALTER TABLE archivo.documentos ADD COLUMN IF NOT EXISTS documento_estado text DEFAULT 'ACTIVO';
ALTER TABLE archivo.documentos ADD COLUMN IF NOT EXISTS documento_eliminado_por integer;
ALTER TABLE archivo.documentos ADD COLUMN IF NOT EXISTS documento_eliminado_en timestamp without time zone;


-- ======================================================================================================
-- 10. PARTES DE SERVICIO (Operaciones): catálogos del formato, enlaces para estadística y privilegios
-- ======================================================================================================
-- =============================================================================
-- PARTES DE SERVICIO (Operaciones) - re-ejecutable, no borra datos
-- Esquema del formulario actual: operaciones.tb_partes + detalles (creados en script_sbj_temp.sql). Las tablas antiguas
-- (operaciones.tb_parte, tb_parte_unidades, tb_parte_personal) quedan solo como histórico.
-- Para la estadística por vehículo, estación, bombero y herramienta, los detalles se enlazan a sus catálogos:
--   vehículos -> administrativo.tb_vehiculos, personal -> tthh.tb_personal (personal_id),
--   equipos/materiales/insumos -> operaciones.tb_partes_catalogo_recursos, tipos de auxilio -> su catálogo.
-- =============================================================================

-- 1. CABECERA ------------------------------------------------------------------
-- Número automático como en el formato del área operativa: {SIGLAS}-{PA|PI}-{ESTACIÓN}-{AAAA}-{NNNN}
-- (PA parte de auxilio, PI parte de incendio), secuencia por año de la fecha del parte, estación y tipo.
ALTER TABLE operaciones.tb_partes ADD COLUMN IF NOT EXISTS parte_anio integer;
ALTER TABLE operaciones.tb_partes ADD COLUMN IF NOT EXISTS parte_serie integer;
ALTER TABLE operaciones.tb_partes ADD COLUMN IF NOT EXISTS parte_anulado_motivo text;
ALTER TABLE operaciones.tb_partes ADD COLUMN IF NOT EXISTS parte_actualizado timestamp without time zone;
ALTER TABLE operaciones.tb_partes ADD COLUMN IF NOT EXISTS fk_usuario_actualiza integer;
-- El formulario no tiene estos datos en la cabecera (las horas de salida/arribo/fin van por vehículo y la cabecera
-- toma la primera/última) o los toma de catálogos opcionales: dejan de ser obligatorios en la tabla.
ALTER TABLE operaciones.tb_partes ALTER COLUMN fk_personal_id DROP NOT NULL;
ALTER TABLE operaciones.tb_partes ALTER COLUMN fk_parroquia_id DROP NOT NULL;
ALTER TABLE operaciones.tb_partes ALTER COLUMN parte_forma_aviso DROP NOT NULL;
ALTER TABLE operaciones.tb_partes ALTER COLUMN parte_codigo_salida DROP NOT NULL;
ALTER TABLE operaciones.tb_partes ALTER COLUMN parte_grupo_asiste DROP NOT NULL;
ALTER TABLE operaciones.tb_partes ALTER COLUMN parte_hora_salida DROP NOT NULL;
ALTER TABLE operaciones.tb_partes ALTER COLUMN parte_hora_arribo DROP NOT NULL;
ALTER TABLE operaciones.tb_partes ALTER COLUMN parte_hora_finalizacion DROP NOT NULL;
ALTER TABLE operaciones.tb_partes ALTER COLUMN parte_hora_retorno DROP NOT NULL;
ALTER TABLE operaciones.tb_partes ALTER COLUMN parte_provincia DROP NOT NULL;
ALTER TABLE operaciones.tb_partes ALTER COLUMN parte_canton DROP NOT NULL;
ALTER TABLE operaciones.tb_partes ALTER COLUMN parte_parroquia DROP NOT NULL;
ALTER TABLE operaciones.tb_partes ALTER COLUMN parte_direccion DROP NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS ux_partes_numero ON operaciones.tb_partes (parte_numero);
CREATE INDEX IF NOT EXISTS ix_partes_fecha ON operaciones.tb_partes (parte_fecha, fk_estacion_id);

-- 2. CATÁLOGO DE RECURSOS (equipos y herramientas, material descartable, insumos) -------------------------------
CREATE TABLE IF NOT EXISTS operaciones.tb_partes_catalogo_recursos (
    recurso_id SERIAL NOT NULL PRIMARY KEY,
    recurso_registro timestamp without time zone DEFAULT ('now'::text)::timestamp(0) with time zone,
    recurso_tipo text NOT NULL CHECK (recurso_tipo IN ('EQUIPO', 'MATERIAL', 'INSUMO')),
    recurso_descripcion text NOT NULL,
    recurso_unidad text,
    recurso_estado text NOT NULL DEFAULT 'ACTIVO'
);
CREATE UNIQUE INDEX IF NOT EXISTS ux_partes_catalogo_recursos ON operaciones.tb_partes_catalogo_recursos (recurso_tipo, upper(recurso_descripcion));
-- Catálogos del esquema anterior, si existen
DO $$
BEGIN
    IF to_regclass('operaciones.tb_parte_equipo') IS NOT NULL THEN
        INSERT INTO operaciones.tb_partes_catalogo_recursos (recurso_tipo, recurso_descripcion)
        SELECT DISTINCT 'EQUIPO', upper(trim(parte_equipo_descripcion)) FROM operaciones.tb_parte_equipo WHERE trim(parte_equipo_descripcion) <> ''
        ON CONFLICT DO NOTHING;
    END IF;
    IF to_regclass('operaciones.tb_parte_material') IS NOT NULL THEN
        INSERT INTO operaciones.tb_partes_catalogo_recursos (recurso_tipo, recurso_descripcion)
        SELECT DISTINCT 'MATERIAL', upper(trim(parte_material_descripcion)) FROM operaciones.tb_parte_material WHERE trim(parte_material_descripcion) <> ''
        ON CONFLICT DO NOTHING;
    END IF;
    IF to_regclass('operaciones.tb_parte_insumo') IS NOT NULL THEN
        INSERT INTO operaciones.tb_partes_catalogo_recursos (recurso_tipo, recurso_descripcion)
        SELECT DISTINCT 'INSUMO', upper(trim(parte_insumo_descripcion)) FROM operaciones.tb_parte_insumo WHERE trim(parte_insumo_descripcion) <> ''
        ON CONFLICT DO NOTHING;
    END IF;
END $$;

-- 2b. CATÁLOGOS DEL FORMATO DEL ÁREA OPERATIVA (listas del Excel CBSD-PA) ------------------------------------------
-- Tipo de auxilio: Clasificación -> Subclasificación y niveles -> Usos y tipos. La clave (10-1, 10-2...) se elige
-- aparte en cada fila del parte, por eso el catálogo usa clave vacía.
ALTER TABLE operaciones.tb_partes_catalogo_tipos_auxilio ADD COLUMN IF NOT EXISTS tipo_auxilio_orden integer NOT NULL DEFAULT 0;
INSERT INTO operaciones.tb_partes_catalogo_tipos_auxilio
       (tipo_auxilio_clave, tipo_auxilio_clasificacion, tipo_auxilio_subclasificacion, tipo_auxilio_uso_tipo, tipo_auxilio_orden)
SELECT '', c.clasificacion, c.subclasificacion, c.uso, c.orden FROM (VALUES
    ('Falsa alarma', '', '', 1),
    ('Soporte vital', 'In situ', '', 2),
    ('Soporte vital', 'Con traslado', '', 3),
    ('Soporte vital', 'Otros', '', 4),
    ('Auxilio', 'Tala de árboles', 'Tala', 5),
    ('Auxilio', 'Tala de árboles', 'Inspección', 6),
    ('Auxilio', 'Tala de árboles', 'Otros', 7),
    ('Auxilio', 'Baldeo', 'Institución Pública', 8),
    ('Auxilio', 'Baldeo', 'Institución Privada', 9),
    ('Auxilio', 'Baldeo', 'Otros', 10),
    ('Auxilio', 'Abastecimiento de agua', 'Comunitario', 11),
    ('Auxilio', 'Abastecimiento de agua', 'Otros', 12),
    ('Auxilio', 'Entrada forzada', 'Abrir departamento', 13),
    ('Auxilio', 'Entrada forzada', 'Abrir vehículo', 14),
    ('Auxilio', 'Entrada forzada', 'Otros', 15),
    ('Auxilio', 'Evacuación', 'Menaje de hogar', 16),
    ('Auxilio', 'Evacuación', 'Personas', 17),
    ('Auxilio', 'Evacuación', 'Menaje + personas', 18),
    ('Auxilio', 'Evacuación', 'Otros', 19),
    ('Auxilio', 'Inspección', 'Con Sirena – Baliza', 20),
    ('Auxilio', 'Inspección', 'Sin Sirena – Baliza', 21),
    ('Auxilio', 'General', '', 22),
    ('Rescate', 'Rescate acuático', 'Aguas rápidas', 23),
    ('Rescate', 'Rescate acuático', 'Estanques', 24),
    ('Rescate', 'Rescate acuático', 'Otros', 25),
    ('Rescate', 'Rescate aéreo', 'Aeronaves tripuladas', 26),
    ('Rescate', 'Rescate aéreo', 'Aeronaves no tripuladas', 27),
    ('Rescate', 'Rescate aéreo', 'Otros', 28),
    ('Rescate', 'Rescate agreste', '', 29),
    ('Rescate', 'Rescate espacios confinados', 'Pozo de agua', 30),
    ('Rescate', 'Rescate espacios confinados', 'Cisterna', 31),
    ('Rescate', 'Rescate espacios confinados', 'Alcantarillado público', 32),
    ('Rescate', 'Rescate espacios confinados', 'Otros', 33),
    ('Rescate', 'Rescate estructuras colapsadas', 'Reuniones Públicas', 34),
    ('Rescate', 'Rescate estructuras colapsadas', 'Educacionales', 35),
    ('Rescate', 'Rescate estructuras colapsadas', 'Guarderías', 36),
    ('Rescate', 'Rescate estructuras colapsadas', 'Cuidado de la Salud', 37),
    ('Rescate', 'Rescate estructuras colapsadas', 'Cuidado de Salud Pacientes Ambulatorio', 38),
    ('Rescate', 'Rescate estructuras colapsadas', 'Detención y Correccional', 39),
    ('Rescate', 'Rescate estructuras colapsadas', 'Residencial y Alojamiento', 40),
    ('Rescate', 'Rescate estructuras colapsadas', 'Asilos y Centros de Acogidas Residenciales', 41),
    ('Rescate', 'Rescate estructuras colapsadas', 'Mercantil Comercial', 42),
    ('Rescate', 'Rescate estructuras colapsadas', 'Negocios / Oficinas / Servicios', 43),
    ('Rescate', 'Rescate estructuras colapsadas', 'Industrial / Manufactura', 44),
    ('Rescate', 'Rescate estructuras colapsadas', 'Almacenamiento', 45),
    ('Rescate', 'Rescate estructuras colapsadas', 'Ocupaciones Múltiple', 46),
    ('Rescate', 'Rescate estructuras colapsadas', 'Parqueaderos', 47),
    ('Rescate', 'Rescate estructuras colapsadas', 'Otras ocupaciones y usos', 48),
    ('Rescate', 'Rescate vehicular', 'Liviano', 49),
    ('Rescate', 'Rescate vehicular', 'Pesado', 50),
    ('Rescate', 'Rescate vehicular', 'Transporte de materiales peligrosos', 51),
    ('Rescate', 'Rescate vehicular', 'Otros', 52),
    ('Rescate', 'Rescate de bombero caído (RIT)', '', 53),
    ('Materiales peligrosos (MATPEL)', 'Control del incidente', 'Clase 1: Explosivos', 54),
    ('Materiales peligrosos (MATPEL)', 'Control del incidente', 'Clase 2: Gases', 55),
    ('Materiales peligrosos (MATPEL)', 'Control del incidente', 'Clase 3: Líquidos inflamables', 56),
    ('Materiales peligrosos (MATPEL)', 'Control del incidente', 'Clase 4: Sólidos inflamables', 57),
    ('Materiales peligrosos (MATPEL)', 'Control del incidente', 'Clase 5: Sustancias oxidantes y peróxidos orgánicos', 58),
    ('Materiales peligrosos (MATPEL)', 'Control del incidente', 'Clase 6: Sustancias tóxicas', 59),
    ('Materiales peligrosos (MATPEL)', 'Control del incidente', 'Clase 7: Materiales radioactivos', 60),
    ('Materiales peligrosos (MATPEL)', 'Control del incidente', 'Clase 8: Sustancias corrosivas', 61),
    ('Materiales peligrosos (MATPEL)', 'Control del incidente', 'Clase 9: Sustancias peligrosas diversas', 62),
    ('Materiales peligrosos (MATPEL)', 'Monitoreo de atmósferas contaminadas', 'Clase 1: Explosivos', 63),
    ('Materiales peligrosos (MATPEL)', 'Monitoreo de atmósferas contaminadas', 'Clase 2: Gases', 64),
    ('Materiales peligrosos (MATPEL)', 'Monitoreo de atmósferas contaminadas', 'Clase 3: Líquidos inflamables', 65),
    ('Materiales peligrosos (MATPEL)', 'Monitoreo de atmósferas contaminadas', 'Clase 4: Sólidos inflamables', 66),
    ('Materiales peligrosos (MATPEL)', 'Monitoreo de atmósferas contaminadas', 'Clase 5: Sustancias oxidantes y peróxidos orgánicos', 67),
    ('Materiales peligrosos (MATPEL)', 'Monitoreo de atmósferas contaminadas', 'Clase 6: Sustancias tóxicas', 68),
    ('Materiales peligrosos (MATPEL)', 'Monitoreo de atmósferas contaminadas', 'Clase 7: Materiales radioactivos', 69),
    ('Materiales peligrosos (MATPEL)', 'Monitoreo de atmósferas contaminadas', 'Clase 8: Sustancias corrosivas', 70),
    ('Materiales peligrosos (MATPEL)', 'Monitoreo de atmósferas contaminadas', 'Clase 9: Sustancias peligrosas diversas', 71),
    ('Inundación y deslizamientos', 'Inundaciones', 'Ordinaria', 72),
    ('Inundación y deslizamientos', 'Inundaciones', 'Extraordinaria', 73),
    ('Inundación y deslizamientos', 'Inundaciones', 'Catastrófica', 74),
    ('Inundación y deslizamientos', 'Deslizamientos', 'En ladera', 75),
    ('Inundación y deslizamientos', 'Deslizamientos', 'En construcción', 76),
    ('Inundación y deslizamientos', 'Deslizamientos', 'En carretera', 77),
    ('Varios', 'Desfile', '', 78),
    ('Varios', 'Capacitación', '', 79),
    ('Varios', 'Simulacro', '', 80)
) AS c(clasificacion, subclasificacion, uso, orden)
ON CONFLICT ON CONSTRAINT tb_partes_catalogo_tipos_auxilio_uk DO NOTHING;
-- Filas de ejemplo del script original (con clave fija): quedan inactivas si ningún parte las usa
UPDATE operaciones.tb_partes_catalogo_tipos_auxilio c SET tipo_auxilio_estado = 'INACTIVO'
 WHERE c.tipo_auxilio_clave <> ''
   AND NOT EXISTS (SELECT 1 FROM operaciones.tb_partes_tipos_auxilio d WHERE d.fk_tipo_auxilio_id = c.tipo_auxilio_id);

-- Posibles causas por clasificación (la de "Incendio" es la lista de los partes de incendio)
CREATE TABLE IF NOT EXISTS operaciones.tb_partes_catalogo_causas (
    causa_id SERIAL NOT NULL PRIMARY KEY,
    causa_clasificacion text NOT NULL,
    causa_descripcion text NOT NULL,
    causa_orden integer NOT NULL DEFAULT 0,
    causa_estado text NOT NULL DEFAULT 'ACTIVO',
    CONSTRAINT tb_partes_catalogo_causas_uk UNIQUE (causa_clasificacion, causa_descripcion)
);
INSERT INTO operaciones.tb_partes_catalogo_causas (causa_clasificacion, causa_descripcion, causa_orden)
SELECT c.clasificacion, c.descripcion, c.orden FROM (VALUES
    ('Falsa alarma', 'Desconocido', 1),
    ('Soporte vital', 'Accidente de tránsito', 2),
    ('Soporte vital', 'Desastre natural', 3),
    ('Soporte vital', 'Evento antrópico', 4),
    ('Soporte vital', 'Otro', 5),
    ('Auxilio', 'Accidente de tránsito', 6),
    ('Auxilio', 'Daño de tubería', 7),
    ('Auxilio', 'Derrame de combustible', 8),
    ('Auxilio', 'Desastre natural', 9),
    ('Auxilio', 'Escasez de agua', 10),
    ('Auxilio', 'Evento antrópico', 11),
    ('Auxilio', 'Material sólido derramado', 12),
    ('Auxilio', 'Personas atrapadas', 13),
    ('Auxilio', 'Otro', 14),
    ('Rescate', 'Accidente de tránsito', 15),
    ('Rescate', 'Caída', 16),
    ('Rescate', 'Desaparición', 17),
    ('Rescate', 'Evento antrópico', 18),
    ('Rescate', 'Desastre natural', 19),
    ('Rescate', 'Inspección', 20),
    ('Rescate', 'Personas atrapadas', 21),
    ('Rescate', 'Trabajo en excavaciones', 22),
    ('Rescate', 'Otro', 23),
    ('Materiales peligrosos (MATPEL)', 'Accidente', 24),
    ('Materiales peligrosos (MATPEL)', 'Fuga', 25),
    ('Materiales peligrosos (MATPEL)', 'Derrame', 26),
    ('Materiales peligrosos (MATPEL)', 'Negligencia', 27),
    ('Materiales peligrosos (MATPEL)', 'Otro', 28),
    ('Inundación y deslizamientos', 'Desastre natural', 29),
    ('Inundación y deslizamientos', 'Evento antrópico', 30),
    ('Inundación y deslizamientos', 'Otro', 31),
    ('Varios', 'Solicitud documentada', 32),
    ('Varios', 'Otro', 33),
    ('Incendio', 'Accidente de tránsito', 34),
    ('Incendio', 'Combustión espontánea', 35),
    ('Incendio', 'Condiciones atmosféricas', 36),
    ('Incendio', 'Cortocircuito', 37),
    ('Incendio', 'Deflagración', 38),
    ('Incendio', 'Desconocida', 39),
    ('Incendio', 'Imprevisión', 40),
    ('Incendio', 'Intencional', 41),
    ('Incendio', 'MATPEL', 42),
    ('Incendio', 'Negligencia', 43)
) AS c(clasificacion, descripcion, orden)
ON CONFLICT ON CONSTRAINT tb_partes_catalogo_causas_uk DO NOTHING;
ALTER TABLE operaciones.tb_partes_causas ADD COLUMN IF NOT EXISTS fk_causa_id integer REFERENCES operaciones.tb_partes_catalogo_causas(causa_id);

-- Formas de aviso y apoyos (instituciones) del formato
INSERT INTO operaciones.tb_partes_catalogo_forma_aviso (forma_aviso_codigo, forma_aviso_descripcion) VALUES
    ('ECU911', 'SIS ECU 911'), ('OTRO', 'Otro')
ON CONFLICT (forma_aviso_codigo) DO NOTHING;
INSERT INTO operaciones.tb_partes_catalogo_apoyo (apoyo_codigo, apoyo_descripcion) VALUES
    ('APOYO_INTERNO', 'Apoyo interno'), ('APOYO_EXTERNO', 'Apoyo externo'),
    ('AGENTES_CONTROL_MUNICIPAL', 'Agentes de Control Municipal'), ('CNEL', 'CNEL-EP'), ('CRUZ_ROJA_ECUATORIANA', 'Cruz Roja Ecuatoriana'),
    ('CTE', 'CTE'), ('EMPMT', 'EMPMT-SD'), ('EPMAPA', 'EPMAPA-SD'), ('FUERZAS_ARMADAS', 'Fuerzas Armadas'),
    ('GRUPOS_VOLUNTARIOS', 'Grupos voluntarios reconocidos'), ('MSP', 'MSP'), ('POLICIA_NACIONAL', 'Policía Nacional'),
    ('SERVICIO_GRUA', 'Servicio de grúa'), ('SGR', 'SGR'), ('ECU911', 'SIS ECU 911')
ON CONFLICT (apoyo_codigo) DO NOTHING;

-- 3. ENLACES DE LOS DETALLES ---------------------------------------------------------------------------------
ALTER TABLE operaciones.tb_partes_vehiculos ADD COLUMN IF NOT EXISTS fk_vehiculo_id integer REFERENCES administrativo.tb_vehiculos(vehiculo_id);
ALTER TABLE operaciones.tb_partes_equipos_herramientas ADD COLUMN IF NOT EXISTS fk_recurso_id integer REFERENCES operaciones.tb_partes_catalogo_recursos(recurso_id);
ALTER TABLE operaciones.tb_partes_materiales_descartables ADD COLUMN IF NOT EXISTS fk_recurso_id integer REFERENCES operaciones.tb_partes_catalogo_recursos(recurso_id);
ALTER TABLE operaciones.tb_partes_insumos ADD COLUMN IF NOT EXISTS fk_recurso_id integer REFERENCES operaciones.tb_partes_catalogo_recursos(recurso_id);
ALTER TABLE operaciones.tb_partes_tipos_auxilio ADD COLUMN IF NOT EXISTS fk_tipo_auxilio_id integer REFERENCES operaciones.tb_partes_catalogo_tipos_auxilio(tipo_auxilio_id);

CREATE INDEX IF NOT EXISTS ix_partes_vehiculos_parte ON operaciones.tb_partes_vehiculos (fk_parte_id);
CREATE INDEX IF NOT EXISTS ix_partes_vehiculos_vehiculo ON operaciones.tb_partes_vehiculos (fk_vehiculo_id);
CREATE INDEX IF NOT EXISTS ix_partes_personal_parte ON operaciones.tb_partes_personal (fk_parte_id);
CREATE INDEX IF NOT EXISTS ix_partes_personal_personal ON operaciones.tb_partes_personal (fk_personal_id);
CREATE INDEX IF NOT EXISTS ix_partes_equipos_parte ON operaciones.tb_partes_equipos_herramientas (fk_parte_id);
CREATE INDEX IF NOT EXISTS ix_partes_materiales_parte ON operaciones.tb_partes_materiales_descartables (fk_parte_id);
CREATE INDEX IF NOT EXISTS ix_partes_insumos_parte ON operaciones.tb_partes_insumos (fk_parte_id);
CREATE INDEX IF NOT EXISTS ix_partes_tipos_auxilio_parte ON operaciones.tb_partes_tipos_auxilio (fk_parte_id);
CREATE INDEX IF NOT EXISTS ix_partes_causas_parte ON operaciones.tb_partes_causas (fk_parte_id);
CREATE INDEX IF NOT EXISTS ix_partes_asistidas_parte ON operaciones.tb_partes_personas_asistidas (fk_parte_id);
CREATE INDEX IF NOT EXISTS ix_partes_victimas_parte ON operaciones.tb_partes_victimas (fk_parte_id);
CREATE INDEX IF NOT EXISTS ix_partes_fallecidos_parte ON operaciones.tb_partes_fallecidos (fk_parte_id);

-- 4. KILOMETRAJE ACTUAL: incluye los vehículos de los partes de servicio (no anulados) --------------------------------
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
           COALESCE((SELECT MAX(GREATEST(COALESCE(pv.parte_vehiculo_km_salida, 0), COALESCE(pv.parte_vehiculo_km_retorno, 0)))
                       FROM operaciones.tb_partes_vehiculos pv JOIN operaciones.tb_partes p ON p.parte_id = pv.fk_parte_id
                      WHERE pv.fk_vehiculo_id = v.vehiculo_id AND p.parte_estado <> 'ANULADO'), 0),
           COALESCE((SELECT MAX(o.orden_km_mantenimiento) FROM logistica.tb_ordenesmantenimiento o
                      WHERE o.fk_vehiculo_id = v.vehiculo_id AND o.orden_estado <> 'ANULADA'), 0)
       )::numeric(12,2) AS vehiculo_kilometraje
FROM administrativo.tb_vehiculos v;

-- 5. PARÁMETROS (listas propias de cada institución) y ubicación por defecto del formulario (parroquia de resources.parishes; el cantón y la provincia se deducen)
INSERT INTO admin.tb_params (param_key, param_value, param_type, param_name, param_modulo) VALUES
    ('OPE_PARTE_PARROQUIA_ID', '230151', 'integer', 'Parroquia por defecto de los partes de servicio (resources.parishes.parish_id); vacío = ninguna', 'OPERACIONES')
ON CONFLICT (param_key) DO NOTHING;
INSERT INTO admin.tb_params (param_key, param_value, param_type, param_name, param_modulo) VALUES
    ('OPE_PARTE_RANGOS', 'Bro. V.|Bro. 1|Bro. 2|Bro. 3|Bro. 4|Subinspector de estación|Inspector de brigada|Subjefe de bomberos|Jefe de bomberos|Otro',
     'lista', 'Rangos del personal en los partes de servicio (separados por |)', 'OPERACIONES'),
    ('OPE_PARTE_PELOTONES', 'Pelotón 1|Pelotón 2|Pelotón 3|Apoyo', 'lista', 'Pelotones del personal en los partes de servicio (separados por |)', 'OPERACIONES'),
    ('OPE_PARTE_CLAVES', '10-1|10-2|10-12|10-17|10-19', 'lista', 'Claves de radio del tipo de auxilio y causas (separadas por |)', 'OPERACIONES')
ON CONFLICT (param_key) DO NOTHING;

-- 6. PRIVILEGIOS ------------------------------------------------------------------------------------------------
-- Acceso: /operaciones/partes (OPE_PARTES, ya existente) y /operaciones/partes-estadisticas (OPE_PARTES_ESTADISTICAS).
-- Acciones: OPE_PARTE_REGISTRAR (registrar y editar) y OPE_PARTE_ANULAR (anular y corregir partes finalizados).
ALTER TABLE admin.tb_roles ADD COLUMN IF NOT EXISTS rol_codigo text;
INSERT INTO admin.tb_submodulos (fk_modulo_id, submodulo_nombre)
SELECT m.modulo_id, 'Partes de servicio' FROM admin.tb_modulos m
 WHERE m.modulo_nombre = 'Operaciones'
   AND NOT EXISTS (SELECT 1 FROM admin.tb_submodulos x WHERE x.submodulo_nombre = 'Partes de servicio');

INSERT INTO admin.tb_roles (rol_nombre, rol_descripcion, fk_submodulo_id, rol_path, rol_codigo)
SELECT c.nombre, c.descripcion, s.submodulo_id, c.ruta, c.codigo
  FROM admin.tb_submodulos s,
       (VALUES ('Partes de servicio', 'Listado y consulta de partes de servicio', '/operaciones/partes', 'OPE_PARTES'),
               ('Estadística de partes', 'Estadística de emergencias por vehículo, estación, bombero y recurso', '/operaciones/partes-estadisticas', 'OPE_PARTES_ESTADISTICAS'),
               ('Registrar partes', 'Registrar y editar partes de servicio', NULL, 'OPE_PARTE_REGISTRAR'),
               ('Anular partes', 'Anular partes y corregir partes finalizados', NULL, 'OPE_PARTE_ANULAR')
       ) AS c(nombre, descripcion, ruta, codigo)
 WHERE s.submodulo_nombre = 'Partes de servicio'
   AND NOT EXISTS (SELECT 1 FROM admin.tb_roles r WHERE r.rol_codigo = c.codigo OR (c.ruta IS NOT NULL AND r.rol_path = c.ruta));
UPDATE admin.tb_roles SET rol_codigo = 'OPE_PARTES_ESTADISTICAS'
 WHERE rol_path = '/operaciones/partes-estadisticas' AND rol_codigo IS NULL
   AND NOT EXISTS (SELECT 1 FROM admin.tb_roles y WHERE y.rol_codigo = 'OPE_PARTES_ESTADISTICAS');

-- Asignación inicial: administrador (parámetro SIS_ADMINISTRADORES) todo; quienes ya tienen Partes de servicio: registrar y estadística;
-- quienes ven el resumen gerencial (dirección): estadística. Perfil ADMINISTRADOR: todo.
INSERT INTO admin.tb_usuario_rol (fk_usuario_id, fk_rol_id)
SELECT DISTINCT u.usuario_id, r.rol_id
  FROM admin.tb_usuarios u
  JOIN admin.tb_roles r ON r.rol_codigo IN ('OPE_PARTES', 'OPE_PARTES_ESTADISTICAS', 'OPE_PARTE_REGISTRAR', 'OPE_PARTE_ANULAR')
 WHERE admin.fn_es_administrador(u.usuario_id)
   AND NOT EXISTS (SELECT 1 FROM admin.tb_usuario_rol x WHERE x.fk_usuario_id = u.usuario_id AND x.fk_rol_id = r.rol_id);
INSERT INTO admin.tb_usuario_rol (fk_usuario_id, fk_rol_id)
SELECT DISTINCT ur.fk_usuario_id, r.rol_id
  FROM admin.tb_usuario_rol ur
  JOIN admin.tb_roles a ON a.rol_id = ur.fk_rol_id AND a.rol_codigo = 'OPE_PARTES'
  JOIN admin.tb_roles r ON r.rol_codigo IN ('OPE_PARTE_REGISTRAR', 'OPE_PARTES_ESTADISTICAS')
 WHERE NOT EXISTS (SELECT 1 FROM admin.tb_usuario_rol x WHERE x.fk_usuario_id = ur.fk_usuario_id AND x.fk_rol_id = r.rol_id);
INSERT INTO admin.tb_usuario_rol (fk_usuario_id, fk_rol_id)
SELECT DISTINCT ur.fk_usuario_id, r.rol_id
  FROM admin.tb_usuario_rol ur
  JOIN admin.tb_roles a ON a.rol_id = ur.fk_rol_id AND a.rol_codigo = 'ADM_DASHBOARD'
  JOIN admin.tb_roles r ON r.rol_codigo = 'OPE_PARTES_ESTADISTICAS'
 WHERE NOT EXISTS (SELECT 1 FROM admin.tb_usuario_rol x WHERE x.fk_usuario_id = ur.fk_usuario_id AND x.fk_rol_id = r.rol_id);
INSERT INTO admin.tb_perfil_rol (fk_perfil_id, fk_rol_id)
SELECT pf.perfil_id, r.rol_id FROM admin.tb_perfiles pf
  JOIN admin.tb_roles r ON r.rol_codigo IN ('OPE_PARTES', 'OPE_PARTES_ESTADISTICAS', 'OPE_PARTE_REGISTRAR', 'OPE_PARTE_ANULAR')
 WHERE admin.fn_perfil_es_administrador(pf.perfil_id)
ON CONFLICT DO NOTHING;


-- ======================================================================================================
-- 11. IMPORTACIÓN DESDE EL SISTEMA ANTERIOR (db_cbsd) - opcional
-- ======================================================================================================
CREATE EXTENSION IF NOT EXISTS dblink;

DO $importacion$
DECLARE
    -- >>> EDITE ESTA LÍNEA con los datos de la base del sistema anterior (db_cbsd). Si la deja con CAMBIAR, se omite.
    conexion text := 'dbname=db_cbsd host=localhost port=5432 user=postgres password=CAMBIAR';
    antes_ordenes integer;
    antes_informes integer;
    total_ordenes integer;
    total_informes integer;
BEGIN
    IF conexion LIKE '%CAMBIAR%' THEN
        RAISE NOTICE 'Importación desde db_cbsd OMITIDA: edite la variable "conexion" para ejecutarla.';
        RETURN;
    END IF;
    PERFORM dblink_connect('legacy', conexion);

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
    -- Equivalencias con el sistema anterior:
    --   orden_cargo_recepcion -> orden_informe_numero  (número del informe de pago, documento institucional, texto libre)
    --   orden_fecha_recepcion -> orden_fecha_entrega   (fecha de entrega del informe de pago)
    --   orden_fecha_entrega   -> orden_fecha_recepcion (fecha del acta entrega-recepción)
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
        orden_informe_numero          -- en el sistema anterior: orden_cargo_recepcion (número del documento, ej. CBSD-DA-2026-0207-I)
    )
    SELECT t.orden_id, t.orden_registro, t.orden_estado, t.fk_usuario_id, t.fk_vehiculo_id, t.personal_solicita, t.director_administrativo, t.tecnico_servicios, t.tecnico_puesto, t.orden_codigo, t.orden_serie, t.orden_tipomantenimiento, t.orden_fecha_mantenimiento_tipo, t.orden_fecha_mantenimiento, t.orden_km_mantenimiento, t.ultimo_km_mantenimiento, t.ultimo_fecha_mantenimiento, t.orden_proximomantenimiento, t.orden_fecha_entrega, t.orden_observaciones, t.orden_fecha_recepcion, t.orden_quien_recepcion, t.orden_cargo_recepcion
    FROM dblink('legacy', $$
        SELECT o.orden_id, o.orden_registro, o.orden_estado, o.fk_usuario_id, u.fk_vehiculo_id, o.personal_solicita, o.director_administrativo,
               o.tecnico_servicios, o.tecnico_puesto, o.orden_codigo, COALESCE(o.orden_serie, 0), o.orden_tipomantenimiento, o.orden_fecha_mantenimiento_tipo,
               o.orden_fecha_mantenimiento, o.orden_km_mantenimiento, o.ultimo_km_mantenimiento, o.ultimo_fecha_mantenimiento, o.orden_proximomantenimiento,
               -- fechas cruzadas en el sistema anterior: fecha_recepcion = informe de pago, fecha_entrega = acta entrega-recepción
               o.orden_fecha_recepcion, o.orden_observaciones, o.orden_fecha_entrega, o.orden_quien_recepcion, o.orden_cargo_recepcion
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
    PERFORM setval(pg_get_serial_sequence('admin.tb_sistema', 'sistema_id'), COALESCE((SELECT MAX(sistema_id) FROM admin.tb_sistema), 0) + 1, false);
    PERFORM setval(pg_get_serial_sequence('admin.tb_params', 'param_id'), COALESCE((SELECT MAX(param_id) FROM admin.tb_params), 0) + 1, false);
    PERFORM setval(pg_get_serial_sequence('logistica.tb_planesmantenimiento', 'plan_id'), COALESCE((SELECT MAX(plan_id) FROM logistica.tb_planesmantenimiento), 0) + 1, false);
    PERFORM setval(pg_get_serial_sequence('logistica.tb_reglasmantenimiento', 'mantenimiento_id'), COALESCE((SELECT MAX(mantenimiento_id) FROM logistica.tb_reglasmantenimiento), 0) + 1, false);
    PERFORM setval(pg_get_serial_sequence('logistica.tb_recursosmantenimiento', 'recurso_id'), COALESCE((SELECT MAX(recurso_id) FROM logistica.tb_recursosmantenimiento), 0) + 1, false);
    PERFORM setval(pg_get_serial_sequence('logistica.tb_mantenimiento_recursos', 'regla_id'), COALESCE((SELECT MAX(regla_id) FROM logistica.tb_mantenimiento_recursos), 0) + 1, false);
    PERFORM setval(pg_get_serial_sequence('logistica.tb_ordenesmantenimiento', 'orden_id'), COALESCE((SELECT MAX(orden_id) FROM logistica.tb_ordenesmantenimiento), 0) + 1, false);
    PERFORM setval(pg_get_serial_sequence('logistica.tb_mantenimiento_trabajos', 'trabajo_id'), COALESCE((SELECT MAX(trabajo_id) FROM logistica.tb_mantenimiento_trabajos), 0) + 1, false);
    PERFORM setval(pg_get_serial_sequence('logistica.tb_mantenimiento_sugeridos', 'trabajo_id'), COALESCE((SELECT MAX(trabajo_id) FROM logistica.tb_mantenimiento_sugeridos), 0) + 1, false);
    PERFORM setval(pg_get_serial_sequence('logistica.tb_mantenimiento_facturas', 'factura_id'), COALESCE((SELECT MAX(factura_id) FROM logistica.tb_mantenimiento_facturas), 0) + 1, false);
    PERFORM setval(pg_get_serial_sequence('logistica.tb_mantenimiento_anexos', 'anexo_id'), COALESCE((SELECT MAX(anexo_id) FROM logistica.tb_mantenimiento_anexos), 0) + 1, false);
    PERFORM setval(pg_get_serial_sequence('logistica.tb_informemantenimiento', 'informe_id'), COALESCE((SELECT MAX(informe_id) FROM logistica.tb_informemantenimiento), 0) + 1, false);

    SELECT n INTO total_ordenes FROM dblink('legacy', 'SELECT count(*) FROM logistica.tb_ordenesmantenimiento') AS t(n integer);
    SELECT n INTO total_informes FROM dblink('legacy', 'SELECT count(*) FROM logistica.tb_informemantenimiento') AS t(n integer);
    SELECT count(*) INTO antes_ordenes FROM logistica.tb_ordenesmantenimiento WHERE fk_contrato_id IS NULL;
    SELECT count(*) INTO antes_informes FROM logistica.tb_informemantenimiento WHERE fk_contrato_id IS NULL;
    RAISE NOTICE 'Importación terminada. Órdenes en db_cbsd: %, sin contrato en la base nueva: %. Informes en db_cbsd: %, en la base nueva: %.',
        total_ordenes, antes_ordenes, total_informes, antes_informes;
    PERFORM dblink_disconnect('legacy');
END
$importacion$;


-- ======================================================================================================
-- 12. REGISTRO INICIAL DE LA INSTITUCIÓN (solo si no se importó ni existe)
-- ======================================================================================================
INSERT INTO admin.tb_sistema (sistema_nombre, sistema_siglas, sistema_slogan, sistema_ciudad, sistema_direccion,
                              sistema_telefono, sistema_correo, sistema_sitioweb, sistema_facebook, sistema_twitter)
SELECT 'CUERPO DE BOMBEROS SANTO DOMINGO', 'CBSD', 'Juntos hacia el crecimiento institucional', 'Santo Domingo',
       'Av. Jacinto Cortez y Jorge Icaza', '(02) 3959-340', 'info@cbsd.gob.ec', 'http://bomberosantodomingo.gob.ec',
       '/CuerpoDeBomberosSantoDomingo', '@BomberosSD'
 WHERE NOT EXISTS (SELECT 1 FROM admin.tb_sistema);
-- Completar siglas/slogan/redes del registro importado si vinieron vacíos
UPDATE admin.tb_sistema SET sistema_slogan = COALESCE(sistema_slogan, 'Juntos hacia el crecimiento institucional'),
                            sistema_facebook = COALESCE(sistema_facebook, '/CuerpoDeBomberosSantoDomingo'),
                            sistema_twitter = COALESCE(sistema_twitter, '@BomberosSD');


-- ======================================================================================================
-- 13. ACCESO DE LOS ADMINISTRADORES (todos los privilegios; parámetros SIS_ADMINISTRADORES y SIS_PERFILES_ADMINISTRADOR)
-- ======================================================================================================
-- =============================================================================
-- ACCESO DE LOS ADMINISTRADORES - re-ejecutable, va AL FINAL de script-3
-- Los administradores (parámetro SIS_ADMINISTRADORES: usuario_id o login) y los perfiles de administrador
-- (parámetro SIS_PERFILES_ADMINISTRADOR) reciben TODOS los privilegios existentes, incluidos los que agreguen
-- migraciones nuevas. Para cambiar quién es administrador:
--   UPDATE admin.tb_params SET param_value = '113|mi.usuario' WHERE param_key = 'SIS_ADMINISTRADORES';
-- y volver a ejecutar esta sección (o script-3 completo).
-- =============================================================================

-- 1. Perfiles de administrador: todos los privilegios
INSERT INTO admin.tb_perfil_rol (fk_perfil_id, fk_rol_id)
SELECT p.perfil_id, r.rol_id
  FROM admin.tb_perfiles p CROSS JOIN admin.tb_roles r
 WHERE admin.fn_perfil_es_administrador(p.perfil_id)
ON CONFLICT DO NOTHING;

-- 2. Usuarios administradores: todos los privilegios como adicionales (no dependen de su perfil ni de su estado)
INSERT INTO admin.tb_usuario_rol (fk_usuario_id, fk_rol_id)
SELECT u.usuario_id, r.rol_id
  FROM admin.tb_usuarios u CROSS JOIN admin.tb_roles r
 WHERE admin.fn_es_administrador(u.usuario_id)
   AND NOT EXISTS (SELECT 1 FROM admin.tb_usuario_rol x WHERE x.fk_usuario_id = u.usuario_id AND x.fk_rol_id = r.rol_id);

-- 3. Perfil de administrador activo (un perfil inactivo no da privilegios)
UPDATE admin.tb_perfiles p SET perfil_estado = 'ACTIVO'
 WHERE admin.fn_perfil_es_administrador(p.perfil_id) AND perfil_estado IS DISTINCT FROM 'ACTIVO';

-- 4. Resultado: administradores, su estado y cuántos privilegios efectivos tienen (debe ser el total de privilegios)
SELECT u.usuario_id, u.usuario_login, COALESCE(u.usuario_estado, 'ACTIVO') AS estado, pf.perfil_nombre,
       (SELECT count(DISTINCT v.rol_id) FROM admin.vw_usuario_privilegios v WHERE v.usuario_id = u.usuario_id) AS privilegios,
       (SELECT count(*) FROM admin.tb_roles) AS total_privilegios
  FROM admin.tb_usuarios u LEFT JOIN admin.tb_perfiles pf ON pf.perfil_id = u.fk_perfil_id
 WHERE admin.fn_es_administrador(u.usuario_id)
 ORDER BY u.usuario_id;
