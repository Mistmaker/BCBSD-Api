-- =============================================================================
-- ESTRUCTURA BASE (antes script.sql, script-2.sql y script_sbj_temp.sql) - re-ejecutable, NO borra datos
-- Tablas en orden de dependencias con su definición final. En bases existentes solo se agregan las columnas que
-- falten. Generado una vez desde los scripts anteriores; desde ahora se mantiene en este archivo.
-- =============================================================================

-- Esquemas y extensiones
CREATE SCHEMA IF NOT EXISTS admin AUTHORIZATION postgres;
CREATE SCHEMA IF NOT EXISTS administrativo AUTHORIZATION postgres;
CREATE SCHEMA IF NOT EXISTS resources AUTHORIZATION postgres;
CREATE SCHEMA IF NOT EXISTS operaciones AUTHORIZATION postgres;
CREATE SCHEMA IF NOT EXISTS tthh AUTHORIZATION postgres;
CREATE SCHEMA IF NOT EXISTS logistica AUTHORIZATION postgres;
CREATE SCHEMA IF NOT EXISTS archivo AUTHORIZATION postgres;
CREATE SCHEMA IF NOT EXISTS historial AUTHORIZATION postgres;
CREATE SCHEMA IF NOT EXISTS subjefatura AUTHORIZATION postgres;
CREATE EXTENSION IF NOT EXISTS dblink;

CREATE TABLE IF NOT EXISTS resources.tb_personas (
    persona_id SERIAL NOT NULL PRIMARY KEY,
    persona_tipo_doc text COLLATE pg_catalog."default" NOT NULL DEFAULT 'CEDULA' :: text,
    persona_doc_identidad text COLLATE pg_catalog."default" NOT NULL,
    persona_nombres text COLLATE pg_catalog."default" NOT NULL,
    persona_apellidos text COLLATE pg_catalog."default" NOT NULL,
    persona_sexo text COLLATE pg_catalog."default",
    persona_imagen text COLLATE pg_catalog."default" DEFAULT 'default.png' :: text,
    persona_direccion text COLLATE pg_catalog."default",
    persona_telefono text COLLATE pg_catalog."default",
    persona_correo text COLLATE pg_catalog."default",
    persona_fingreso timestamp without time zone DEFAULT ('now' :: text) :: timestamp(0) with time zone,
    fk_usuario_id integer,
    persona_fnacimiento date,
    persona_nacionalidad text COLLATE pg_catalog."default" DEFAULT 'ECUATORIANA' :: text,
    persona_celular text COLLATE pg_catalog."default",
    persona_estadocivil text COLLATE pg_catalog."default",
    persona_tiposangre text COLLATE pg_catalog."default",
    fk_parroquia_id integer DEFAULT 230151,
    persona_estatura text COLLATE pg_catalog."default",
    persona_peso text COLLATE pg_catalog."default",
    persona_acerca text COLLATE pg_catalog."default",
    persona_destrezas text COLLATE pg_catalog."default",
    persona_alergias text COLLATE pg_catalog."default",
    persona_discapacidad text COLLATE pg_catalog."default",
    persona_lugarnacimiento text COLLATE pg_catalog."default",
    persona_etnia text COLLATE pg_catalog."default",
    persona_senialesparticulares text COLLATE pg_catalog."default",
    fk_conyugeue_id integer,
    persona_principal text COLLATE pg_catalog."default",
    persona_secundaria text COLLATE pg_catalog."default",
    persona_no_casa text COLLATE pg_catalog."default",
    persona_referencia text COLLATE pg_catalog."default",
    persona_barrio_ciudadela text COLLATE pg_catalog."default",
    persona_barrio_sector text COLLATE pg_catalog."default",
    persona_titulo text COLLATE pg_catalog."default",
    persona_anexo_cedula text COLLATE pg_catalog."default" DEFAULT 'NO' :: text,
    persona_anexo_votacion text COLLATE pg_catalog."default" DEFAULT 'NO' :: text,
    persona_cemergencia_nombre text COLLATE pg_catalog."default",
    persona_cemergencia_parentesco text COLLATE pg_catalog."default",
    persona_cemergencia_direccion text COLLATE pg_catalog."default",
    persona_cemergencia_telefono text COLLATE pg_catalog."default",
    persona_discapacidad_tiene text COLLATE pg_catalog."default" DEFAULT 'NO' :: text,
    persona_discapacidad_tipo text COLLATE pg_catalog."default",
    persona_discapacidad_porcentaje text COLLATE pg_catalog."default",
    persona_discapacidad_conadis text COLLATE pg_catalog."default" DEFAULT 'NO' :: text,
    persona_discapacidad_conadis_numero text COLLATE pg_catalog."default",
    persona_enfermedad_cronica text COLLATE pg_catalog."default" DEFAULT 'NO' :: text,
    persona_enfermedad_cronica_describa text COLLATE pg_catalog."default"
);

CREATE TABLE IF NOT EXISTS resources.tb_licenciasdeconducir (
    licencia_id SERIAL NOT NULL PRIMARY KEY,
    licencia_estado text COLLATE pg_catalog."default" DEFAULT 'ACTIVO'::text,
    licencia_registro timestamp without time zone DEFAULT ('now'::text)::timestamp(0) with time zone,
    fk_usuario_id integer,
    licencia_tipo text COLLATE pg_catalog."default",
    licencia_categoria text COLLATE pg_catalog."default",
    licencia_descripcion text COLLATE pg_catalog."default"
);

CREATE TABLE IF NOT EXISTS admin.tb_perfiles (
    perfil_id SERIAL NOT NULL PRIMARY KEY,
    perfil_nombre text COLLATE pg_catalog."default" NOT NULL,
    perfil_descripcion text COLLATE pg_catalog."default",
    perfil_estado text COLLATE pg_catalog."default" DEFAULT 'ACTIVO' :: text
);

CREATE TABLE IF NOT EXISTS admin.tb_usuarios (
    usuario_id SERIAL NOT NULL PRIMARY KEY,
    fk_persona_id integer NOT NULL,
    fk_perfil_id integer NOT NULL REFERENCES admin.tb_perfiles(perfil_id),
    usuario_login text COLLATE pg_catalog."default" NOT NULL,
    usuario_pass text COLLATE pg_catalog."default" NOT NULL,
    usuario_estado text COLLATE pg_catalog."default" DEFAULT 'ACTIVO' :: text,
    usuario_acceso_correcto boolean DEFAULT false,
    usuario_acceso_fallido boolean DEFAULT false,
    usuario_cambio_perfil boolean DEFAULT false,
    fk_usuario_id integer,
    usuario_cambiar_pass boolean DEFAULT true,
    usuario_idioma text COLLATE pg_catalog."default" DEFAULT 'es' :: text,
    usuario_webmail_user text COLLATE pg_catalog."default",
    usuario_webmail_pass text COLLATE pg_catalog."default",
    usuario_registro timestamp without time zone DEFAULT ('now' :: text) :: timestamp(0) with time zone,
    usuario_fingreso timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0),
    usuario_tipo text COLLATE pg_catalog."default" DEFAULT 'USUARIO' :: text
);
ALTER TABLE admin.tb_usuarios ADD COLUMN IF NOT EXISTS usuario_tipo text COLLATE pg_catalog."default" DEFAULT 'USUARIO' :: text;

CREATE TABLE IF NOT EXISTS administrativo.tb_vehiculos_marcas (
    marca_id SERIAL NOT NULL PRIMARY KEY,
    marca_nombre text COLLATE pg_catalog."default" NOT NULL,
    marca_estado text COLLATE pg_catalog."default" DEFAULT 'ACTIVO' :: text
);

CREATE TABLE IF NOT EXISTS tthh.tb_jornadas_trabajo (
    jornada_id SERIAL NOT NULL PRIMARY KEY,
    jornada_registro timestamp without time zone DEFAULT ('now'::text)::timestamp(0) with time zone,
    jornada_estado text COLLATE pg_catalog."default" DEFAULT 'ACTIVO'::text,
    fk_usuario_id integer,
    jornada_nombre text COLLATE pg_catalog."default" NOT NULL,
    jornada_rancho numeric(10,2) DEFAULT 0,
    jornada_diasminimo integer DEFAULT 0,
    jornada_diasmaximo integer DEFAULT 0,
    jornada_dias_semana text COLLATE pg_catalog."default",
    jornada_horas_dia integer NOT NULL DEFAULT 8,
    jornada_entrada text COLLATE pg_catalog."default",
    jornada_salida text COLLATE pg_catalog."default",
    jornada_break text COLLATE pg_catalog."default" DEFAULT 'NO'::text,
    jornada_entrada_break text COLLATE pg_catalog."default",
    jornada_salida_break text COLLATE pg_catalog."default"
);

CREATE TABLE IF NOT EXISTS operaciones.tb_estaciones (
    estacion_id SERIAL NOT NULL PRIMARY KEY,
    fk_jornada_id integer REFERENCES tthh.tb_jornadas_trabajo(jornada_id),
    estacion_nombre text COLLATE pg_catalog."default" NOT NULL,
    estacion_tipo text COLLATE pg_catalog."default" DEFAULT 'ESTACION' NOT NULL,
    estacion_subtipo text COLLATE pg_catalog."default" DEFAULT 'URBANA' NOT NULL,
    estacion_jornada text COLLATE pg_catalog."default" DEFAULT '24 HORAS' NOT NULL,
    estacion_ubicacion text COLLATE pg_catalog."default",
    estacion_ubicacion_x text COLLATE pg_catalog."default",
    estacion_ubicacion_y text COLLATE pg_catalog."default",
    estacion_estado text COLLATE pg_catalog."default" DEFAULT 'ACTIVO' :: text
);
ALTER TABLE operaciones.tb_estaciones ADD COLUMN IF NOT EXISTS fk_jornada_id integer REFERENCES tthh.tb_jornadas_trabajo(jornada_id);
ALTER TABLE operaciones.tb_estaciones ADD COLUMN IF NOT EXISTS estacion_tipo text COLLATE pg_catalog."default" DEFAULT 'ESTACION' NOT NULL;
ALTER TABLE operaciones.tb_estaciones ADD COLUMN IF NOT EXISTS estacion_subtipo text COLLATE pg_catalog."default" DEFAULT 'URBANA' NOT NULL;
ALTER TABLE operaciones.tb_estaciones ADD COLUMN IF NOT EXISTS estacion_jornada text COLLATE pg_catalog."default" DEFAULT '24 HORAS' NOT NULL;
ALTER TABLE operaciones.tb_estaciones ADD COLUMN IF NOT EXISTS estacion_ubicacion text COLLATE pg_catalog."default";

CREATE TABLE IF NOT EXISTS tthh.tb_direcciones (
    direccion_id SERIAL NOT NULL PRIMARY KEY,
    direccion_registro timestamp without time zone DEFAULT ('now' :: text) :: timestamp(0) with time zone,
    direccion_estado text COLLATE pg_catalog."default" DEFAULT 'ACTIVO' :: text,
    fk_usuario_id integer,
    direccion_codigo text COLLATE pg_catalog."default" NOT NULL,
    direccion_nombre text COLLATE pg_catalog."default" NOT NULL,
    direccion_competencias text COLLATE pg_catalog."default",
    direccion_fecha_creacion date,
    direccion_baselegal text COLLATE pg_catalog."default",
    direccion_tipo text COLLATE pg_catalog."default" DEFAULT 'DIRECCION' :: text
);

CREATE TABLE IF NOT EXISTS administrativo.tb_vehiculos (
    vehiculo_id SERIAL NOT NULL PRIMARY KEY,
    fk_usuario_id integer REFERENCES admin.tb_usuarios(usuario_id) NOT NULL,
    fk_estacion_id integer REFERENCES operaciones.tb_estaciones(estacion_id) DEFAULT NULL,
    fk_direccion_id integer REFERENCES tthh.tb_direcciones(direccion_id) DEFAULT NULL,
    fk_marca_id integer REFERENCES administrativo.tb_vehiculos_marcas(marca_id) NOT NULL,
    vehiculo_registro timestamp without time zone DEFAULT ('now' :: text) :: timestamp(0) with time zone,
    vehiculo_estado text COLLATE pg_catalog."default" DEFAULT 'ACTIVO' :: text,
    vehiculo_direccion text COLLATE pg_catalog."default",
    vehiculo_placa text COLLATE pg_catalog."default" NOT NULL UNIQUE,
    vehiculo_toneladas numeric(4, 2),
    vehiculo_tipo text COLLATE pg_catalog."default" NOT NULL,
    vehiculo_color1 text COLLATE pg_catalog."default",
    vehiculo_marca text COLLATE pg_catalog."default",
    vehiculo_fingreso timestamp without time zone DEFAULT ('now' :: text) :: timestamp(0) with time zone,
    custodio_id integer,
    vehiculo_modelo text COLLATE pg_catalog."default",
    vehiculo_chasis text COLLATE pg_catalog."default",
    vehiculo_motor text COLLATE pg_catalog."default",
    vehiculo_combustible text COLLATE pg_catalog."default" NOT NULL,
    vehiculo_avaluo numeric(10, 2),
    vehiculo_anio integer,
    vehiculo_pais text COLLATE pg_catalog."default",
    vehiculo_corroceria text COLLATE pg_catalog."default",
    vehiculo_pasajeros integer,
    vehiculo_cilindraje numeric(6, 2),
    vehiculo_color2 text COLLATE pg_catalog."default",
    vehiculo_proposito text COLLATE pg_catalog."default" DEFAULT 'PARTICULAR' :: text,
    vehiculo_anio_matricula integer,
    vehiculo_ramv text COLLATE pg_catalog."default",
    vehiculo_sigla text COLLATE pg_catalog."default",
    vehiculo_area text COLLATE pg_catalog."default"
);
ALTER TABLE administrativo.tb_vehiculos ADD COLUMN IF NOT EXISTS fk_direccion_id integer REFERENCES tthh.tb_direcciones(direccion_id) DEFAULT NULL;
ALTER TABLE administrativo.tb_vehiculos ADD COLUMN IF NOT EXISTS vehiculo_area text COLLATE pg_catalog."default";

CREATE TABLE IF NOT EXISTS tthh.tb_personal (
    personal_id SERIAL NOT NULL PRIMARY KEY,
    personal_registro timestamp without time zone DEFAULT ('now' :: text) :: timestamp(0) with time zone,
    personal_estado text COLLATE pg_catalog."default" DEFAULT 'EN FUNCIONES' :: text,
    fk_usuario_id integer,
    fk_persona_id integer NOT NULL,
    fk_estacion_id integer,
    personal_contrasenia text COLLATE pg_catalog."default",
    personal_cambiar_pass text COLLATE pg_catalog."default" DEFAULT 'SI' :: text,
    personal_notificar_acceso_exitoso boolean DEFAULT false,
    personal_notificar_acceso_fallido boolean DEFAULT false,
    personal_notificar_cambios_perfil boolean DEFAULT false,
    personal_notificar_permisos boolean DEFAULT false,
    personal_notificar_eventos boolean DEFAULT false,
    personal_correo_institucional text COLLATE pg_catalog."default",
    biometrico_id integer NOT NULL DEFAULT 0,
    fk_jornada_id integer
);

CREATE TABLE IF NOT EXISTS tthh.tb_grupos (
    grupo_id SERIAL NOT NULL PRIMARY KEY,
    grupo_registro timestamp without time zone DEFAULT ('now' :: text) :: timestamp(0) with time zone,
    grupo_estado text COLLATE pg_catalog."default" DEFAULT 'ACTIVO' :: text,
    fk_usuario_id integer,
    grupo_nombre text COLLATE pg_catalog."default" NOT NULL,
    grupo_grado text COLLATE pg_catalog."default" NOT NULL,
    grupo_salario_sri numeric(8, 2) NOT NULL,
    grupo_salario_interno numeric(8, 2) DEFAULT 0
);

CREATE TABLE IF NOT EXISTS tthh.tb_puestos (
    puesto_id SERIAL NOT NULL PRIMARY KEY,
    puesto_registro timestamp without time zone DEFAULT ('now' :: text) :: timestamp(0) with time zone,
    puesto_estado text COLLATE pg_catalog."default" DEFAULT 'ACTIVO' :: text,
    fk_usuario_id integer,
    puesto_departamento text COLLATE pg_catalog."default" DEFAULT 'PRIMERA JEFATURA' :: text,
    puesto_nombre text COLLATE pg_catalog."default" NOT NULL,
    fk_direccion_id integer,
    puesto_remuneracion numeric(10, 2) DEFAULT 0,
    puesto_direccion text COLLATE pg_catalog."default" DEFAULT 'NO' :: text,
    puesto_grado integer DEFAULT 3,
    puesto_modalidad text COLLATE pg_catalog."default" DEFAULT 'ADMINISTRATIVO' :: text,
    puesto_fecha_creacion date,
    puesto_baselegal text COLLATE pg_catalog."default",
    puesto_partida text COLLATE pg_catalog."default",
    fk_grupo_id integer
);

CREATE TABLE IF NOT EXISTS tthh.tb_personal_puestos (
    ppersonal_id SERIAL NOT NULL PRIMARY KEY,
    ppersonal_registro timestamp without time zone DEFAULT ('now' :: text) :: timestamp(0) with time zone,
    ppersonal_estado text COLLATE pg_catalog."default" DEFAULT 'EN FUNCIONES' :: text,
    fk_usuario_id integer,
    fk_personal_id integer NOT NULL,
    fk_puesto_id integer NOT NULL,
    personal_definicion text COLLATE pg_catalog."default" DEFAULT 'TITULAR' :: text,
    personal_contrato text COLLATE pg_catalog."default" DEFAULT 'CONTRATO OCASIONAL' :: text,
    personal_fecha_ingreso date,
    personal_fecha_salida date,
    personal_fecha_registro date,
    personal_motivo_salida text COLLATE pg_catalog."default",
    personal_observacion text COLLATE pg_catalog."default",
    personal_baselegal text COLLATE pg_catalog."default",
    personal_regimen_laboral text COLLATE pg_catalog."default" DEFAULT 'LOSEP' :: text
);

CREATE TABLE IF NOT EXISTS tthh.tb_conductores (
    conductor_id SERIAL NOT NULL PRIMARY KEY,
    conductor_registro timestamp without time zone DEFAULT ('now'::text)::timestamp(0) with time zone,
    conductor_estado text COLLATE pg_catalog."default" DEFAULT 'ACTIVO'::text,
    fk_usuario_id integer,
    fk_personal_id integer NOT NULL,
    fk_licencia_id integer NOT NULL,
    conductor_licencia_emision date NOT NULL,
    conductor_licencia_validez date NOT NULL,
    conductor_pdf text COLLATE pg_catalog."default"
);

CREATE TABLE IF NOT EXISTS operaciones.tb_distributivo (
    distributivo_id SERIAL NOT NULL PRIMARY KEY,
    distributivo_registro timestamp without time zone DEFAULT ('now'::text)::timestamp(0) with time zone,
    distributivo_estado text COLLATE pg_catalog."default" DEFAULT 'ACTIVO'::text,
    fk_usuario_id integer,
    distributivo_codigo text COLLATE pg_catalog."default",
    distributivo_periodo_inicio date NOT NULL,
    distributivo_periodo_cierre date,
    distributivo_jornadas integer DEFAULT 24,
    distributivo_ingreso_guardia text COLLATE pg_catalog."default" DEFAULT '08:00'::text,
    distributivo_salida_guardia text COLLATE pg_catalog."default" DEFAULT '08:00'::text
);

CREATE TABLE IF NOT EXISTS operaciones.tb_pelotones (
    peloton_id SERIAL NOT NULL PRIMARY KEY,
    peloton_registro timestamp without time zone DEFAULT ('now'::text)::timestamp(0) with time zone,
    peloton_estado text COLLATE pg_catalog."default" DEFAULT 'ACTIVO'::text,
    fk_usuario_id integer,
    fk_estacion_id integer NOT NULL,
    peloton_nombre text COLLATE pg_catalog."default"
);

CREATE TABLE IF NOT EXISTS operaciones.tb_distributivo_peloton (
    dist_pelo_id SERIAL NOT NULL PRIMARY KEY,
    fk_peloton_id integer NOT NULL,
    fk_distributivo_id integer NOT NULL
);

CREATE TABLE IF NOT EXISTS operaciones.tb_tropas (
    tropa_id SERIAL NOT NULL PRIMARY KEY,
    tropa_registro timestamp without time zone DEFAULT ('now'::text)::timestamp(0) with time zone,
    tropa_estado text COLLATE pg_catalog."default" DEFAULT 'ACTIVO'::text,
    fk_usuario_id integer,
    fk_dist_pelo_id integer NOT NULL,
    fk_personal_id integer NOT NULL,
    tropa_cargo text COLLATE pg_catalog."default",
    tropa_cargo_otro text COLLATE pg_catalog."default",
    tropa_detalle text COLLATE pg_catalog."default"
);

CREATE TABLE IF NOT EXISTS logistica.tb_ordenesmovilizacion (
    orden_id SERIAL NOT NULL PRIMARY KEY,
    orden_registro timestamp without time zone DEFAULT ('now'::text)::timestamp(0) with time zone,
    orden_estado text COLLATE pg_catalog."default" DEFAULT 'SALIDA'::text,
    fk_usuario_id integer NOT NULL,
    fk_unidad_id integer NOT NULL,
    operador_id integer NOT NULL,
    director_administrativo integer NOT NULL,
    tecnico_servicios integer,
    orden_codigo text COLLATE pg_catalog."default" NOT NULL,
    orden_codigo_serie integer NOT NULL,
    orden_serie integer NOT NULL DEFAULT 0,
    orden_destino text COLLATE pg_catalog."default" NOT NULL,
    orden_motivo_salida text COLLATE pg_catalog."default" NOT NULL,
    personal_solicita integer NOT NULL,
    orden_hora_salida_tipo text COLLATE pg_catalog."default" DEFAULT 'SISTEMA'::text,
    orden_hora_salida timestamp without time zone NOT NULL,
    orden_kilometraje_salida numeric(10,2) NOT NULL,
    orden_hora_entrada_tipo text COLLATE pg_catalog."default" DEFAULT 'SISTEMA'::text,
    orden_hora_entrada timestamp without time zone,
    orden_kilometraje_entrada numeric(10,2),
    orden_observaciones text COLLATE pg_catalog."default"
);
ALTER TABLE logistica.tb_ordenesmovilizacion ADD COLUMN IF NOT EXISTS orden_codigo_serie integer;

CREATE TABLE IF NOT EXISTS resources.countries (
    country_id SERIAL NOT NULL PRIMARY KEY,
    country_sortname character varying(3) COLLATE pg_catalog."default" NOT NULL,
    country_name text COLLATE pg_catalog."default" NOT NULL,
    country_nombre text COLLATE pg_catalog."default",
    country_gentilicio text COLLATE pg_catalog."default",
    country_iso3 text COLLATE pg_catalog."default"
);

CREATE TABLE IF NOT EXISTS resources.states (
    state_id SERIAL NOT NULL PRIMARY KEY,
    state_name text COLLATE pg_catalog."default" NOT NULL,
    fk_country_id integer NOT NULL REFERENCES resources.countries(country_id)
);

CREATE TABLE IF NOT EXISTS resources.towns (
    town_id SERIAL NOT NULL PRIMARY KEY,
    town_name text COLLATE pg_catalog."default" NOT NULL,
    fk_state_id integer NOT NULL REFERENCES resources.states(state_id)
);

CREATE TABLE IF NOT EXISTS resources.parishes (
    parish_id SERIAL NOT NULL PRIMARY KEY,
    parish_name text COLLATE pg_catalog."default" NOT NULL,
    fk_town_id integer NOT NULL REFERENCES resources.towns(town_id)
);

CREATE TABLE IF NOT EXISTS resources.cie (
    cie_id SERIAL NOT NULL PRIMARY KEY,
    cie_codigo text COLLATE pg_catalog."default",
    cie_simbolo text COLLATE pg_catalog."default",
    cie_descripcion text COLLATE pg_catalog."default",
    cie_sexo text COLLATE pg_catalog."default",
    cie_limite_inferior text COLLATE pg_catalog."default",
    cie_limite_superior text COLLATE pg_catalog."default",
    cie_no_afeccion text COLLATE pg_catalog."default",
    cie_observacion text COLLATE pg_catalog."default"
);

CREATE TABLE IF NOT EXISTS admin.tb_modulos (
    modulo_id SERIAL NOT NULL PRIMARY KEY,
    modulo_nombre text COLLATE pg_catalog."default" NOT NULL,
    modulo_descripcion text COLLATE pg_catalog."default"
);

CREATE TABLE IF NOT EXISTS admin.tb_submodulos (
    submodulo_id SERIAL NOT NULL PRIMARY KEY,
    fk_modulo_id integer NOT NULL REFERENCES admin.tb_modulos(modulo_id),
    submodulo_nombre text COLLATE pg_catalog."default" NOT NULL,
    submodulo_descripcion text COLLATE pg_catalog."default"
);

CREATE TABLE IF NOT EXISTS admin.tb_roles (
    rol_id SERIAL NOT NULL PRIMARY KEY,
    rol_nombre text COLLATE pg_catalog."default" NOT NULL,
    rol_descripcion text COLLATE pg_catalog."default",
    fk_submodulo_id integer NOT NULL REFERENCES admin.tb_submodulos(submodulo_id),
    rol_path text COLLATE pg_catalog."default"
);

CREATE TABLE IF NOT EXISTS admin.tb_usuario_rol (
    fk_usuario_id integer NOT NULL,
    fk_rol_id integer NOT NULL
);

CREATE TABLE IF NOT EXISTS operaciones.tb_parte_clasificacion (
    parte_clasificacion_id SERIAL NOT NULL PRIMARY KEY,
    parte_clasificacion_codigo text COLLATE pg_catalog."default" NOT NULL,
    parte_clasificacion_descripcion text COLLATE pg_catalog."default" NOT NULL
);

CREATE TABLE IF NOT EXISTS operaciones.tb_parte_subclasificacion (
    parte_subclasificacion_id SERIAL NOT NULL PRIMARY KEY,
    fk_parte_clasificacion_id integer NOT NULL REFERENCES operaciones.tb_parte_clasificacion(parte_clasificacion_id),
    parte_subclasificacion_descripcion text COLLATE pg_catalog."default" NOT NULL
);

CREATE TABLE IF NOT EXISTS operaciones.tb_parte_uso (
    parte_uso_id SERIAL NOT NULL PRIMARY KEY,
    fk_parte_subclasificacion_id integer NOT NULL REFERENCES operaciones.tb_parte_subclasificacion(parte_subclasificacion_id),
    parte_uso_codigo text COLLATE pg_catalog."default" NOT NULL,
    parte_uso_descripcion text COLLATE pg_catalog."default" NOT NULL
);

CREATE TABLE IF NOT EXISTS operaciones.tb_parte_causa (
    parte_causa_id SERIAL NOT NULL PRIMARY KEY,
    parte_causa_codigo text COLLATE pg_catalog."default" NOT NULL,
    parte_causa_descripcion text COLLATE pg_catalog."default" NOT NULL
);

CREATE TABLE IF NOT EXISTS operaciones.tb_parte_posible_causa (
    parte_posible_causa_id SERIAL NOT NULL PRIMARY KEY,
    fk_parte_causa_id integer NOT NULL REFERENCES operaciones.tb_parte_causa(parte_causa_id),
    parte_posible_causa_descripcion text COLLATE pg_catalog."default" NOT NULL
);

CREATE TABLE IF NOT EXISTS operaciones.tb_parte_equipo (
    parte_equipo_id SERIAL NOT NULL PRIMARY KEY,
    parte_equipo_codigo text COLLATE pg_catalog."default" NOT NULL,
    parte_equipo_descripcion text COLLATE pg_catalog."default" NOT NULL
);

CREATE TABLE IF NOT EXISTS operaciones.tb_parte_material (
    parte_material_id SERIAL NOT NULL PRIMARY KEY,
    parte_material_codigo text COLLATE pg_catalog."default" NOT NULL,
    parte_material_descripcion text COLLATE pg_catalog."default" NOT NULL
);

CREATE TABLE IF NOT EXISTS operaciones.tb_parte_insumo (
    parte_insumo_id SERIAL NOT NULL PRIMARY KEY,
    parte_insumo_codigo text COLLATE pg_catalog."default" NOT NULL,
    parte_insumo_descripcion text COLLATE pg_catalog."default" NOT NULL
);

CREATE TABLE IF NOT EXISTS operaciones.tb_parte (
    parte_id SERIAL NOT NULL PRIMARY KEY,
    parte_registro timestamp without time zone DEFAULT ('now'::text)::timestamp(0) with time zone,
    parte_estado text COLLATE pg_catalog."default" DEFAULT 'REGISTRADO'::text,
    parte_tipo text COLLATE pg_catalog."default",
    parte_codigo text COLLATE pg_catalog."default" NOT NULL,
    parte_serie integer NOT NULL,
    parte_tipo_dia text COLLATE pg_catalog."default" DEFAULT 'LABORABLE'::text,
    fk_usuario_id integer NOT NULL REFERENCES admin.tb_usuarios(usuario_id),
    fk_personal_id integer NOT NULL REFERENCES tthh.tb_personal(personal_id),
    fk_parroquia_id integer NOT NULL REFERENCES resources.parishes(parish_id),
    parte_forma_aviso text COLLATE pg_catalog."default" NOT NULL,
    parte_fecha_aviso date NOT NULL,
    parte_hora_aviso time without time zone NOT NULL,
    parte_fecha_transferencia date NOT NULL,
    parte_hora_transferencia time without time zone NOT NULL,
    parte_fecha_salida date NOT NULL,
    parte_hora_salida time without time zone NOT NULL,
    parte_fecha_arribo date NOT NULL,
    parte_hora_arribo time without time zone NOT NULL,
    parte_fecha_retorno date NOT NULL,
    parte_hora_retorno time without time zone NOT NULL,
    parte_zona text COLLATE pg_catalog."default",
    parte_calle_principal text COLLATE pg_catalog."default" NOT NULL,
    parte_calle_secundaria text COLLATE pg_catalog."default",
    parte_direccion_numero text COLLATE pg_catalog."default",
    parte_sector text COLLATE pg_catalog."default",
    parte_referencia text COLLATE pg_catalog."default",
    parte_informacion_alertante text COLLATE pg_catalog."default" NOT NULL,
    parte_observaciones text COLLATE pg_catalog."default"
);

CREATE TABLE IF NOT EXISTS operaciones.tb_parte_personal (
    parte_personal_id SERIAL NOT NULL PRIMARY KEY,
    fk_parte_id integer NOT NULL REFERENCES operaciones.tb_parte(parte_id),
    fk_personal_id integer NOT NULL REFERENCES tthh.tb_personal(personal_id),
    parte_personal_funcion text COLLATE pg_catalog."default"
);

CREATE TABLE IF NOT EXISTS operaciones.tb_parte_unidades (
    parte_unidad_id SERIAL NOT NULL PRIMARY KEY,
    fk_parte_id integer NOT NULL REFERENCES operaciones.tb_parte(parte_id),
    fk_vehiculo_id integer NOT NULL REFERENCES administrativo.tb_vehiculos(vehiculo_id),
    parte_unidad_funcion text COLLATE pg_catalog."default",
    parte_unidad_kilometraje_salida numeric(10,0) NOT NULL,
    parte_unidad_kilometraje_ingreso numeric(10,0),
    parte_unidad_despacho timestamp without time zone NOT NULL,
    parte_unidad_salida timestamp without time zone,
    parte_unidad_arribo timestamp without time zone,
    parte_unidad_fin_operaciones timestamp without time zone
);

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
);
ALTER TABLE operaciones.tb_partes ADD COLUMN IF NOT EXISTS fk_personal_despacho_id integer REFERENCES tthh.tb_personal(personal_id);
ALTER TABLE operaciones.tb_partes ADD COLUMN IF NOT EXISTS parte_fecha_aviso date;
ALTER TABLE operaciones.tb_partes ADD COLUMN IF NOT EXISTS parte_hora_transferencia_ecu smallint;
ALTER TABLE operaciones.tb_partes ADD COLUMN IF NOT EXISTS parte_minuto_transferencia_ecu smallint;
ALTER TABLE operaciones.tb_partes ADD COLUMN IF NOT EXISTS parte_calle_principal text COLLATE pg_catalog."default";
ALTER TABLE operaciones.tb_partes ADD COLUMN IF NOT EXISTS parte_calle_secundaria text COLLATE pg_catalog."default";
ALTER TABLE operaciones.tb_partes ADD COLUMN IF NOT EXISTS parte_numero_domicilio text COLLATE pg_catalog."default";
ALTER TABLE operaciones.tb_partes ADD COLUMN IF NOT EXISTS parte_informacion_alertante text COLLATE pg_catalog."default";
ALTER TABLE operaciones.tb_partes ADD COLUMN IF NOT EXISTS parte_institucion_tipo text COLLATE pg_catalog."default";
ALTER TABLE operaciones.tb_partes ADD COLUMN IF NOT EXISTS parte_institucion_propiedad text COLLATE pg_catalog."default";
ALTER TABLE operaciones.tb_partes ADD COLUMN IF NOT EXISTS parte_observacion_institucion text COLLATE pg_catalog."default";
ALTER TABLE operaciones.tb_partes ADD COLUMN IF NOT EXISTS parte_observacion_victimas text COLLATE pg_catalog."default";
ALTER TABLE operaciones.tb_partes ADD COLUMN IF NOT EXISTS parte_observacion_fallecidos text COLLATE pg_catalog."default";
ALTER TABLE operaciones.tb_partes ADD COLUMN IF NOT EXISTS parte_total_superficie_quemada_m2 numeric(16,4);
ALTER TABLE operaciones.tb_partes ADD COLUMN IF NOT EXISTS parte_causante_identificado boolean;
ALTER TABLE operaciones.tb_partes ADD COLUMN IF NOT EXISTS parte_nombre_causante text COLLATE pg_catalog."default";
ALTER TABLE operaciones.tb_partes ADD COLUMN IF NOT EXISTS parte_otros_datos_causante text COLLATE pg_catalog."default";
ALTER TABLE operaciones.tb_partes ADD COLUMN IF NOT EXISTS parte_naturaleza_especifique text COLLATE pg_catalog."default";
ALTER TABLE operaciones.tb_partes ADD COLUMN IF NOT EXISTS parte_total_muertos integer NOT NULL DEFAULT 0;
ALTER TABLE operaciones.tb_partes ADD COLUMN IF NOT EXISTS parte_total_heridos integer NOT NULL DEFAULT 0;
ALTER TABLE operaciones.tb_partes ADD COLUMN IF NOT EXISTS parte_anexo_requerido boolean;
ALTER TABLE operaciones.tb_partes ADD COLUMN IF NOT EXISTS parte_visita_inspectores boolean;
ALTER TABLE operaciones.tb_partes ADD COLUMN IF NOT EXISTS parte_visita_inspectores_motivo text COLLATE pg_catalog."default";
ALTER TABLE operaciones.tb_partes ADD COLUMN IF NOT EXISTS parte_novedades text COLLATE pg_catalog."default";
ALTER TABLE operaciones.tb_partes ADD COLUMN IF NOT EXISTS parte_croquis_url text COLLATE pg_catalog."default";
ALTER TABLE operaciones.tb_partes ADD COLUMN IF NOT EXISTS parte_elaborado_por text COLLATE pg_catalog."default";
ALTER TABLE operaciones.tb_partes ADD COLUMN IF NOT EXISTS parte_revisado_por text COLLATE pg_catalog."default";
ALTER TABLE operaciones.tb_partes ADD COLUMN IF NOT EXISTS parte_aprobado_por text COLLATE pg_catalog."default";
ALTER TABLE operaciones.tb_partes ADD COLUMN IF NOT EXISTS parte_entregado_a text COLLATE pg_catalog."default";
ALTER TABLE operaciones.tb_partes ADD COLUMN IF NOT EXISTS parte_entregado_identificacion text COLLATE pg_catalog."default";
ALTER TABLE operaciones.tb_partes ADD COLUMN IF NOT EXISTS parte_fecha_entrega date;

CREATE TABLE IF NOT EXISTS logistica.tb_ordenescombustible (
    orden_id SERIAL NOT NULL PRIMARY KEY,
    orden_registro timestamp without time zone DEFAULT ('now'::text)::timestamp(0) with time zone,
    orden_estado text COLLATE pg_catalog."default" DEFAULT 'EMITIDA'::text,
    fk_personal_id integer NOT NULL,
    fk_autoriza_id integer NOT NULL,
    fk_solicitante_id integer NOT NULL,
    fk_unidad_id integer,
    orden_codigo text COLLATE pg_catalog."default" NOT NULL,
    orden_serie integer NOT NULL DEFAULT 0,
    orden_estacionservicio_codigo text COLLATE pg_catalog."default",
    orden_estacionservicio text COLLATE pg_catalog."default",
    orden_combustible text COLLATE pg_catalog."default",
    orden_lugar text COLLATE pg_catalog."default",
    orden_emitida timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0),
    orden_valdacion date,
    fk_encargadoestacion_id integer,
    fk_operador_id integer,
    orden_total numeric(5,2),
    orden_kilometraje integer DEFAULT 0,
    orden_canecas integer DEFAULT 0,
    orden_fecha_factura date,
    orden_galones numeric(5,2),
    orden_precio numeric(5,2),
    orden_documento text COLLATE pg_catalog."default",
    tipo_caneca text COLLATE pg_catalog."default"
);

CREATE TABLE IF NOT EXISTS archivo.direcciones (
    direccion_id SERIAL PRIMARY KEY,
    direccion_sigla VARCHAR(10) NOT NULL,
    direccion_nombre_direccion TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS archivo.tipo_documentos (
    tipodocumento_id SERIAL PRIMARY KEY,
    tipodocumento_tipo VARCHAR(50) NOT NULL
);

CREATE TABLE IF NOT EXISTS archivo.documentos (
    documento_id SERIAL PRIMARY KEY,
    documento_direccion_origen_id INT REFERENCES archivo.direcciones(direccion_id),
    documento_direccion_destino_id INT REFERENCES archivo.direcciones(direccion_id),
    documento_tipo_documento_id INT REFERENCES archivo.tipo_documentos(tipodocumento_id),
    documento_numero_documento TEXT NOT NULL UNIQUE,
    documento_numero_folio INT NOT NULL,
    documento_fecha_documento DATE NOT NULL,
    documento_remitente TEXT NOT NULL,
    documento_destinatario TEXT NOT NULL,
    documento_asunto TEXT NOT NULL,
    documento_archivo_escaneado TEXT NOT NULL,
    documento_ubicacion_fisica TEXT NOT NULL,
    documento_anio INT NOT NULL
);

CREATE TABLE IF NOT EXISTS archivo.actas_entrega (
    acta_entrega_id SERIAL PRIMARY KEY,
    acta_entrega_documento_id INT REFERENCES archivo.documentos(documento_id),
    acta_entrega_fecha_entrega DATE NOT NULL,
    acta_entrega_receptor TEXT NOT NULL,
    acta_entrega_descripcion TEXT
);

CREATE TABLE IF NOT EXISTS archivo.registro_retorno (
    retorno_id SERIAL PRIMARY KEY,
    retorno_acta_entrega_id INT REFERENCES archivo.actas_entrega(acta_entrega_id),
    retorno_fecha_retorno DATE NOT NULL,
    retorno_receptor TEXT NOT NULL,
    retorno_descripcion TEXT
);

CREATE TABLE IF NOT EXISTS subjefatura.tb_tipoincidencia (
    incidencia_id SERIAL NOT NULL PRIMARY KEY,
    incidencia_estado text COLLATE pg_catalog."default" DEFAULT 'ACTIVO'::text,
    incidencia_registro timestamp without time zone DEFAULT ('now'::text)::timestamp(0) with time zone,
    incidencia_descripcion text NOT NULL COLLATE pg_catalog."default"
);

CREATE TABLE IF NOT EXISTS subjefatura.tb_tipoemergencia (
    emergencia_id SERIAL NOT NULL PRIMARY KEY,
    fk_incidencia_id INT NOT NULL REFERENCES subjefatura.tb_tipoincidencia(incidencia_id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    emergencia_estado text COLLATE pg_catalog."default" DEFAULT 'ACTIVO'::text,
    emergencia_registro timestamp without time zone DEFAULT ('now'::text)::timestamp(0) with time zone,
    emergencia_descripcion text NOT NULL COLLATE pg_catalog."default"
);

CREATE TABLE IF NOT EXISTS subjefatura.tb_causas (
    causa_id SERIAL NOT NULL PRIMARY KEY,
    fk_incidencia_id INT NOT NULL REFERENCES subjefatura.tb_tipoincidencia(incidencia_id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    causa_estado text COLLATE pg_catalog."default" DEFAULT 'ACTIVO'::text,
    causa_registro timestamp without time zone DEFAULT ('now'::text)::timestamp(0) with time zone,
    causa_codigo text COLLATE pg_catalog."default",
    causa_descripcion text NOT NULL COLLATE pg_catalog."default"
);

CREATE TABLE IF NOT EXISTS subjefatura.tb_naturaleza (
    naturaleza_id SERIAL NOT NULL PRIMARY KEY,
    fk_incidencia_id INT NOT NULL REFERENCES subjefatura.tb_tipoincidencia(incidencia_id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    naturaleza_estado text COLLATE pg_catalog."default" DEFAULT 'ACTIVO'::text,
    naturaleza_registro timestamp without time zone DEFAULT ('now'::text)::timestamp(0) with time zone,
    naturaleza_descripcion text NOT NULL COLLATE pg_catalog."default"
);

CREATE TABLE IF NOT EXISTS subjefatura.tb_intervenciones (
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
);

CREATE TABLE IF NOT EXISTS subjefatura.tb_tipoasusencia (
    tipoasusencia_id SERIAL NOT NULL PRIMARY KEY,
    tipoasusencia_estado text COLLATE pg_catalog."default" DEFAULT 'ACTIVO'::text,
    tipoasusencia_registro timestamp without time zone DEFAULT ('now'::text)::timestamp(0) with time zone,
    tipoasusencia_descripcion text NOT NULL COLLATE pg_catalog."default"
);

CREATE TABLE IF NOT EXISTS subjefatura.tb_asusencia (
    asusencia_id SERIAL NOT NULL PRIMARY KEY,
    fk_tipoausencia_id INT NOT NULL REFERENCES subjefatura.tb_tipoasusencia (tipoasusencia_id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    fk_personal_id INT NOT NULL REFERENCES tthh.tb_personal (personal_id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    fk_estacion_id INT NOT NULL REFERENCES operaciones.tb_estaciones (estacion_id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    asusencia_estado text COLLATE pg_catalog."default" DEFAULT 'ACTIVO'::text,
    asusencia_registro timestamp without time zone DEFAULT ('now'::text)::timestamp(0) with time zone,
    asusencia_descripcion text NOT NULL COLLATE pg_catalog."default"
);

CREATE TABLE IF NOT EXISTS subjefatura.tb_aph_hojaruta_tipoemergencia (
    aph_hojaruta_tipoemergencia_id SERIAL NOT NULL PRIMARY KEY,
    aph_hojaruta_tipoemergencia_descripcion text NOT NULL COLLATE pg_catalog."default"
);

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
);

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
);

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
);

CREATE TABLE IF NOT EXISTS subjefatura.tb_aph_medicamentos (
    medicamento_id SERIAL NOT NULL PRIMARY KEY,
    medicamento_nombre text COLLATE pg_catalog."default",
    medicamento_presentacion text COLLATE pg_catalog."default"
);

CREATE TABLE IF NOT EXISTS subjefatura.tb_aph_hojaruta_medicamentos (
    aph_hojaruta_medicamento_id SERIAL NOT NULL PRIMARY KEY,
    fk_aph_hojaruta_id INT NOT NULL REFERENCES subjefatura.tb_aph_hojaruta (aph_hojaruta_id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    fk_aph_hojaruta_paciente_id INT NOT NULL REFERENCES subjefatura.tb_aph_hojaruta_pacientes (aph_hojaruta_paciente_id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    fk_medicamento_id INT NOT NULL,
    aph_hojaruta_medicamento_presentacion text COLLATE pg_catalog."default",
    aph_hojaruta_medicamento_cantidad text COLLATE pg_catalog."default"
);

CREATE TABLE IF NOT EXISTS operaciones.tb_partes_personal (
    parte_personal_id SERIAL NOT NULL PRIMARY KEY,
    fk_parte_id integer NOT NULL REFERENCES operaciones.tb_partes(parte_id) ON DELETE CASCADE,
    fk_personal_id integer NOT NULL REFERENCES tthh.tb_personal(personal_id),
    parte_personal_rol text COLLATE pg_catalog."default",
    parte_personal_rango text COLLATE pg_catalog."default",
    parte_personal_grupo text COLLATE pg_catalog."default"
);

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
);

CREATE TABLE IF NOT EXISTS operaciones.tb_partes_tipos_auxilio (
    parte_tipo_auxilio_id SERIAL NOT NULL PRIMARY KEY,
    fk_parte_id integer NOT NULL REFERENCES operaciones.tb_partes(parte_id) ON DELETE CASCADE,
    parte_auxilio_clave text COLLATE pg_catalog."default",
    parte_auxilio_clasificacion text COLLATE pg_catalog."default",
    parte_auxilio_subclasificacion text COLLATE pg_catalog."default",
    parte_auxilio_uso_tipo text COLLATE pg_catalog."default",
    parte_auxilio_especifique text COLLATE pg_catalog."default"
);

CREATE TABLE IF NOT EXISTS operaciones.tb_partes_causas (
    parte_causa_id SERIAL NOT NULL PRIMARY KEY,
    fk_parte_id integer NOT NULL REFERENCES operaciones.tb_partes(parte_id) ON DELETE CASCADE,
    parte_causa_clave text COLLATE pg_catalog."default",
    parte_causa_clasificacion text COLLATE pg_catalog."default",
    parte_causa_descripcion text COLLATE pg_catalog."default",
    parte_causa_especifique text COLLATE pg_catalog."default"
);

CREATE TABLE IF NOT EXISTS operaciones.tb_partes_equipos_herramientas (
    parte_equipo_herramienta_id SERIAL NOT NULL PRIMARY KEY,
    fk_parte_id integer NOT NULL REFERENCES operaciones.tb_partes(parte_id) ON DELETE CASCADE,
    fk_estacion_id integer REFERENCES operaciones.tb_estaciones(estacion_id),
    parte_recurso_descripcion text COLLATE pg_catalog."default",
    parte_recurso_cantidad numeric,
    parte_recurso_observaciones text COLLATE pg_catalog."default"
);

CREATE TABLE IF NOT EXISTS operaciones.tb_partes_materiales_descartables (
    parte_material_descartable_id SERIAL NOT NULL PRIMARY KEY,
    fk_parte_id integer NOT NULL REFERENCES operaciones.tb_partes(parte_id) ON DELETE CASCADE,
    fk_estacion_id integer REFERENCES operaciones.tb_estaciones(estacion_id),
    parte_recurso_descripcion text COLLATE pg_catalog."default",
    parte_recurso_cantidad numeric,
    parte_recurso_observaciones text COLLATE pg_catalog."default"
);

CREATE TABLE IF NOT EXISTS operaciones.tb_partes_insumos (
    parte_insumo_id SERIAL NOT NULL PRIMARY KEY,
    fk_parte_id integer NOT NULL REFERENCES operaciones.tb_partes(parte_id) ON DELETE CASCADE,
    fk_estacion_id integer REFERENCES operaciones.tb_estaciones(estacion_id),
    parte_recurso_descripcion text COLLATE pg_catalog."default",
    parte_recurso_cantidad numeric,
    parte_recurso_observaciones text COLLATE pg_catalog."default"
);

CREATE TABLE IF NOT EXISTS operaciones.tb_partes_personas_asistidas (
    parte_persona_asistida_id SERIAL NOT NULL PRIMARY KEY,
    fk_parte_id integer NOT NULL REFERENCES operaciones.tb_partes(parte_id) ON DELETE CASCADE,
    parte_persona_institucion text COLLATE pg_catalog."default",
    parte_persona_tipo_institucion text COLLATE pg_catalog."default",
    parte_persona_nombre text COLLATE pg_catalog."default",
    parte_persona_identificacion text COLLATE pg_catalog."default",
    parte_persona_telefono text COLLATE pg_catalog."default",
    parte_persona_propiedad text COLLATE pg_catalog."default"
);

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
);

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
);

CREATE TABLE IF NOT EXISTS operaciones.tb_partes_catalogo_tipos_incendio (
    tipo_incendio_id SERIAL NOT NULL PRIMARY KEY,
    tipo_incendio_codigo text COLLATE pg_catalog."default" NOT NULL UNIQUE,
    tipo_incendio_descripcion text COLLATE pg_catalog."default" NOT NULL,
    tipo_incendio_estado text COLLATE pg_catalog."default" NOT NULL DEFAULT 'ACTIVO'::text
);

CREATE TABLE IF NOT EXISTS operaciones.tb_partes_catalogo_causas_incendio (
    causa_incendio_id SERIAL NOT NULL PRIMARY KEY,
    causa_incendio_codigo text COLLATE pg_catalog."default" NOT NULL UNIQUE,
    causa_incendio_descripcion text COLLATE pg_catalog."default" NOT NULL,
    causa_incendio_estado text COLLATE pg_catalog."default" NOT NULL DEFAULT 'ACTIVO'::text
);

CREATE TABLE IF NOT EXISTS operaciones.tb_partes_catalogo_naturalezas (
    naturaleza_id SERIAL NOT NULL PRIMARY KEY,
    naturaleza_codigo text COLLATE pg_catalog."default" NOT NULL UNIQUE,
    naturaleza_descripcion text COLLATE pg_catalog."default" NOT NULL,
    naturaleza_estado text COLLATE pg_catalog."default" NOT NULL DEFAULT 'ACTIVO'::text
);

CREATE TABLE IF NOT EXISTS operaciones.tb_partes_catalogo_causas_afectacion_humana (
    causa_afectacion_humana_id SERIAL NOT NULL PRIMARY KEY,
    causa_afectacion_humana_codigo text COLLATE pg_catalog."default" NOT NULL UNIQUE,
    causa_afectacion_humana_descripcion text COLLATE pg_catalog."default" NOT NULL,
    causa_afectacion_humana_estado text COLLATE pg_catalog."default" NOT NULL DEFAULT 'ACTIVO'::text
);

CREATE TABLE IF NOT EXISTS operaciones.tb_partes_catalogo_tipo_afectado (
    tipo_afectado_id SERIAL NOT NULL PRIMARY KEY,
    tipo_afectado_codigo text COLLATE pg_catalog."default" NOT NULL UNIQUE,
    tipo_afectado_descripcion text COLLATE pg_catalog."default" NOT NULL,
    tipo_afectado_estado text COLLATE pg_catalog."default" NOT NULL DEFAULT 'ACTIVO'::text
);

CREATE TABLE IF NOT EXISTS operaciones.tb_partes_catalogo_forma_aviso (
    forma_aviso_id SERIAL NOT NULL PRIMARY KEY,
    forma_aviso_codigo text COLLATE pg_catalog."default" NOT NULL UNIQUE,
    forma_aviso_descripcion text COLLATE pg_catalog."default" NOT NULL,
    forma_aviso_estado text COLLATE pg_catalog."default" NOT NULL DEFAULT 'ACTIVO'::text
);

CREATE TABLE IF NOT EXISTS operaciones.tb_partes_catalogo_apoyo (
    apoyo_id SERIAL NOT NULL PRIMARY KEY,
    apoyo_codigo text COLLATE pg_catalog."default" NOT NULL UNIQUE,
    apoyo_descripcion text COLLATE pg_catalog."default" NOT NULL,
    apoyo_estado text COLLATE pg_catalog."default" NOT NULL DEFAULT 'ACTIVO'::text
);

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
);

CREATE TABLE IF NOT EXISTS operaciones.tb_partes_tipos_incendio (
    parte_tipo_incendio_id SERIAL NOT NULL PRIMARY KEY,
    fk_parte_id integer NOT NULL REFERENCES operaciones.tb_partes(parte_id) ON DELETE CASCADE,
    fk_tipo_incendio_catalogo_id integer REFERENCES operaciones.tb_partes_catalogo_tipos_incendio(tipo_incendio_id),
    parte_incendio_clave text COLLATE pg_catalog."default",
    parte_incendio_clasificacion text COLLATE pg_catalog."default",
    parte_incendio_especifique text COLLATE pg_catalog."default"
);

CREATE TABLE IF NOT EXISTS operaciones.tb_partes_naturalezas (
    parte_naturaleza_id SERIAL NOT NULL PRIMARY KEY,
    fk_parte_id integer NOT NULL REFERENCES operaciones.tb_partes(parte_id) ON DELETE CASCADE,
    fk_naturaleza_catalogo_id integer REFERENCES operaciones.tb_partes_catalogo_naturalezas(naturaleza_id),
    parte_naturaleza_clave text COLLATE pg_catalog."default",
    parte_naturaleza_descripcion text COLLATE pg_catalog."default",
    parte_naturaleza_especifique text COLLATE pg_catalog."default"
);

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
);

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
);

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
);

CREATE TABLE IF NOT EXISTS subjefatura.tb_voluntarios_eventos_participantes (
    evento_participante_id SERIAL NOT NULL PRIMARY KEY,
    fk_evento_id integer NOT NULL REFERENCES subjefatura.tb_voluntarios_eventos (evento_id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    fk_voluntario_id integer NOT NULL REFERENCES subjefatura.tb_voluntarios (voluntario_id) ON DELETE RESTRICT ON UPDATE RESTRICT
);

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
);

CREATE TABLE IF NOT EXISTS subjefatura.tb_voluntarios_asignacion (
    asignacion_id SERIAL NOT NULL PRIMARY KEY,
    asignacion_registro timestamp without time zone DEFAULT ('now'::text)::timestamp(0) with time zone,
    asignacion_estado text COLLATE pg_catalog."default" DEFAULT 'ACTIVO'::text,
    fk_voluntario_id integer NOT NULL REFERENCES subjefatura.tb_voluntarios (voluntario_id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    fk_estacion_id integer NOT NULL REFERENCES operaciones.tb_estaciones (estacion_id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    fk_unidad_id integer,
    asignacion_fecha_inicio date NOT NULL,
    asignacion_fecha_fin date
);

-- Vistas
CREATE OR REPLACE VIEW tthh.vw_personal_simple as 
select ppersonal_id, personal_id,persona_doc_identidad,persona_apellidos, persona_nombres, puesto_nombre, concat( persona_apellidos,' ',persona_nombres, ', ', puesto_nombre ) as nombre_completo from tthh.tb_personal p 
inner join tthh.tb_personal_puestos pp ON pp.fk_personal_id = p.personal_id inner join tthh.tb_puestos pu on pu.puesto_id = pp.fk_puesto_id
inner join resources.tb_personas pe on pe.persona_id = fk_persona_id  order by persona_apellidos, persona_nombres;
CREATE OR REPLACE VIEW tthh.vw_conductores as
select ppersonal_id, personal_id,conductor_id, persona_doc_identidad,conductor_estado, licencia_categoria,persona_apellidos, persona_nombres, puesto_nombre, conductor_licencia_validez, concat( persona_apellidos,' ',persona_nombres, ', Lic.:', licencia_categoria ) as nombre_completo,licencia_tipo
from tthh.tb_conductores c 
inner join resources.tb_licenciasdeconducir l on l.licencia_id = c.fk_licencia_id inner join tthh.tb_personal p on p.personal_id = c.fk_personal_id
inner join tthh.tb_personal_puestos pp ON pp.fk_personal_id = p.personal_id inner join tthh.tb_puestos pu on pu.puesto_id = pp.fk_puesto_id
inner join resources.tb_personas pe on pe.persona_id = fk_persona_id order by persona_apellidos, persona_nombres;
CREATE OR REPLACE VIEW logistica.vw_ordenesomvilizacion as
SELECT orden_id, orden_serie, orden_estado, orden_codigo, vehiculo_sigla, vehiculo_placa, vehiculo_chasis, vehiculo_motor, orden_hora_salida, orden_kilometraje_salida, orden_motivo_salida, orden_destino, orden_hora_entrada, orden_kilometraje_entrada, orden_registro, orden_observaciones 
,(select concat(persona_apellidos,' ',persona_nombres) from tthh.vw_personal_simple p1 where p1.ppersonal_id =  o.director_administrativo)  as da_nombre
,(select persona_doc_identidad from tthh.vw_personal_simple p1 where p1.ppersonal_id =  o.director_administrativo)  as da_cc
,(select puesto_nombre from tthh.vw_personal_simple p1 where p1.ppersonal_id =  o.director_administrativo)  as da_puesto
,(select concat(persona_apellidos,' ',persona_nombres)  from tthh.vw_personal_simple p1 where p1.ppersonal_id =  o.personal_solicita)  as s_nombre
,(select persona_doc_identidad from tthh.vw_personal_simple p1 where p1.ppersonal_id =  o.personal_solicita)  as s_cc
,(select puesto_nombre from tthh.vw_personal_simple p1 where p1.ppersonal_id =  o.personal_solicita)  as s_puesto
,(select concat(persona_apellidos,' ',persona_nombres) from tthh.vw_conductores c1 where c1.conductor_id =  o.operador_id order by c1.ppersonal_id desc limit 1)  as o_nombre
,(select persona_doc_identidad from tthh.vw_conductores c1 where c1.conductor_id =  o.operador_id order by c1.ppersonal_id desc limit 1)  as o_cc
,(select puesto_nombre from tthh.vw_conductores c1 where c1.conductor_id =  o.operador_id order by c1.ppersonal_id desc limit 1)  as o_puesto
,(select concat(licencia_tipo,' - ',licencia_categoria) from tthh.vw_conductores c1 where c1.conductor_id =  o.operador_id order by c1.ppersonal_id desc limit 1)  as o_licencia
,(select usuario_login from admin.tb_usuarios u where u.usuario_id =  o.fk_usuario_id)  as usuario
FROM logistica.tb_ordenesmovilizacion o
inner join administrativo.tb_vehiculos v on v.vehiculo_id = o.fk_unidad_id;
