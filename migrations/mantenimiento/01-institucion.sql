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
    ('MANT_TECNICO_PUESTO', 'PROFESIONAL TÉCNICO EN SERVICIOS GENERALES', 'text', 'Cargo del técnico que firma las órdenes de mantenimiento', 'MANTENIMIENTO'),
    ('MANT_INFORME_CARGO', 'ADMINISTRADOR DE CONTRATO', 'text', 'Cargo de quien firma los informes de mantenimiento', 'MANTENIMIENTO')
ON CONFLICT (param_key) DO NOTHING;
