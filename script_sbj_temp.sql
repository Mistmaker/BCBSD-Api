CREATE SCHEMA IF NOT EXISTS subjefatura AUTHORIZATION postgres;

DROP TABLE IF EXISTS subjefatura.tb_tipoincidencia CASCADE;
CREATE TABLE IF NOT EXISTS subjefatura.tb_tipoincidencia (
    incidencia_id SERIAL NOT NULL PRIMARY KEY,
    incidencia_estado text COLLATE pg_catalog."default" DEFAULT 'ACTIVO'::text,
    incidencia_registro timestamp without time zone DEFAULT ('now'::text)::timestamp(0) with time zone,
    incidencia_descripcion text NOT NULL COLLATE pg_catalog."default"
) WITH (OIDS = FALSE) TABLESPACE pg_default;

DROP TABLE IF EXISTS subjefatura.tb_tipoemergencia CASCADE;
CREATE TABLE IF NOT EXISTS subjefatura.tb_tipoemergencia (
    emergencia_id SERIAL NOT NULL PRIMARY KEY,
    fk_incidencia_id INT NOT NULL REFERENCES subjefatura.tb_tipoincidencia(incidencia_id) ON DELETE RESTRICT ON UPDATE RESTRICT, 
    emergencia_estado text COLLATE pg_catalog."default" DEFAULT 'ACTIVO'::text,
    emergencia_registro timestamp without time zone DEFAULT ('now'::text)::timestamp(0) with time zone,
    emergencia_descripcion text NOT NULL COLLATE pg_catalog."default"
) WITH (OIDS = FALSE) TABLESPACE pg_default;

DROP TABLE IF EXISTS subjefatura.tb_causas CASCADE;
CREATE TABLE IF NOT EXISTS subjefatura.tb_causas (
    causa_id SERIAL NOT NULL PRIMARY KEY,
    fk_incidencia_id INT NOT NULL REFERENCES subjefatura.tb_tipoincidencia(incidencia_id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    causa_estado text COLLATE pg_catalog."default" DEFAULT 'ACTIVO'::text,
    causa_registro timestamp without time zone DEFAULT ('now'::text)::timestamp(0) with time zone,
    causa_codigo text COLLATE pg_catalog."default",
    causa_descripcion text NOT NULL COLLATE pg_catalog."default"
) WITH (OIDS = FALSE) TABLESPACE pg_default;

DROP TABLE IF EXISTS subjefatura.tb_naturaleza CASCADE;
CREATE TABLE IF NOT EXISTS subjefatura.tb_naturaleza(
    naturaleza_id SERIAL NOT NULL PRIMARY KEY,
    fk_incidencia_id INT NOT NULL REFERENCES subjefatura.tb_tipoincidencia(incidencia_id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    naturaleza_estado text COLLATE pg_catalog."default" DEFAULT 'ACTIVO'::text,
    naturaleza_registro timestamp without time zone DEFAULT ('now'::text)::timestamp(0) with time zone,
    naturaleza_descripcion text NOT NULL COLLATE pg_catalog."default"
) WITH (OIDS = FALSE) TABLESPACE pg_default;

DROP TABLE IF EXISTS subjefatura.tb_intervenciones CASCADE;
CREATE TABLE IF NOT EXISTS subjefatura.tb_intervenciones(
    intervencion_id SERIAL NOT NULL PRIMARY KEY,
    fk_estacion_id int not null,
    fk_incidencia_id int not null,
    fk_emergencia_id int not null,
    fk_causa_id int not null,
    fk_naturaleza_id int,
    fk_unidad_id int not null,
    fk_personal_id int not null REFERENCES tthh.tb_personal (personal_id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    fk_parroquia_id int not null,
    intervencion_longitud text COLLATE pg_catalog."default",
    intervencion_latitud text COLLATE pg_catalog."default",
    intervencion_estado text COLLATE pg_catalog."default" DEFAULT 'ACTIVO'::text,
    intervencion_registro timestamp without time zone DEFAULT ('now'::text)::timestamp(0) with time zone,
    intervencion_fecha timestamp without time zone NOT NULL,
    intervencion_direccion text COLLATE pg_catalog."default",
    incidencia_beneficiarios int not null DEFAULT 0,
    incidencia_fallecidos int not null DEFAULT 0
) WITH (OIDS = FALSE) TABLESPACE pg_default;

-- CONTROL DE AUSENCIAS (TIPOS DE AUSENCIUAS)
DROP TABLE IF EXISTS subjefatura.tb_tipoasusencia CASCADE;
CREATE TABLE IF NOT EXISTS subjefatura.tb_tipoasusencia (
    tipoasusencia_id SERIAL NOT NULL PRIMARY KEY,
    tipoasusencia_estado text COLLATE pg_catalog."default" DEFAULT 'ACTIVO'::text,
    tipoasusencia_registro timestamp without time zone DEFAULT ('now'::text)::timestamp(0) with time zone,
    tipoasusencia_descripcion text NOT NULL COLLATE pg_catalog."default"
) WITH (OIDS = FALSE) TABLESPACE pg_default;

-- CONTROL DE AUSENCIAS (AUSENCIA)
DROP TABLE IF EXISTS subjefatura.tb_asusencia CASCADE;
CREATE TABLE IF NOT EXISTS subjefatura.tb_asusencia (
    asusencia_id SERIAL NOT NULL PRIMARY KEY,
    fk_tipoausencia_id INT NOT NULL REFERENCES subjefatura.tb_tipoasusencia (tipoasusencia_id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    fk_personal_id INT NOT NULL REFERENCES tthh.tb_personal (personal_id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    fk_estacion_id INT NOT NULL REFERENCES operaciones.tb_estaciones (estacion_id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    asusencia_estado text COLLATE pg_catalog."default" DEFAULT 'ACTIVO'::text,
    asusencia_registro timestamp without time zone DEFAULT ('now'::text)::timestamp(0) with time zone,
    asusencia_descripcion text NOT NULL COLLATE pg_catalog."default"
) WITH (OIDS = FALSE) TABLESPACE pg_default;

-- HOJA DE RUTA DE APH
DROP TABLE IF EXISTS subjefatura.tb_aph_hojaruta_tipoemergencia CASCADE;
CREATE TABLE IF NOT EXISTS subjefatura.tb_aph_hojaruta_tipoemergencia (
    aph_hojaruta_tipoemergencia_id SERIAL NOT NULL PRIMARY KEY,
    aph_hojaruta_tipoemergencia_descripcion text NOT NULL COLLATE pg_catalog."default"
) WITH (OIDS = FALSE) TABLESPACE pg_default;

DROP TABLE IF EXISTS subjefatura.tb_aph_hojaruta CASCADE;
CREATE TABLE IF NOT EXISTS subjefatura.tb_aph_hojaruta (
    aph_hojaruta_id SERIAL NOT NULL PRIMARY KEY,
    fk_responsable_atencion INT NOT NULL REFERENCES tthh.tb_personal (personal_id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    fk_tipo_emergencia INT NOT NULL REFERENCES subjefatura.tb_aph_hojaruta_tipoemergencia (aph_hojaruta_tipoemergencia_id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    fk_estacion_id INT NOT NULL REFERENCES operaciones.tb_estaciones (estacion_id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    fk_parroquia_id INT NOT NULL,
    aph_hojaruta_registro timestamp without time zone DEFAULT ('now'::text)::timestamp(0) with time zone,
    aph_hojaruta_codigo text COLLATE pg_catalog."default",
    aph_hojaruta_codigo002 text COLLATE pg_catalog."default",
    aph_hojaruta_fecha timestamp without time zone NOT NULL,
    aph_hojaruta_direccion text COLLATE pg_catalog."default",
    aph_hojaruta_hora_salida_estacion text COLLATE pg_catalog."default",
    aph_hojaruta_hora_retorno_estacion text COLLATE pg_catalog."default"
) WITH (OIDS = FALSE) TABLESPACE pg_default;

DROP TABLE IF EXISTS subjefatura.tb_aph_hojaruta_vehiculos CASCADE;
CREATE TABLE IF NOT EXISTS subjefatura.tb_aph_hojaruta_vehiculos (
    aph_hojaruta_vehiculo_id SERIAL NOT NULL PRIMARY KEY,
    fk_aph_hojaruta_id INT NOT NULL REFERENCES subjefatura.tb_aph_hojaruta (aph_hojaruta_id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    fk_vehiculo INT NOT NULL,
    fk_operador INT NOT NULL REFERENCES tthh.tb_personal (personal_id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    aph_hojaruta_vehiculo_kilometraje_salida text COLLATE pg_catalog."default",
    aph_hojaruta_vehiculo_kilometraje_retorno text COLLATE pg_catalog."default",
    aph_hojaruta_vehiculo_hora_salida text COLLATE pg_catalog."default",
    aph_hojaruta_vehiculo_hora_arribo text COLLATE pg_catalog."default",
    aph_hojaruta_vehiculo_hora_retorno text COLLATE pg_catalog."default"
) WITH (OIDS = FALSE) TABLESPACE pg_default;

DROP TABLE IF EXISTS subjefatura.tb_aph_hojaruta_pacientes CASCADE;
CREATE TABLE IF NOT EXISTS subjefatura.tb_aph_hojaruta_pacientes (
    aph_hojaruta_paciente_id SERIAL NOT NULL PRIMARY KEY,
    fk_aph_hojaruta_id INT NOT NULL REFERENCES subjefatura.tb_aph_hojaruta (aph_hojaruta_id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    fk_cie10 text COLLATE pg_catalog."default",
    aph_hojaruta_paciente_cedula text COLLATE pg_catalog."default",
    aph_hojaruta_paciente_nombres text COLLATE pg_catalog."default",
    aph_hojaruta_paciente_apellidos text COLLATE pg_catalog."default",
    aph_hojaruta_paciente_edad text COLLATE pg_catalog."default",
    aph_hojaruta_paciente_sexo text COLLATE pg_catalog."default",
    aph_hojaruta_paciente_condicion_inicial text COLLATE pg_catalog."default",
    aph_hojaruta_paciente_condicion_final text COLLATE pg_catalog."default",
    aph_hojaruta_paciente_diagnostico_preliminar text COLLATE pg_catalog."default",
    aph_hojaruta_paciente_destino text COLLATE pg_catalog."default"
) WITH (OIDS = FALSE) TABLESPACE pg_default;

DROP TABLE IF EXISTS subjefatura.tb_aph_medicamentos CASCADE;
CREATE TABLE IF NOT EXISTS subjefatura.tb_aph_medicamentos (
    medicamento_id SERIAL NOT NULL PRIMARY KEY,
    medicamento_nombre text COLLATE pg_catalog."default",
    medicamento_presentacion text COLLATE pg_catalog."default"
) WITH (OIDS = FALSE) TABLESPACE pg_default;

DROP TABLE IF EXISTS subjefatura.tb_aph_hojaruta_medicamentos CASCADE;
CREATE TABLE IF NOT EXISTS subjefatura.tb_aph_hojaruta_medicamentos (
    aph_hojaruta_medicamento_id SERIAL NOT NULL PRIMARY KEY,
    fk_aph_hojaruta_id INT NOT NULL REFERENCES subjefatura.tb_aph_hojaruta (aph_hojaruta_id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    fk_aph_hojaruta_paciente_id INT NOT NULL REFERENCES subjefatura.tb_aph_hojaruta_pacientes (aph_hojaruta_paciente_id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    fk_medicamento_id INT NOT NULL,
    aph_hojaruta_medicamento_presentacion text COLLATE pg_catalog."default",
    aph_hojaruta_medicamento_cantidad text COLLATE pg_catalog."default"
    -- aph_hojaruta_medicamento_dosis text COLLATE pg_catalog."default",
    -- aph_hojaruta_medicamento_via_administracion text COLLATE pg_catalog."default",
    -- aph_hojaruta_medicamento_frecuencia text COLLATE pg_catalog."default"
) WITH (OIDS = FALSE) TABLESPACE pg_default;

-- PARTES DE AUXILIO E INCENDIO
-- Una sola cabecera compartida por partes de auxilio e incendio.
DROP TABLE IF EXISTS operaciones.tb_partes CASCADE;
CREATE TABLE IF NOT EXISTS operaciones.tb_partes (
    parte_id SERIAL NOT NULL PRIMARY KEY,
    parte_registro timestamp without time zone DEFAULT ('now'::text)::timestamp(0) with time zone,
    parte_estado text COLLATE pg_catalog."default" DEFAULT 'REGISTRADO'::text,
    parte_numero text COLLATE pg_catalog."default" NOT NULL,
    parte_tipo text COLLATE pg_catalog."default" NOT NULL,
    fk_estacion_id integer NOT NULL REFERENCES operaciones.tb_estaciones(estacion_id),
    fk_usuario_id integer NOT NULL REFERENCES admin.tb_usuarios(usuario_id),
    fk_personal_despacho_id integer REFERENCES tthh.tb_personal(personal_id),
    fk_personal_id integer NOT NULL REFERENCES tthh.tb_personal(personal_id),
    fk_parroquia_id integer NOT NULL REFERENCES resources.parishes(parish_id),
    parte_fecha date NOT NULL,
    parte_fecha_aviso date,
    parte_forma_aviso text COLLATE pg_catalog."default" NOT NULL,
    parte_codigo_salida text COLLATE pg_catalog."default" NOT NULL,
    parte_tipo_dia text COLLATE pg_catalog."default" DEFAULT 'LABORABLE'::text,
    parte_grupo_asiste text COLLATE pg_catalog."default" NOT NULL,
    parte_hora_aviso time without time zone NOT NULL,
    parte_hora_transferencia_ecu smallint,
    parte_minuto_transferencia_ecu smallint,
    parte_hora_salida time without time zone NOT NULL,
    parte_hora_arribo time without time zone NOT NULL,
    parte_hora_finalizacion time without time zone NOT NULL,
    parte_hora_retorno time without time zone NOT NULL,
    parte_apoyo_requerido text COLLATE pg_catalog."default",
    parte_apoyo text COLLATE pg_catalog."default",
    parte_apoyo_otros text COLLATE pg_catalog."default",
    parte_provincia integer NOT NULL REFERENCES resources.states(state_id),
    parte_canton integer NOT NULL REFERENCES resources.towns(town_id),
    parte_parroquia integer NOT NULL REFERENCES resources.parishes(parish_id),
    parte_direccion text COLLATE pg_catalog."default" NOT NULL,
    parte_calle_principal text COLLATE pg_catalog."default",
    parte_calle_secundaria text COLLATE pg_catalog."default",
    parte_numero_domicilio text COLLATE pg_catalog."default",
    parte_telefono text COLLATE pg_catalog."default",
    parte_sector text COLLATE pg_catalog."default",
    parte_tipo_sector text COLLATE pg_catalog."default",
    parte_referencia text COLLATE pg_catalog."default",
    parte_informacion_alertante text COLLATE pg_catalog."default",
    parte_institucion_tipo text COLLATE pg_catalog."default",
    parte_institucion_propiedad text COLLATE pg_catalog."default",
    parte_observacion_institucion text COLLATE pg_catalog."default",
    parte_observacion_victimas text COLLATE pg_catalog."default",
    parte_observacion_fallecidos text COLLATE pg_catalog."default",
    parte_tipo_afectado text COLLATE pg_catalog."default",
    parte_afectado_propietario text COLLATE pg_catalog."default",
    parte_afectado_arrendatario text COLLATE pg_catalog."default",
    parte_afectado_otros text COLLATE pg_catalog."default",
    parte_area_destruida_m2 numeric(16,4) NOT NULL DEFAULT 0,
    parte_especies_predominantes text COLLATE pg_catalog."default" NOT NULL DEFAULT 'NINGUNA'::text,
    parte_total_superficie_quemada text COLLATE pg_catalog."default" NOT NULL DEFAULT 'NINGUNA'::text,
    parte_total_superficie_quemada_m2 numeric(16,4),
    parte_lugar_posible_inicio text COLLATE pg_catalog."default",
    parte_personas_institucion text COLLATE pg_catalog."default" DEFAULT 'NINGUNA'::text,
    parte_nombre_representante text COLLATE pg_catalog."default" DEFAULT 'NINGUNA'::text,
    parte_propietario_afectado text COLLATE pg_catalog."default" DEFAULT 'NINGUNO'::text,
    parte_datos_adicionales text COLLATE pg_catalog."default" DEFAULT 'NINGUNO'::text,
    parte_causante_identificado boolean,
    parte_nombre_causante text COLLATE pg_catalog."default",
    parte_otros_datos_causante text COLLATE pg_catalog."default",
    parte_naturaleza_especifique text COLLATE pg_catalog."default",
    parte_total_muertos integer NOT NULL DEFAULT 0,
    parte_total_heridos integer NOT NULL DEFAULT 0,
    parte_danios_materiales text COLLATE pg_catalog."default" NOT NULL DEFAULT 'NINGUNA'::text,
    parte_anexo_requerido boolean,
    parte_visita_inspectores boolean,
    parte_visita_inspectores_motivo text COLLATE pg_catalog."default",
    parte_descripcion_operaciones text COLLATE pg_catalog."default" NOT NULL,
    parte_longitud numeric(10,7),
    parte_latitud numeric(10,7),
    parte_novedades text COLLATE pg_catalog."default",
    parte_croquis_url text COLLATE pg_catalog."default",
    parte_elaborado_por text COLLATE pg_catalog."default",
    parte_revisado_por text COLLATE pg_catalog."default",
    parte_aprobado_por text COLLATE pg_catalog."default",
    parte_entregado_a text COLLATE pg_catalog."default",
    parte_entregado_identificacion text COLLATE pg_catalog."default",
    parte_fecha_entrega date
) WITH (OIDS = FALSE) TABLESPACE pg_default;

CREATE TABLE IF NOT EXISTS operaciones.tb_partes_personal (
    parte_personal_id SERIAL NOT NULL PRIMARY KEY,
    fk_parte_id integer NOT NULL REFERENCES operaciones.tb_partes(parte_id) ON DELETE CASCADE,
    fk_personal_id integer NOT NULL REFERENCES tthh.tb_personal(personal_id),
    parte_personal_rol text COLLATE pg_catalog."default",
    parte_personal_rango text COLLATE pg_catalog."default",
    parte_personal_grupo text COLLATE pg_catalog."default"
) WITH (OIDS = FALSE) TABLESPACE pg_default;

CREATE TABLE IF NOT EXISTS operaciones.tb_partes_vehiculos (
    parte_vehiculo_id SERIAL NOT NULL PRIMARY KEY,
    fk_parte_id integer NOT NULL REFERENCES operaciones.tb_partes(parte_id) ON DELETE CASCADE,
    fk_estacion_id integer REFERENCES operaciones.tb_estaciones(estacion_id),
    parte_vehiculo_placa text COLLATE pg_catalog."default",
    parte_vehiculo_siglas text COLLATE pg_catalog."default",
    parte_vehiculo_km_salida numeric,
    parte_vehiculo_km_retorno numeric,
    parte_vehiculo_hora_despacho timestamp without time zone,
    parte_vehiculo_hora_salida timestamp without time zone,
    parte_vehiculo_hora_arribo timestamp without time zone,
    parte_vehiculo_hora_fin_operaciones timestamp without time zone,
    parte_vehiculo_apoyo text COLLATE pg_catalog."default"
) WITH (OIDS = FALSE) TABLESPACE pg_default;

CREATE TABLE IF NOT EXISTS operaciones.tb_partes_tipos_auxilio (
    parte_tipo_auxilio_id SERIAL NOT NULL PRIMARY KEY,
    fk_parte_id integer NOT NULL REFERENCES operaciones.tb_partes(parte_id) ON DELETE CASCADE,
    parte_auxilio_clave text COLLATE pg_catalog."default",
    parte_auxilio_clasificacion text COLLATE pg_catalog."default",
    parte_auxilio_subclasificacion text COLLATE pg_catalog."default",
    parte_auxilio_uso_tipo text COLLATE pg_catalog."default",
    parte_auxilio_especifique text COLLATE pg_catalog."default"
) WITH (OIDS = FALSE) TABLESPACE pg_default;

CREATE TABLE IF NOT EXISTS operaciones.tb_partes_causas (
    parte_causa_id SERIAL NOT NULL PRIMARY KEY,
    fk_parte_id integer NOT NULL REFERENCES operaciones.tb_partes(parte_id) ON DELETE CASCADE,
    parte_causa_clave text COLLATE pg_catalog."default",
    parte_causa_clasificacion text COLLATE pg_catalog."default",
    parte_causa_descripcion text COLLATE pg_catalog."default",
    parte_causa_especifique text COLLATE pg_catalog."default"
) WITH (OIDS = FALSE) TABLESPACE pg_default;

CREATE TABLE IF NOT EXISTS operaciones.tb_partes_equipos_herramientas (
    parte_equipo_herramienta_id SERIAL NOT NULL PRIMARY KEY,
    fk_parte_id integer NOT NULL REFERENCES operaciones.tb_partes(parte_id) ON DELETE CASCADE,
    fk_estacion_id integer REFERENCES operaciones.tb_estaciones(estacion_id),
    parte_recurso_descripcion text COLLATE pg_catalog."default",
    parte_recurso_cantidad numeric,
    parte_recurso_observaciones text COLLATE pg_catalog."default"
) WITH (OIDS = FALSE) TABLESPACE pg_default;

CREATE TABLE IF NOT EXISTS operaciones.tb_partes_materiales_descartables (
    parte_material_descartable_id SERIAL NOT NULL PRIMARY KEY,
    fk_parte_id integer NOT NULL REFERENCES operaciones.tb_partes(parte_id) ON DELETE CASCADE,
    fk_estacion_id integer REFERENCES operaciones.tb_estaciones(estacion_id),
    parte_recurso_descripcion text COLLATE pg_catalog."default",
    parte_recurso_cantidad numeric,
    parte_recurso_observaciones text COLLATE pg_catalog."default"
) WITH (OIDS = FALSE) TABLESPACE pg_default;

CREATE TABLE IF NOT EXISTS operaciones.tb_partes_insumos (
    parte_insumo_id SERIAL NOT NULL PRIMARY KEY,
    fk_parte_id integer NOT NULL REFERENCES operaciones.tb_partes(parte_id) ON DELETE CASCADE,
    fk_estacion_id integer REFERENCES operaciones.tb_estaciones(estacion_id),
    parte_recurso_descripcion text COLLATE pg_catalog."default",
    parte_recurso_cantidad numeric,
    parte_recurso_observaciones text COLLATE pg_catalog."default"
) WITH (OIDS = FALSE) TABLESPACE pg_default;

CREATE TABLE IF NOT EXISTS operaciones.tb_partes_personas_asistidas (
    parte_persona_asistida_id SERIAL NOT NULL PRIMARY KEY,
    fk_parte_id integer NOT NULL REFERENCES operaciones.tb_partes(parte_id) ON DELETE CASCADE,
    parte_persona_institucion text COLLATE pg_catalog."default",
    parte_persona_tipo_institucion text COLLATE pg_catalog."default",
    parte_persona_nombre text COLLATE pg_catalog."default",
    parte_persona_identificacion text COLLATE pg_catalog."default",
    parte_persona_telefono text COLLATE pg_catalog."default",
    parte_persona_propiedad text COLLATE pg_catalog."default"
) WITH (OIDS = FALSE) TABLESPACE pg_default;

CREATE TABLE IF NOT EXISTS operaciones.tb_partes_victimas (
    parte_victima_id SERIAL NOT NULL PRIMARY KEY,
    fk_parte_id integer NOT NULL REFERENCES operaciones.tb_partes(parte_id) ON DELETE CASCADE,
    parte_victima_numero_hoja text COLLATE pg_catalog."default",
    parte_victima_tipo_identificacion text COLLATE pg_catalog."default",
    parte_victima_identificacion text COLLATE pg_catalog."default",
    parte_victima_nombres text COLLATE pg_catalog."default",
    parte_victima_edad numeric,
    parte_victima_tipo_edad text COLLATE pg_catalog."default",
    parte_victima_sexo text COLLATE pg_catalog."default",
    parte_victima_signos_sintomas text COLLATE pg_catalog."default",
    parte_victima_traslado text COLLATE pg_catalog."default"
) WITH (OIDS = FALSE) TABLESPACE pg_default;

CREATE TABLE IF NOT EXISTS operaciones.tb_partes_fallecidos (
    parte_fallecido_id SERIAL NOT NULL PRIMARY KEY,
    fk_parte_id integer NOT NULL REFERENCES operaciones.tb_partes(parte_id) ON DELETE CASCADE,
    parte_fallecido_numero text COLLATE pg_catalog."default",
    parte_fallecido_tipo_identificacion text COLLATE pg_catalog."default",
    parte_fallecido_identificacion text COLLATE pg_catalog."default",
    parte_fallecido_nombres text COLLATE pg_catalog."default",
    parte_fallecido_edad numeric,
    parte_fallecido_tipo_edad text COLLATE pg_catalog."default",
    parte_fallecido_sexo text COLLATE pg_catalog."default",
    parte_fallecido_observaciones text COLLATE pg_catalog."default",
    parte_fallecido_traslado text COLLATE pg_catalog."default"
) WITH (OIDS = FALSE) TABLESPACE pg_default;

CREATE TABLE IF NOT EXISTS operaciones.tb_partes_catalogo_tipos_incendio (
    tipo_incendio_id SERIAL NOT NULL PRIMARY KEY,
    tipo_incendio_codigo text COLLATE pg_catalog."default" NOT NULL UNIQUE,
    tipo_incendio_descripcion text COLLATE pg_catalog."default" NOT NULL,
    tipo_incendio_estado text COLLATE pg_catalog."default" NOT NULL DEFAULT 'ACTIVO'::text
) WITH (OIDS = FALSE) TABLESPACE pg_default;

CREATE TABLE IF NOT EXISTS operaciones.tb_partes_catalogo_causas_incendio (
    causa_incendio_id SERIAL NOT NULL PRIMARY KEY,
    causa_incendio_codigo text COLLATE pg_catalog."default" NOT NULL UNIQUE,
    causa_incendio_descripcion text COLLATE pg_catalog."default" NOT NULL,
    causa_incendio_estado text COLLATE pg_catalog."default" NOT NULL DEFAULT 'ACTIVO'::text
) WITH (OIDS = FALSE) TABLESPACE pg_default;

CREATE TABLE IF NOT EXISTS operaciones.tb_partes_catalogo_naturalezas (
    naturaleza_id SERIAL NOT NULL PRIMARY KEY,
    naturaleza_codigo text COLLATE pg_catalog."default" NOT NULL UNIQUE,
    naturaleza_descripcion text COLLATE pg_catalog."default" NOT NULL,
    naturaleza_estado text COLLATE pg_catalog."default" NOT NULL DEFAULT 'ACTIVO'::text
) WITH (OIDS = FALSE) TABLESPACE pg_default;

CREATE TABLE IF NOT EXISTS operaciones.tb_partes_catalogo_causas_afectacion_humana (
    causa_afectacion_humana_id SERIAL NOT NULL PRIMARY KEY,
    causa_afectacion_humana_codigo text COLLATE pg_catalog."default" NOT NULL UNIQUE,
    causa_afectacion_humana_descripcion text COLLATE pg_catalog."default" NOT NULL,
    causa_afectacion_humana_estado text COLLATE pg_catalog."default" NOT NULL DEFAULT 'ACTIVO'::text
) WITH (OIDS = FALSE) TABLESPACE pg_default;

CREATE TABLE IF NOT EXISTS operaciones.tb_partes_catalogo_tipo_afectado (
    tipo_afectado_id SERIAL NOT NULL PRIMARY KEY,
    tipo_afectado_codigo text COLLATE pg_catalog."default" NOT NULL UNIQUE,
    tipo_afectado_descripcion text COLLATE pg_catalog."default" NOT NULL,
    tipo_afectado_estado text COLLATE pg_catalog."default" NOT NULL DEFAULT 'ACTIVO'::text
) WITH (OIDS = FALSE) TABLESPACE pg_default;

CREATE TABLE IF NOT EXISTS operaciones.tb_partes_catalogo_forma_aviso (
    forma_aviso_id SERIAL NOT NULL PRIMARY KEY,
    forma_aviso_codigo text COLLATE pg_catalog."default" NOT NULL UNIQUE,
    forma_aviso_descripcion text COLLATE pg_catalog."default" NOT NULL,
    forma_aviso_estado text COLLATE pg_catalog."default" NOT NULL DEFAULT 'ACTIVO'::text
) WITH (OIDS = FALSE) TABLESPACE pg_default;

CREATE TABLE IF NOT EXISTS operaciones.tb_partes_catalogo_apoyo (
    apoyo_id SERIAL NOT NULL PRIMARY KEY,
    apoyo_codigo text COLLATE pg_catalog."default" NOT NULL UNIQUE,
    apoyo_descripcion text COLLATE pg_catalog."default" NOT NULL,
    apoyo_estado text COLLATE pg_catalog."default" NOT NULL DEFAULT 'ACTIVO'::text
) WITH (OIDS = FALSE) TABLESPACE pg_default;

CREATE TABLE IF NOT EXISTS operaciones.tb_partes_catalogo_tipos_auxilio (
    tipo_auxilio_id SERIAL NOT NULL PRIMARY KEY,
    tipo_auxilio_clave text COLLATE pg_catalog."default" NOT NULL,
    tipo_auxilio_clasificacion text COLLATE pg_catalog."default" NOT NULL,
    tipo_auxilio_subclasificacion text COLLATE pg_catalog."default" NOT NULL,
    tipo_auxilio_uso_tipo text COLLATE pg_catalog."default" NOT NULL DEFAULT ''::text,
    tipo_auxilio_estado text COLLATE pg_catalog."default" NOT NULL DEFAULT 'ACTIVO'::text,
    CONSTRAINT tb_partes_catalogo_tipos_auxilio_uk UNIQUE (
        tipo_auxilio_clave,
        tipo_auxilio_clasificacion,
        tipo_auxilio_subclasificacion,
        tipo_auxilio_uso_tipo
    )
) WITH (OIDS = FALSE) TABLESPACE pg_default;

CREATE TABLE IF NOT EXISTS operaciones.tb_partes_tipos_incendio (
    parte_tipo_incendio_id SERIAL NOT NULL PRIMARY KEY,
    fk_parte_id integer NOT NULL REFERENCES operaciones.tb_partes(parte_id) ON DELETE CASCADE,
    fk_tipo_incendio_catalogo_id integer REFERENCES operaciones.tb_partes_catalogo_tipos_incendio(tipo_incendio_id),
    parte_incendio_clave text COLLATE pg_catalog."default",
    parte_incendio_clasificacion text COLLATE pg_catalog."default",
    parte_incendio_especifique text COLLATE pg_catalog."default"
) WITH (OIDS = FALSE) TABLESPACE pg_default;

CREATE TABLE IF NOT EXISTS operaciones.tb_partes_naturalezas (
    parte_naturaleza_id SERIAL NOT NULL PRIMARY KEY,
    fk_parte_id integer NOT NULL REFERENCES operaciones.tb_partes(parte_id) ON DELETE CASCADE,
    fk_naturaleza_catalogo_id integer REFERENCES operaciones.tb_partes_catalogo_naturalezas(naturaleza_id),
    parte_naturaleza_clave text COLLATE pg_catalog."default",
    parte_naturaleza_descripcion text COLLATE pg_catalog."default",
    parte_naturaleza_especifique text COLLATE pg_catalog."default"
) WITH (OIDS = FALSE) TABLESPACE pg_default;

-- Catalogos iniciales leidos de los formatos de partes.
INSERT INTO operaciones.tb_partes_catalogo_tipos_incendio (
    tipo_incendio_codigo,
    tipo_incendio_descripcion
) VALUES
    ('DECLARADO', 'Declarado'),
    ('INCENDIO', 'Incendio'),
    ('AMAGO', 'Amago'),
    ('FORESTAL', 'Forestal'),
    ('FUGA_GAS', 'Fuga de gas'),
    ('INSPECCION_SIRENA_BALIZA', 'Inspección con sirena - baliza'),
    ('INSPECCION_SIN_SIRENA_BALIZA', 'Inspección sin sirena - baliza'),
    ('FALSA_ALARMA', 'Falsa alarma'),
    ('SIMULACRO', 'Simulacro'),
    ('INCENDIO_APOYO', 'Incendio / apoyo')
ON CONFLICT (tipo_incendio_codigo) DO NOTHING;

INSERT INTO operaciones.tb_partes_catalogo_causas_incendio (
    causa_incendio_codigo,
    causa_incendio_descripcion
) VALUES
    ('DESCONOCIDA', 'Desconocida'),
    ('DERRAME_COMBUSTIBLE', 'Derrame de combustible'),
    ('ELECTRICA', 'Eléctrica'),
    ('ACCIDENTE_TRANSITO', 'Accidente de tránsito'),
    ('INTENCIONAL', 'Intencional'),
    ('EXPLOSION', 'Explosión'),
    ('RAYO', 'Rayo'),
    ('DESPRENDIMIENTO_CHISPAS', 'Desprendimiento de chispas'),
    ('IMPREVISION', 'Imprevisión'),
    ('FUGA_GAS', 'Fuga de gas'),
    ('MANIOBRAS_MILITARES', 'Maniobras militares'),
    ('PROPAGACION_INCENDIO', 'Propagación de incendio'),
    ('DESCUIDO', 'Descuido'),
    ('COMBUSTION_ESPONTANEA', 'Combustión espontánea'),
    ('QUEMA_AGRICOLA', 'Quema agrícola'),
    ('QUEMA_BASURA', 'Quema de basura'),
    ('INSTRUIR_CIUDADANIA', 'Instruir a la ciudadanía'),
    ('VEHICULAR', 'Vehicular')
ON CONFLICT (causa_incendio_codigo) DO NOTHING;

INSERT INTO operaciones.tb_partes_catalogo_naturalezas (
    naturaleza_codigo,
    naturaleza_descripcion
) VALUES
    ('VIVIENDA', 'Vivienda'),
    ('CLANDESTINO', 'Clandestino'),
    ('TERRENO_BALDIO', 'Terreno baldío'),
    ('PANADERIA', 'Panadería'),
    ('INDUSTRIA', 'Industria'),
    ('MECANICA', 'Mecánica'),
    ('BOSQUE_CAMPO', 'Bosque / campo'),
    ('IGLESIA', 'Iglesia'),
    ('COMERCIO', 'Comercio'),
    ('RESTAURANTE', 'Restaurante'),
    ('CENTRO_COMERCIAL', 'Centro comercial'),
    ('ASERRADERO', 'Aserradero'),
    ('VEHICULO', 'Vehículo'),
    ('ESTACION_SERVICIO', 'Estación de servicio'),
    ('EDIFICIO_OFICINAS', 'Edificio de oficinas'),
    ('OTROS', 'Otros')
ON CONFLICT (naturaleza_codigo) DO NOTHING;

INSERT INTO operaciones.tb_partes_catalogo_causas_afectacion_humana (
    causa_afectacion_humana_codigo,
    causa_afectacion_humana_descripcion
) VALUES
    ('ASFIXIA', 'Asfixia'),
    ('QUEMADURAS', 'Quemaduras'),
    ('CAIDA', 'Caída'),
    ('OTRAS', 'Otras')
ON CONFLICT (causa_afectacion_humana_codigo) DO NOTHING;

INSERT INTO operaciones.tb_partes_catalogo_tipo_afectado (
    tipo_afectado_codigo,
    tipo_afectado_descripcion
) VALUES
    ('PROPIO', 'Propio'),
    ('ARRENDADO', 'Arrendado')
ON CONFLICT (tipo_afectado_codigo) DO NOTHING;

INSERT INTO operaciones.tb_partes_catalogo_forma_aviso (
    forma_aviso_codigo,
    forma_aviso_descripcion
) VALUES
    ('CR', 'Central de radio'),
    ('CABINA_RADIO', 'Cabina de radio'),
    ('TELEFONO', 'Teléfono'),
    ('PERSONAL', 'Personal')
ON CONFLICT (forma_aviso_codigo) DO NOTHING;

INSERT INTO operaciones.tb_partes_catalogo_apoyo (
    apoyo_codigo,
    apoyo_descripcion
) VALUES
    ('POLICIA', 'Policía'),
    ('CRUZ_ROJA', 'Cruz Roja'),
    ('EJERCITO', 'Ejército'),
    ('PERSONAS_PARTICULARES', 'Personas particulares'),
    ('OTROS', 'Otros')
ON CONFLICT (apoyo_codigo) DO NOTHING;

INSERT INTO operaciones.tb_partes_catalogo_tipos_auxilio (
    tipo_auxilio_clave,
    tipo_auxilio_clasificacion,
    tipo_auxilio_subclasificacion,
    tipo_auxilio_uso_tipo
) VALUES
    ('10-1', 'Auxilio', 'Evacuación', 'Menaje + personas'),
    ('10-1', 'Auxilio', 'Tala de árboles', '')
ON CONFLICT (
    tipo_auxilio_clave,
    tipo_auxilio_clasificacion,
    tipo_auxilio_subclasificacion,
    tipo_auxilio_uso_tipo
) DO NOTHING;

-- TABLAS BOMBEROS VOLUNTARIOS

DROP TABLE IF EXISTS subjefatura.tb_voluntarios CASCADE;
CREATE TABLE IF NOT EXISTS subjefatura.tb_voluntarios (
    voluntario_id SERIAL NOT NULL PRIMARY KEY,
    voluntario_estado text COLLATE pg_catalog."default" DEFAULT 'ACTIVO' :: text,
    voluntario_tipo_doc text COLLATE pg_catalog."default" NOT NULL DEFAULT 'CEDULA' :: text,
    voluntario_doc_identidad text COLLATE pg_catalog."default" NOT NULL,
    voluntario_pass text COLLATE pg_catalog."default" NULL,
    voluntario_nombres text COLLATE pg_catalog."default" NOT NULL,
    voluntario_apellidos text COLLATE pg_catalog."default" NOT NULL,
    voluntario_sexo text COLLATE pg_catalog."default",
    voluntario_promocion text COLLATE pg_catalog."default",
    voluntario_imagen text COLLATE pg_catalog."default" DEFAULT 'default.png' :: text,
    voluntario_direccion text COLLATE pg_catalog."default",
    voluntario_telefono text COLLATE pg_catalog."default",
    voluntario_correo text COLLATE pg_catalog."default",
    voluntario_fingreso timestamp without time zone DEFAULT ('now' :: text) :: timestamp(0) with time zone,
    fk_usuario_id integer,
    voluntario_fnacimiento date,
    voluntario_nacionalidad text COLLATE pg_catalog."default" DEFAULT 'ECUATORIANA' :: text,
    voluntario_celular text COLLATE pg_catalog."default",
    voluntario_estadocivil text COLLATE pg_catalog."default",
    voluntario_tiposangre text COLLATE pg_catalog."default",
    fk_parroquia_id integer DEFAULT 230151,
    voluntario_principal text COLLATE pg_catalog."default",
    voluntario_secundaria text COLLATE pg_catalog."default",
    voluntario_no_casa text COLLATE pg_catalog."default",
    voluntario_referencia text COLLATE pg_catalog."default",
    voluntario_barrio_ciudadela text COLLATE pg_catalog."default",
    voluntario_barrio_sector text COLLATE pg_catalog."default",
    voluntario_titulo text COLLATE pg_catalog."default",
    voluntario_anexo_cedula text COLLATE pg_catalog."default" DEFAULT 'NO' :: text,
    voluntario_cemergencia_nombre text COLLATE pg_catalog."default",
    voluntario_cemergencia_parentesco text COLLATE pg_catalog."default",
    voluntario_cemergencia_direccion text COLLATE pg_catalog."default",
    voluntario_cemergencia_telefono text COLLATE pg_catalog."default",
    voluntario_discapacidad_tiene text COLLATE pg_catalog."default" DEFAULT 'NO' :: text,
    voluntario_discapacidad_tipo text COLLATE pg_catalog."default",
    voluntario_discapacidad_porcentaje text COLLATE pg_catalog."default",
    voluntario_discapacidad_conadis text COLLATE pg_catalog."default" DEFAULT 'NO' :: text,
    voluntario_discapacidad_conadis_numero text COLLATE pg_catalog."default",
    voluntario_enfermedad_cronica text COLLATE pg_catalog."default" DEFAULT 'NO' :: text,
    voluntario_enfermedad_cronica_describa text COLLATE pg_catalog."default"
) WITH (OIDS = FALSE) TABLESPACE pg_default;

-- TABLA PARA HISTORIAL
DROP TABLE IF EXISTS historial.tb_voluntarios CASCADE;
CREATE TABLE IF NOT EXISTS historial.tb_voluntarios (
    voluntario_id SERIAL REFERENCES subjefatura.tb_voluntarios (voluntario_id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    voluntario_estado text COLLATE pg_catalog."default" DEFAULT 'ACTIVO' :: text,
    voluntario_tipo_doc text COLLATE pg_catalog."default" NOT NULL DEFAULT 'CEDULA' :: text,
    voluntario_doc_identidad text COLLATE pg_catalog."default" NOT NULL,
    voluntario_pass text COLLATE pg_catalog."default" NOT NULL,
    voluntario_nombres text COLLATE pg_catalog."default" NOT NULL,
    voluntario_apellidos text COLLATE pg_catalog."default" NOT NULL,
    voluntario_sexo text COLLATE pg_catalog."default",
    voluntario_promocion text COLLATE pg_catalog."default" NOT NULL,
    voluntario_imagen text COLLATE pg_catalog."default" DEFAULT 'default.png' :: text,
    voluntario_direccion text COLLATE pg_catalog."default",
    voluntario_telefono text COLLATE pg_catalog."default",
    voluntario_correo text COLLATE pg_catalog."default",
    voluntario_fingreso timestamp without time zone DEFAULT ('now' :: text) :: timestamp(0) with time zone,
    fk_usuario_id integer,
    voluntario_fnacimiento date,
    voluntario_nacionalidad text COLLATE pg_catalog."default" DEFAULT 'ECUATORIANA' :: text,
    voluntario_celular text COLLATE pg_catalog."default",
    voluntario_estadocivil text COLLATE pg_catalog."default",
    voluntario_tiposangre text COLLATE pg_catalog."default",
    fk_parroquia_id integer DEFAULT 230151,
    voluntario_principal text COLLATE pg_catalog."default",
    voluntario_secundaria text COLLATE pg_catalog."default",
    voluntario_no_casa text COLLATE pg_catalog."default",
    voluntario_referencia text COLLATE pg_catalog."default",
    voluntario_barrio_ciudadela text COLLATE pg_catalog."default",
    voluntario_barrio_sector text COLLATE pg_catalog."default",
    voluntario_titulo text COLLATE pg_catalog."default",
    voluntario_anexo_cedula text COLLATE pg_catalog."default" DEFAULT 'NO' :: text,
    voluntario_cemergencia_nombre text COLLATE pg_catalog."default",
    voluntario_cemergencia_parentesco text COLLATE pg_catalog."default",
    voluntario_cemergencia_direccion text COLLATE pg_catalog."default",
    voluntario_cemergencia_telefono text COLLATE pg_catalog."default",
    voluntario_discapacidad_tiene text COLLATE pg_catalog."default" DEFAULT 'NO' :: text,
    voluntario_discapacidad_tipo text COLLATE pg_catalog."default",
    voluntario_discapacidad_porcentaje text COLLATE pg_catalog."default",
    voluntario_discapacidad_conadis text COLLATE pg_catalog."default" DEFAULT 'NO' :: text,
    voluntario_discapacidad_conadis_numero text COLLATE pg_catalog."default",
    voluntario_enfermedad_cronica text COLLATE pg_catalog."default" DEFAULT 'NO' :: text,
    voluntario_enfermedad_cronica_describa text COLLATE pg_catalog."default"
) WITH (OIDS = FALSE) TABLESPACE pg_default;

DROP TABLE IF EXISTS subjefatura.tb_voluntarios_eventos CASCADE;
CREATE TABLE IF NOT EXISTS subjefatura.tb_voluntarios_eventos (
    evento_id SERIAL NOT NULL PRIMARY KEY,
    evento_registro timestamp without time zone DEFAULT ('now'::text)::timestamp(0) with time zone,
    evento_estado text COLLATE pg_catalog."default" DEFAULT 'GENERADO'::text,
    evento_fecha_inicio date NOT NULL,
    evento_hora_inicio text COLLATE pg_catalog."default",
    evento_fecha_finalizacion date NOT NULL,
    evento_hora_finalizacion text COLLATE pg_catalog."default",
    evento_motivo text COLLATE pg_catalog."default" NOT NULL,
    evento_lugar text COLLATE pg_catalog."default" NOT NULL,
    evento_latitud text COLLATE pg_catalog."default",
    evento_longitud text COLLATE pg_catalog."default",
    evento_descripcion text COLLATE pg_catalog."default" NOT NULL
) WITH (OIDS = FALSE) TABLESPACE pg_default;

DROP TABLE IF EXISTS subjefatura.tb_voluntarios_eventos_participantes CASCADE;
CREATE TABLE IF NOT EXISTS subjefatura.tb_voluntarios_eventos_participantes (
    evento_participante_id SERIAL NOT NULL PRIMARY KEY,
    fk_evento_id integer NOT NULL REFERENCES subjefatura.tb_voluntarios_eventos (evento_id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    fk_voluntario_id integer NOT NULL REFERENCES subjefatura.tb_voluntarios (voluntario_id) ON DELETE RESTRICT ON UPDATE RESTRICT
) WITH (OIDS = FALSE) TABLESPACE pg_default;

DROP TABLE IF EXISTS subjefatura.tb_voluntarios_actividades CASCADE;
CREATE TABLE IF NOT EXISTS subjefatura.tb_voluntarios_actividades (
    actividad_id SERIAL NOT NULL PRIMARY KEY,
    actividad_registro timestamp without time zone DEFAULT ('now'::text)::timestamp(0) with time zone,
    actividad_estado text COLLATE pg_catalog."default" DEFAULT 'INICIADA'::text,
    fk_voluntario_id integer NOT NULL REFERENCES subjefatura.tb_voluntarios (voluntario_id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    actividad_actividad text COLLATE pg_catalog."default" NOT NULL,
    actividad_descripcion text COLLATE pg_catalog."default" NOT NULL,
    actividad_fecha_inicio timestamp without time zone NOT NULL,
    actividad_fecha_finalizacion timestamp without time zone,
    actividad_evidencia text COLLATE pg_catalog."default",
    fk_ppersonal_id integer
) WITH (OIDS = FALSE) TABLESPACE pg_default;

DROP TABLE IF EXISTS subjefatura.tb_voluntarios_asignacion CASCADE;
CREATE TABLE IF NOT EXISTS subjefatura.tb_voluntarios_asignacion (
    asignacion_id SERIAL NOT NULL PRIMARY KEY,
    asignacion_registro timestamp without time zone DEFAULT ('now'::text)::timestamp(0) with time zone,
    asignacion_estado text COLLATE pg_catalog."default" DEFAULT 'ACTIVO'::text,
    fk_voluntario_id integer NOT NULL REFERENCES subjefatura.tb_voluntarios (voluntario_id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    fk_estacion_id integer NOT NULL REFERENCES operaciones.tb_estaciones (estacion_id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    fk_unidad_id integer,
    asignacion_fecha_inicio date NOT NULL,
    asignacion_fecha_fin date
) WITH (OIDS = FALSE) TABLESPACE pg_default;

-- FIN TABLAS BOMBEROS VOLUNTARIOS


--REGISTROS INICIALES
INSERT INTO subjefatura.tb_aph_hojaruta_tipoemergencia(aph_hojaruta_tipoemergencia_descripcion) VALUES ('TRASLADO DE PACIENTE');
INSERT INTO subjefatura.tb_aph_hojaruta_tipoemergencia(aph_hojaruta_tipoemergencia_descripcion) VALUES ('ATROPELLAMIENTO');
INSERT INTO subjefatura.tb_aph_hojaruta_tipoemergencia(aph_hojaruta_tipoemergencia_descripcion) VALUES ('OBSTETRICA');

--TIPOS INCIDENCIA - NIVEL 1
INSERT INTO subjefatura.tb_tipoincidencia(incidencia_descripcion) VALUES ('INCENDIO');
INSERT INTO subjefatura.tb_tipoincidencia(incidencia_descripcion) VALUES ('AUXILIO');
INSERT INTO subjefatura.tb_tipoincidencia(incidencia_descripcion) VALUES ('ATENCION PRE HOSPITALARIA');

--TIPOS EMERGENCIAS - NIVEL 2 (INCENDIOS)
INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) VALUES (1,'Declarado');
INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) VALUES (1,'Incendio');
INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) VALUES (1,'Amago');
INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) VALUES (1,'Forestal');
INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) VALUES (1,'Fuga de gas');
INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) VALUES (1,'Simulacro');
INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) VALUES (1,'Inspección con Sirena – Baliza');
INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) VALUES (1,'Inspección sin Sirena – Baliza');
INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) VALUES (1,'Falsa Alarma');
INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) VALUES (1,'Incendio / apoyo ');
--TIPOS EMERGENCIAS - NIVEL 2 (AUXILIOS)
INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) VALUES (2,'Rescate');
INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) VALUES (2,'Inundación');
INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) VALUES (2,'Traslado de ambulancia');
INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) VALUES (2,'Deslizamiento de tierra');
INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) VALUES (2,'Simulacro en Rescate');
INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) VALUES (2,'Rescate / apoyo');
INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) VALUES (2,'Inundación (apoyo)');
INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) VALUES (2,'Traslado de paciente');
INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) VALUES (2,'Desfile');
INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) VALUES (2,'Simulacro en Evacuación');
INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) VALUES (2,'Salvamento');
INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) VALUES (2,'Accidente de transito');
INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) VALUES (2,'Soporte Vital');
INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) VALUES (2,'Abrir departamento');
INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) VALUES (2,'Reparto de agua');
INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) VALUES (2,'Capacitación');
INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) VALUES (2,'Baldeo');
INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) VALUES (2,'Evacuación');
INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) VALUES (2,'Accidente Aviatorio');
INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) VALUES (2,'Caída de arboles');
INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) VALUES (2,'Inspección con Sirena – Baliza');
INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) VALUES (2,'Inspección sin Sirena – Baliza');
INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) VALUES (2,'Apoyo');
INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) VALUES (2,'Auxilio General');
INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) VALUES (2,'Abrir departamento');
--TIPOS EMERGENCIAS - NIVEL 2 (APH)
INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) VALUES (3,'Traslado de paciente');
INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) VALUES (3,'Salvamento');
INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) VALUES (3,'Soporte Vital');
INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) VALUES (3,'Accidente Aviatorio');
INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) VALUES (3,'Inspección con Sirena – Baliza');
INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) VALUES (3,'Inspección sin Sirena – Baliza');
INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) VALUES (3,'Auxilio General');

--CAUSAS INCENDIOS
INSERT INTO subjefatura.tb_causas( fk_incidencia_id, causa_codigo, causa_descripcion)VALUES (1, '10.', 'Desconocida');
INSERT INTO subjefatura.tb_causas( fk_incidencia_id, causa_codigo, causa_descripcion)VALUES (1, '10.', 'Derrame de combustible');
INSERT INTO subjefatura.tb_causas( fk_incidencia_id, causa_codigo, causa_descripcion)VALUES (1, '10.', 'Eléctrica');
INSERT INTO subjefatura.tb_causas( fk_incidencia_id, causa_codigo, causa_descripcion)VALUES (1, '10.', 'Accidente de transito');
INSERT INTO subjefatura.tb_causas( fk_incidencia_id, causa_codigo, causa_descripcion)VALUES (1, '10.', 'Intencional');
INSERT INTO subjefatura.tb_causas( fk_incidencia_id, causa_codigo, causa_descripcion)VALUES (1, '10.', 'Explosión');
INSERT INTO subjefatura.tb_causas( fk_incidencia_id, causa_codigo, causa_descripcion)VALUES (1, '10.', 'Rayo');
INSERT INTO subjefatura.tb_causas( fk_incidencia_id, causa_codigo, causa_descripcion)VALUES (1, '10.', 'Desprendimiento de chispa');
INSERT INTO subjefatura.tb_causas( fk_incidencia_id, causa_codigo, causa_descripcion)VALUES (1, '10.', 'Imprevisión');
INSERT INTO subjefatura.tb_causas( fk_incidencia_id, causa_codigo, causa_descripcion)VALUES (1, '10.', 'Fuga de gas');
INSERT INTO subjefatura.tb_causas( fk_incidencia_id, causa_codigo, causa_descripcion)VALUES (1, '10.', 'Maniobras militares');
INSERT INTO subjefatura.tb_causas( fk_incidencia_id, causa_codigo, causa_descripcion)VALUES (1, '10.', 'Propagación de incendio');
INSERT INTO subjefatura.tb_causas( fk_incidencia_id, causa_codigo, causa_descripcion)VALUES (1, '10.', 'Descuido');
INSERT INTO subjefatura.tb_causas( fk_incidencia_id, causa_codigo, causa_descripcion)VALUES (1, '10.', 'Combustión espontanea');
INSERT INTO subjefatura.tb_causas( fk_incidencia_id, causa_codigo, causa_descripcion)VALUES (1, '10.', 'Quema agrícola');
INSERT INTO subjefatura.tb_causas( fk_incidencia_id, causa_codigo, causa_descripcion)VALUES (1, '10.', 'Quema de basura');
INSERT INTO subjefatura.tb_causas( fk_incidencia_id, causa_codigo, causa_descripcion)VALUES (1, '10.', 'Instruir a la ciudadanía');
INSERT INTO subjefatura.tb_causas( fk_incidencia_id, causa_codigo, causa_descripcion)VALUES (1, '10.', 'Vehicular');

--CAUSAS AUXILIOS
INSERT INTO subjefatura.tb_causas( fk_incidencia_id, causa_codigo, causa_descripcion)VALUES (2, '10.', 'Caída');
INSERT INTO subjefatura.tb_causas( fk_incidencia_id, causa_codigo, causa_descripcion)VALUES (2, '10.', 'Combustible derramado');
INSERT INTO subjefatura.tb_causas( fk_incidencia_id, causa_codigo, causa_descripcion)VALUES (2, '10.', 'Choque');
INSERT INTO subjefatura.tb_causas( fk_incidencia_id, causa_codigo, causa_descripcion)VALUES (2, '10.', 'Parto');
INSERT INTO subjefatura.tb_causas( fk_incidencia_id, causa_codigo, causa_descripcion)VALUES (2, '10.', 'Evaluación Primaria');
INSERT INTO subjefatura.tb_causas( fk_incidencia_id, causa_codigo, causa_descripcion)VALUES (2, '10.', 'Daño de tubería');
INSERT INTO subjefatura.tb_causas( fk_incidencia_id, causa_codigo, causa_descripcion)VALUES (2, '10.', 'Escasez de agua');
INSERT INTO subjefatura.tb_causas( fk_incidencia_id, causa_codigo, causa_descripcion)VALUES (2, '10.', 'Atropellamiento');
INSERT INTO subjefatura.tb_causas( fk_incidencia_id, causa_codigo, causa_descripcion)VALUES (2, '10.', 'Intoxicación');
INSERT INTO subjefatura.tb_causas( fk_incidencia_id, causa_codigo, causa_descripcion)VALUES (2, '10.', 'Apuñalamiento');
INSERT INTO subjefatura.tb_causas( fk_incidencia_id, causa_codigo, causa_descripcion)VALUES (2, '10.', 'Acumulación de agua');
INSERT INTO subjefatura.tb_causas( fk_incidencia_id, causa_codigo, causa_descripcion)VALUES (2, '10.', 'Caída a pozo de agua');
INSERT INTO subjefatura.tb_causas( fk_incidencia_id, causa_codigo, causa_descripcion)VALUES (2, '10.', 'Volcamiento');
INSERT INTO subjefatura.tb_causas( fk_incidencia_id, causa_codigo, causa_descripcion)VALUES (2, '10.', 'Quemaduras');
INSERT INTO subjefatura.tb_causas( fk_incidencia_id, causa_codigo, causa_descripcion)VALUES (2, '10.', 'Traslado de animales');
INSERT INTO subjefatura.tb_causas( fk_incidencia_id, causa_codigo, causa_descripcion)VALUES (2, '10.', 'Estado Etílico');
INSERT INTO subjefatura.tb_causas( fk_incidencia_id, causa_codigo, causa_descripcion)VALUES (2, '10.', 'Instruir a la ciudadanía');
INSERT INTO subjefatura.tb_causas( fk_incidencia_id, causa_codigo, causa_descripcion)VALUES (2, '10.', 'Traumatismo');
INSERT INTO subjefatura.tb_causas( fk_incidencia_id, causa_codigo, causa_descripcion)VALUES (2, '10.', 'Enfermedad');
INSERT INTO subjefatura.tb_causas( fk_incidencia_id, causa_codigo, causa_descripcion)VALUES (2, '10.', 'Olvido de llaves');
INSERT INTO subjefatura.tb_causas( fk_incidencia_id, causa_codigo, causa_descripcion)VALUES (2, '10.', 'Picadura de animales');
INSERT INTO subjefatura.tb_causas( fk_incidencia_id, causa_codigo, causa_descripcion)VALUES (2, '10.', 'Mordedura de animales');
INSERT INTO subjefatura.tb_causas( fk_incidencia_id, causa_codigo, causa_descripcion)VALUES (2, '10.', 'Material solido derramado');
INSERT INTO subjefatura.tb_causas( fk_incidencia_id, causa_codigo, causa_descripcion)VALUES (2, '10.', 'Acto Cívico');
INSERT INTO subjefatura.tb_causas( fk_incidencia_id, causa_codigo, causa_descripcion)VALUES (2, '10.', 'Otro');

--CAUSAS APH
INSERT INTO subjefatura.tb_causas( fk_incidencia_id, causa_codigo, causa_descripcion)VALUES (3, '10.', 'ATROPELLAMIENTO');
INSERT INTO subjefatura.tb_causas( fk_incidencia_id, causa_codigo, causa_descripcion)VALUES (3, '10.', 'TRAUMATISMO');
INSERT INTO subjefatura.tb_causas( fk_incidencia_id, causa_codigo, causa_descripcion)VALUES (3, '10.', 'QUEMADURAS');
INSERT INTO subjefatura.tb_causas( fk_incidencia_id, causa_codigo, causa_descripcion)VALUES (3, '10.', 'INTOXICACIÓN');
INSERT INTO subjefatura.tb_causas( fk_incidencia_id, causa_codigo, causa_descripcion)VALUES (3, '10.', 'PARTO');
INSERT INTO subjefatura.tb_causas( fk_incidencia_id, causa_codigo, causa_descripcion)VALUES (3, '10.', 'APUÑALAMIENTO');
INSERT INTO subjefatura.tb_causas( fk_incidencia_id, causa_codigo, causa_descripcion)VALUES (3, '10.', 'EVALUACIÓN PRIMARIA');

--NATURALEZA INCENDIO
INSERT INTO subjefatura.tb_naturaleza(fk_incidencia_id,naturaleza_descripcion)VALUES (1,'Vivienda');
INSERT INTO subjefatura.tb_naturaleza(fk_incidencia_id,naturaleza_descripcion)VALUES (1,'Clandestino');
INSERT INTO subjefatura.tb_naturaleza(fk_incidencia_id,naturaleza_descripcion)VALUES (1,'Terreno baldío');
INSERT INTO subjefatura.tb_naturaleza(fk_incidencia_id,naturaleza_descripcion)VALUES (1,'Panadería');
INSERT INTO subjefatura.tb_naturaleza(fk_incidencia_id,naturaleza_descripcion)VALUES (1,'Industria');
INSERT INTO subjefatura.tb_naturaleza(fk_incidencia_id,naturaleza_descripcion)VALUES (1,'Mecánica');
INSERT INTO subjefatura.tb_naturaleza(fk_incidencia_id,naturaleza_descripcion)VALUES (1,'Bosque / Campo');
INSERT INTO subjefatura.tb_naturaleza(fk_incidencia_id,naturaleza_descripcion)VALUES (1,'Iglesia');
INSERT INTO subjefatura.tb_naturaleza(fk_incidencia_id,naturaleza_descripcion)VALUES (1,'Comercio');
INSERT INTO subjefatura.tb_naturaleza(fk_incidencia_id,naturaleza_descripcion)VALUES (1,'Restaurante');
INSERT INTO subjefatura.tb_naturaleza(fk_incidencia_id,naturaleza_descripcion)VALUES (1,'Centro Comercial');
INSERT INTO subjefatura.tb_naturaleza(fk_incidencia_id,naturaleza_descripcion)VALUES (1,'Aserradero');
INSERT INTO subjefatura.tb_naturaleza(fk_incidencia_id,naturaleza_descripcion)VALUES (1,'Vehículo');
INSERT INTO subjefatura.tb_naturaleza(fk_incidencia_id,naturaleza_descripcion)VALUES (1,'Est. De Servicio');
INSERT INTO subjefatura.tb_naturaleza(fk_incidencia_id,naturaleza_descripcion)VALUES (1,'Edificio oficinas');
INSERT INTO subjefatura.tb_naturaleza(fk_incidencia_id,naturaleza_descripcion)VALUES (1,'Otros');

--NATURALEZA AUXILIO
INSERT INTO subjefatura.tb_naturaleza(fk_incidencia_id,naturaleza_descripcion)VALUES (2,'Vivienda');
INSERT INTO subjefatura.tb_naturaleza(fk_incidencia_id,naturaleza_descripcion)VALUES (2,'Vía pública');
INSERT INTO subjefatura.tb_naturaleza(fk_incidencia_id,naturaleza_descripcion)VALUES (2,'Casa de Salud');
INSERT INTO subjefatura.tb_naturaleza(fk_incidencia_id,naturaleza_descripcion)VALUES (2,'Escenario deportivo');
INSERT INTO subjefatura.tb_naturaleza(fk_incidencia_id,naturaleza_descripcion)VALUES (2,'Concentración  pública');
INSERT INTO subjefatura.tb_naturaleza(fk_incidencia_id,naturaleza_descripcion)VALUES (2,'Institución');
INSERT INTO subjefatura.tb_naturaleza(fk_incidencia_id,naturaleza_descripcion)VALUES (2,'Pozo de agua');
INSERT INTO subjefatura.tb_naturaleza(fk_incidencia_id,naturaleza_descripcion)VALUES (2,'Campo y bosque');
INSERT INTO subjefatura.tb_naturaleza(fk_incidencia_id,naturaleza_descripcion)VALUES (2,'Carretera');
INSERT INTO subjefatura.tb_naturaleza(fk_incidencia_id,naturaleza_descripcion)VALUES (2,'Otro');

--NATURALEZA APH
INSERT INTO subjefatura.tb_naturaleza(fk_incidencia_id,naturaleza_descripcion)VALUES (3,'Vivienda');
INSERT INTO subjefatura.tb_naturaleza(fk_incidencia_id,naturaleza_descripcion)VALUES (3,'Vía pública');
INSERT INTO subjefatura.tb_naturaleza(fk_incidencia_id,naturaleza_descripcion)VALUES (3,'Casa de Salud');
INSERT INTO subjefatura.tb_naturaleza(fk_incidencia_id,naturaleza_descripcion)VALUES (3,'Escenario deportivo');
INSERT INTO subjefatura.tb_naturaleza(fk_incidencia_id,naturaleza_descripcion)VALUES (3,'Concentración  pública');
INSERT INTO subjefatura.tb_naturaleza(fk_incidencia_id,naturaleza_descripcion)VALUES (3,'Institución');
INSERT INTO subjefatura.tb_naturaleza(fk_incidencia_id,naturaleza_descripcion)VALUES (3,'Pozo de agua');
INSERT INTO subjefatura.tb_naturaleza(fk_incidencia_id,naturaleza_descripcion)VALUES (3,'Campo y bosque');
INSERT INTO subjefatura.tb_naturaleza(fk_incidencia_id,naturaleza_descripcion)VALUES (3,'Carretera');
INSERT INTO subjefatura.tb_naturaleza(fk_incidencia_id,naturaleza_descripcion)VALUES (3,'Otro');
