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
