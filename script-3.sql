-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- SCRIPT 3: ÚNICO SCRIPT DE LA BASE DE DATOS (reemplaza a script.sql, script-2.sql y script_sbj_temp.sql)
--   Estructura base, catálogos, combustible, institución, mantenimiento vehicular, contratos, menús y privilegios,
--   bitácora, operadores, usuarios y perfiles, servicios generales, partes de servicio e importación de db_cbsd.
--
-- CÓMO USARLO (pgAdmin): abra el Query Tool sobre la base (db_bcbsd), pegue TODO el archivo y ejecútelo.
--   * Sirve para una base VACÍA (la crea completa) y para una base EXISTENTE (solo agrega lo que falta).
--   * Se puede ejecutar varias veces: no borra tablas ni datos; lo que ya existe se omite.
--   * La importación (sección 11) solo corre si edita la línea "conexion" con la clave de la base anterior.
--   * Base nueva sin importar: se crea el usuario "admin" (perfil Administrador); cambie su clave al entrar.
--   * Después: asigne los privilegios nuevos a los usuarios en Administración > Usuarios > Privilegios.
--
-- ARCHIVO GENERADO por migrations/generar-script-3.py a partir de migrations/. No lo edite a mano:
-- edite los archivos de migrations/ y vuelva a generarlo.
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


-- ======================================================================================================
-- 0. ESTRUCTURA BASE: esquemas, tablas y vistas (antes script.sql, script-2.sql y script_sbj_temp.sql)
-- ======================================================================================================
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


-- ======================================================================================================
-- 0.1 CATÁLOGOS BASE: estaciones, jornadas, menús, documentos y catálogos de subjefatura y partes
-- ======================================================================================================
-- =============================================================================
-- CATÁLOGOS BASE (antes en script.sql, script-2.sql y script_sbj_temp.sql) - re-ejecutable
-- Cada catálogo se carga solo si su tabla está vacía (base nueva): no duplica filas renombradas por la institución.
-- Los menús (admin.tb_roles) se cargan por ruta. Las referencias a otros catálogos se buscan por nombre.
-- =============================================================================

-- operaciones.tb_estaciones: solo si está vacía
DO $catalogo$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM operaciones.tb_estaciones) THEN
        INSERT INTO operaciones.tb_estaciones (estacion_nombre, estacion_tipo) SELECT 'X-1', 'ESTACION'
         WHERE NOT EXISTS (SELECT 1 FROM operaciones.tb_estaciones x WHERE x.estacion_nombre IS NOT DISTINCT FROM 'X-1');
        INSERT INTO operaciones.tb_estaciones (estacion_nombre, estacion_tipo) SELECT 'X-2', 'ESTACION'
         WHERE NOT EXISTS (SELECT 1 FROM operaciones.tb_estaciones x WHERE x.estacion_nombre IS NOT DISTINCT FROM 'X-2');
        INSERT INTO operaciones.tb_estaciones (estacion_nombre, estacion_tipo) SELECT 'X-3', 'ESTACION'
         WHERE NOT EXISTS (SELECT 1 FROM operaciones.tb_estaciones x WHERE x.estacion_nombre IS NOT DISTINCT FROM 'X-3');
        INSERT INTO operaciones.tb_estaciones (estacion_nombre, estacion_tipo) SELECT 'X-4', 'ESTACION'
         WHERE NOT EXISTS (SELECT 1 FROM operaciones.tb_estaciones x WHERE x.estacion_nombre IS NOT DISTINCT FROM 'X-4');
        INSERT INTO operaciones.tb_estaciones (estacion_nombre, estacion_tipo) SELECT 'X-5', 'ESTACION'
         WHERE NOT EXISTS (SELECT 1 FROM operaciones.tb_estaciones x WHERE x.estacion_nombre IS NOT DISTINCT FROM 'X-5');
        INSERT INTO operaciones.tb_estaciones (estacion_nombre, estacion_tipo) SELECT 'X-6', 'ESTACION'
         WHERE NOT EXISTS (SELECT 1 FROM operaciones.tb_estaciones x WHERE x.estacion_nombre IS NOT DISTINCT FROM 'X-6');
        INSERT INTO operaciones.tb_estaciones (estacion_nombre, estacion_tipo) SELECT 'X-7', 'ESTACION'
         WHERE NOT EXISTS (SELECT 1 FROM operaciones.tb_estaciones x WHERE x.estacion_nombre IS NOT DISTINCT FROM 'X-7');
        INSERT INTO operaciones.tb_estaciones (estacion_nombre, estacion_tipo) SELECT 'X-8', 'ESTACION'
         WHERE NOT EXISTS (SELECT 1 FROM operaciones.tb_estaciones x WHERE x.estacion_nombre IS NOT DISTINCT FROM 'X-8');
        INSERT INTO operaciones.tb_estaciones (estacion_nombre, estacion_tipo) SELECT 'Grupo de Canes', 'GRUPO'
         WHERE NOT EXISTS (SELECT 1 FROM operaciones.tb_estaciones x WHERE x.estacion_nombre IS NOT DISTINCT FROM 'Grupo de Canes');
        INSERT INTO operaciones.tb_estaciones (estacion_nombre, estacion_tipo) SELECT 'Grupo de Drones', 'GRUPO'
         WHERE NOT EXISTS (SELECT 1 FROM operaciones.tb_estaciones x WHERE x.estacion_nombre IS NOT DISTINCT FROM 'Grupo de Drones');
        INSERT INTO operaciones.tb_estaciones (estacion_nombre, estacion_tipo) SELECT 'Escuela EFEESB', 'DIRECCION'
         WHERE NOT EXISTS (SELECT 1 FROM operaciones.tb_estaciones x WHERE x.estacion_nombre IS NOT DISTINCT FROM 'Escuela EFEESB');
    END IF;
END
$catalogo$;

-- tthh.tb_jornadas_trabajo: solo si está vacía
DO $catalogo$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM tthh.tb_jornadas_trabajo) THEN
        INSERT INTO tthh.tb_jornadas_trabajo (jornada_estado, jornada_nombre, jornada_rancho, jornada_diasminimo, jornada_diasmaximo, jornada_dias_semana, jornada_horas_dia, jornada_entrada, jornada_salida, jornada_break, jornada_entrada_break, jornada_salida_break) SELECT 'ACTIVO', 'OPERATIVOS 24H/48H', 6.00, 20, 20, '["1","2","3","4","5","6","0"]', 24, '08:00', '08:00', 'NO', NULL, NULL
         WHERE NOT EXISTS (SELECT 1 FROM tthh.tb_jornadas_trabajo x WHERE x.jornada_nombre IS NOT DISTINCT FROM 'OPERATIVOS 24H/48H');
        INSERT INTO tthh.tb_jornadas_trabajo (jornada_estado, jornada_nombre, jornada_rancho, jornada_diasminimo, jornada_diasmaximo, jornada_dias_semana, jornada_horas_dia, jornada_entrada, jornada_salida, jornada_break, jornada_entrada_break, jornada_salida_break) SELECT 'ACTIVO', 'ADMINISTRATIVO 8H', 0.00, 5, 10, '["1","2","3","4","5"]', 8, '08:00', '17:00', 'SI', '13:00', '14:00'
         WHERE NOT EXISTS (SELECT 1 FROM tthh.tb_jornadas_trabajo x WHERE x.jornada_nombre IS NOT DISTINCT FROM 'ADMINISTRATIVO 8H');
        INSERT INTO tthh.tb_jornadas_trabajo (jornada_estado, jornada_nombre, jornada_rancho, jornada_diasminimo, jornada_diasmaximo, jornada_dias_semana, jornada_horas_dia, jornada_entrada, jornada_salida, jornada_break, jornada_entrada_break, jornada_salida_break) SELECT 'ACTIVO', 'OPERATIVOS 8H', 3.00, 20, 20, '["1","2","3","4","5"]', 9, '08:00', '18:00', 'NO', NULL, NULL
         WHERE NOT EXISTS (SELECT 1 FROM tthh.tb_jornadas_trabajo x WHERE x.jornada_nombre IS NOT DISTINCT FROM 'OPERATIVOS 8H');
    END IF;
END
$catalogo$;

-- administrativo.tb_vehiculos_marcas: solo si está vacía
DO $catalogo$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM administrativo.tb_vehiculos_marcas) THEN
        INSERT INTO administrativo.tb_vehiculos_marcas (marca_nombre) SELECT 'S/M'
         WHERE NOT EXISTS (SELECT 1 FROM administrativo.tb_vehiculos_marcas x WHERE x.marca_nombre IS NOT DISTINCT FROM 'S/M');
    END IF;
END
$catalogo$;

-- archivo.direcciones: solo si está vacía
DO $catalogo$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM archivo.direcciones) THEN
        INSERT INTO archivo.direcciones (direccion_sigla, direccion_nombre_direccion) SELECT 'JB', 'Jefatura de Bomberos'
         WHERE NOT EXISTS (SELECT 1 FROM archivo.direcciones x WHERE x.direccion_sigla IS NOT DISTINCT FROM 'JB');
        INSERT INTO archivo.direcciones (direccion_sigla, direccion_nombre_direccion) SELECT 'DA', 'Dirección Administrativa'
         WHERE NOT EXISTS (SELECT 1 FROM archivo.direcciones x WHERE x.direccion_sigla IS NOT DISTINCT FROM 'DA');
        INSERT INTO archivo.direcciones (direccion_sigla, direccion_nombre_direccion) SELECT 'DJ', 'Dirección Jurídica'
         WHERE NOT EXISTS (SELECT 1 FROM archivo.direcciones x WHERE x.direccion_sigla IS NOT DISTINCT FROM 'DJ');
        INSERT INTO archivo.direcciones (direccion_sigla, direccion_nombre_direccion) SELECT 'DPCE', 'Dirección Planificación y Control Estratégico'
         WHERE NOT EXISTS (SELECT 1 FROM archivo.direcciones x WHERE x.direccion_sigla IS NOT DISTINCT FROM 'DPCE');
    END IF;
END
$catalogo$;

-- archivo.tipo_documentos: solo si está vacía
DO $catalogo$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM archivo.tipo_documentos) THEN
        INSERT INTO archivo.tipo_documentos (tipodocumento_tipo) SELECT 'Memorando'
         WHERE NOT EXISTS (SELECT 1 FROM archivo.tipo_documentos x WHERE x.tipodocumento_tipo IS NOT DISTINCT FROM 'Memorando');
        INSERT INTO archivo.tipo_documentos (tipodocumento_tipo) SELECT 'Informe'
         WHERE NOT EXISTS (SELECT 1 FROM archivo.tipo_documentos x WHERE x.tipodocumento_tipo IS NOT DISTINCT FROM 'Informe');
        INSERT INTO archivo.tipo_documentos (tipodocumento_tipo) SELECT 'Oficio'
         WHERE NOT EXISTS (SELECT 1 FROM archivo.tipo_documentos x WHERE x.tipodocumento_tipo IS NOT DISTINCT FROM 'Oficio');
    END IF;
END
$catalogo$;

-- admin.tb_modulos: solo si está vacía
DO $catalogo$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM admin.tb_modulos) THEN
        INSERT INTO admin.tb_modulos (modulo_nombre) SELECT 'ROOT'
         WHERE NOT EXISTS (SELECT 1 FROM admin.tb_modulos x WHERE x.modulo_nombre IS NOT DISTINCT FROM 'ROOT');
        INSERT INTO admin.tb_modulos (modulo_nombre) SELECT 'Dir. Administrativa'
         WHERE NOT EXISTS (SELECT 1 FROM admin.tb_modulos x WHERE x.modulo_nombre IS NOT DISTINCT FROM 'Dir. Administrativa');
        INSERT INTO admin.tb_modulos (modulo_nombre) SELECT 'Subjefatura'
         WHERE NOT EXISTS (SELECT 1 FROM admin.tb_modulos x WHERE x.modulo_nombre IS NOT DISTINCT FROM 'Subjefatura');
        INSERT INTO admin.tb_modulos (modulo_nombre) SELECT 'SCI'
         WHERE NOT EXISTS (SELECT 1 FROM admin.tb_modulos x WHERE x.modulo_nombre IS NOT DISTINCT FROM 'SCI');
        INSERT INTO admin.tb_modulos (modulo_nombre) SELECT 'Operaciones'
         WHERE NOT EXISTS (SELECT 1 FROM admin.tb_modulos x WHERE x.modulo_nombre IS NOT DISTINCT FROM 'Operaciones');
    END IF;
END
$catalogo$;

-- admin.tb_submodulos: solo si está vacía
DO $catalogo$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM admin.tb_submodulos) THEN
        INSERT INTO admin.tb_submodulos (fk_modulo_id, submodulo_nombre) SELECT (SELECT modulo_id FROM admin.tb_modulos WHERE modulo_nombre = 'Dir. Administrativa' ORDER BY modulo_id LIMIT 1), 'Unidades'
         WHERE NOT EXISTS (SELECT 1 FROM admin.tb_submodulos x WHERE x.submodulo_nombre IS NOT DISTINCT FROM 'Unidades');
        INSERT INTO admin.tb_submodulos (fk_modulo_id, submodulo_nombre) SELECT (SELECT modulo_id FROM admin.tb_modulos WHERE modulo_nombre = 'Dir. Administrativa' ORDER BY modulo_id LIMIT 1), 'Ordenes de movilización'
         WHERE NOT EXISTS (SELECT 1 FROM admin.tb_submodulos x WHERE x.submodulo_nombre IS NOT DISTINCT FROM 'Ordenes de movilización');
        INSERT INTO admin.tb_submodulos (fk_modulo_id, submodulo_nombre) SELECT (SELECT modulo_id FROM admin.tb_modulos WHERE modulo_nombre = 'Subjefatura' ORDER BY modulo_id LIMIT 1), 'Parámetros'
         WHERE NOT EXISTS (SELECT 1 FROM admin.tb_submodulos x WHERE x.submodulo_nombre IS NOT DISTINCT FROM 'Parámetros');
        INSERT INTO admin.tb_submodulos (fk_modulo_id, submodulo_nombre) SELECT (SELECT modulo_id FROM admin.tb_modulos WHERE modulo_nombre = 'Subjefatura' ORDER BY modulo_id LIMIT 1), 'Intervenciones'
         WHERE NOT EXISTS (SELECT 1 FROM admin.tb_submodulos x WHERE x.submodulo_nombre IS NOT DISTINCT FROM 'Intervenciones');
        INSERT INTO admin.tb_submodulos (fk_modulo_id, submodulo_nombre) SELECT (SELECT modulo_id FROM admin.tb_modulos WHERE modulo_nombre = 'Subjefatura' ORDER BY modulo_id LIMIT 1), 'Voluntarios'
         WHERE NOT EXISTS (SELECT 1 FROM admin.tb_submodulos x WHERE x.submodulo_nombre IS NOT DISTINCT FROM 'Voluntarios');
        INSERT INTO admin.tb_submodulos (fk_modulo_id, submodulo_nombre) SELECT (SELECT modulo_id FROM admin.tb_modulos WHERE modulo_nombre = 'Operaciones' ORDER BY modulo_id LIMIT 1), 'Distributivo'
         WHERE NOT EXISTS (SELECT 1 FROM admin.tb_submodulos x WHERE x.submodulo_nombre IS NOT DISTINCT FROM 'Distributivo');
        INSERT INTO admin.tb_submodulos (fk_modulo_id, submodulo_nombre) SELECT (SELECT modulo_id FROM admin.tb_modulos WHERE modulo_nombre = 'Operaciones' ORDER BY modulo_id LIMIT 1), 'Partes de servicio'
         WHERE NOT EXISTS (SELECT 1 FROM admin.tb_submodulos x WHERE x.submodulo_nombre IS NOT DISTINCT FROM 'Partes de servicio');
    END IF;
END
$catalogo$;

-- admin.tb_roles (por ruta)
INSERT INTO admin.tb_roles (rol_nombre, rol_descripcion, fk_submodulo_id, rol_path) SELECT 'Vehiculos', 'Administrar vehiculos', (SELECT submodulo_id FROM admin.tb_submodulos WHERE submodulo_nombre = 'Unidades' ORDER BY submodulo_id LIMIT 1), '/admin/vehiculos'
 WHERE NOT EXISTS (SELECT 1 FROM admin.tb_roles x WHERE x.rol_path IS NOT DISTINCT FROM '/admin/vehiculos');
INSERT INTO admin.tb_roles (rol_nombre, rol_descripcion, fk_submodulo_id, rol_path) SELECT 'Ordenes de Movilizacion', 'Administrar ordenes de movilizacion', (SELECT submodulo_id FROM admin.tb_submodulos WHERE submodulo_nombre = 'Ordenes de movilización' ORDER BY submodulo_id LIMIT 1), '/admin/ordenes-movilizacion'
 WHERE NOT EXISTS (SELECT 1 FROM admin.tb_roles x WHERE x.rol_path IS NOT DISTINCT FROM '/admin/ordenes-movilizacion');
INSERT INTO admin.tb_roles (rol_nombre, rol_descripcion, fk_submodulo_id, rol_path) SELECT 'Ingresar nuevo vehiculo', 'Poder registrar nuevas unidades', (SELECT submodulo_id FROM admin.tb_submodulos WHERE submodulo_nombre = 'Unidades' ORDER BY submodulo_id LIMIT 1), null
 WHERE NOT EXISTS (SELECT 1 FROM admin.tb_roles x WHERE x.rol_nombre IS NOT DISTINCT FROM 'Ingresar nuevo vehiculo');
INSERT INTO admin.tb_roles (rol_nombre, rol_descripcion, fk_submodulo_id, rol_path) SELECT 'Estadisticas', 'Estadisticas operaticas', (SELECT submodulo_id FROM admin.tb_submodulos WHERE submodulo_nombre = 'Parámetros' ORDER BY submodulo_id LIMIT 1), '/sbj/dashboard'
 WHERE NOT EXISTS (SELECT 1 FROM admin.tb_roles x WHERE x.rol_path IS NOT DISTINCT FROM '/sbj/dashboard');
INSERT INTO admin.tb_roles (rol_nombre, rol_descripcion, fk_submodulo_id, rol_path) SELECT 'Intervenciones', 'Administración de intervenciones de emergencias', (SELECT submodulo_id FROM admin.tb_submodulos WHERE submodulo_nombre = 'Intervenciones' ORDER BY submodulo_id LIMIT 1), '/sbj/intervenciones'
 WHERE NOT EXISTS (SELECT 1 FROM admin.tb_roles x WHERE x.rol_path IS NOT DISTINCT FROM '/sbj/intervenciones');
INSERT INTO admin.tb_roles (rol_nombre, rol_descripcion, fk_submodulo_id, rol_path) SELECT 'Ausencias', 'Registros de ausencias del presonal', (SELECT submodulo_id FROM admin.tb_submodulos WHERE submodulo_nombre = 'Parámetros' ORDER BY submodulo_id LIMIT 1), '/sbj/ausencias'
 WHERE NOT EXISTS (SELECT 1 FROM admin.tb_roles x WHERE x.rol_path IS NOT DISTINCT FROM '/sbj/ausencias');
INSERT INTO admin.tb_roles (rol_nombre, rol_descripcion, fk_submodulo_id, rol_path) SELECT 'Voluntarios', 'Registros de voluntarios', (SELECT submodulo_id FROM admin.tb_submodulos WHERE submodulo_nombre = 'Voluntarios' ORDER BY submodulo_id LIMIT 1), '/sbj/ubv-voluntarios'
 WHERE NOT EXISTS (SELECT 1 FROM admin.tb_roles x WHERE x.rol_path IS NOT DISTINCT FROM '/sbj/ubv-voluntarios');
INSERT INTO admin.tb_roles (rol_nombre, rol_descripcion, fk_submodulo_id, rol_path) SELECT 'UBV Actividades', 'Registros de actividades de personal voluntario', (SELECT submodulo_id FROM admin.tb_submodulos WHERE submodulo_nombre = 'Voluntarios' ORDER BY submodulo_id LIMIT 1), '/sbj/ubv-actividades'
 WHERE NOT EXISTS (SELECT 1 FROM admin.tb_roles x WHERE x.rol_path IS NOT DISTINCT FROM '/sbj/ubv-actividades');
INSERT INTO admin.tb_roles (rol_nombre, rol_descripcion, fk_submodulo_id, rol_path) SELECT 'UBV Eventos', 'Registros de eventos de personal voluntario', (SELECT submodulo_id FROM admin.tb_submodulos WHERE submodulo_nombre = 'Voluntarios' ORDER BY submodulo_id LIMIT 1), '/sbj/ubv-eventos'
 WHERE NOT EXISTS (SELECT 1 FROM admin.tb_roles x WHERE x.rol_path IS NOT DISTINCT FROM '/sbj/ubv-eventos');
INSERT INTO admin.tb_roles (rol_nombre, rol_descripcion, fk_submodulo_id, rol_path) SELECT 'Distributivo', 'Administrar distributivos de personal', (SELECT submodulo_id FROM admin.tb_submodulos WHERE submodulo_nombre = 'Distributivo' ORDER BY submodulo_id LIMIT 1), '/operaciones/distributivo'
 WHERE NOT EXISTS (SELECT 1 FROM admin.tb_roles x WHERE x.rol_path IS NOT DISTINCT FROM '/operaciones/distributivo');
INSERT INTO admin.tb_roles (rol_nombre, rol_descripcion, fk_submodulo_id, rol_path) SELECT 'Partes de servicio', 'Administrar partes de servicio', (SELECT submodulo_id FROM admin.tb_submodulos WHERE submodulo_nombre = 'Partes de servicio' ORDER BY submodulo_id LIMIT 1), '/operaciones/partes'
 WHERE NOT EXISTS (SELECT 1 FROM admin.tb_roles x WHERE x.rol_path IS NOT DISTINCT FROM '/operaciones/partes');

-- subjefatura.tb_aph_hojaruta_tipoemergencia: solo si está vacía
DO $catalogo$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM subjefatura.tb_aph_hojaruta_tipoemergencia) THEN
        INSERT INTO subjefatura.tb_aph_hojaruta_tipoemergencia (aph_hojaruta_tipoemergencia_descripcion) SELECT 'TRASLADO DE PACIENTE'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_aph_hojaruta_tipoemergencia x WHERE x.aph_hojaruta_tipoemergencia_descripcion IS NOT DISTINCT FROM 'TRASLADO DE PACIENTE');
        INSERT INTO subjefatura.tb_aph_hojaruta_tipoemergencia (aph_hojaruta_tipoemergencia_descripcion) SELECT 'ATROPELLAMIENTO'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_aph_hojaruta_tipoemergencia x WHERE x.aph_hojaruta_tipoemergencia_descripcion IS NOT DISTINCT FROM 'ATROPELLAMIENTO');
        INSERT INTO subjefatura.tb_aph_hojaruta_tipoemergencia (aph_hojaruta_tipoemergencia_descripcion) SELECT 'OBSTETRICA'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_aph_hojaruta_tipoemergencia x WHERE x.aph_hojaruta_tipoemergencia_descripcion IS NOT DISTINCT FROM 'OBSTETRICA');
    END IF;
END
$catalogo$;

-- subjefatura.tb_tipoincidencia: solo si está vacía
DO $catalogo$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoincidencia) THEN
        INSERT INTO subjefatura.tb_tipoincidencia (incidencia_descripcion) SELECT 'INCENDIO'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoincidencia x WHERE x.incidencia_descripcion IS NOT DISTINCT FROM 'INCENDIO');
        INSERT INTO subjefatura.tb_tipoincidencia (incidencia_descripcion) SELECT 'AUXILIO'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoincidencia x WHERE x.incidencia_descripcion IS NOT DISTINCT FROM 'AUXILIO');
        INSERT INTO subjefatura.tb_tipoincidencia (incidencia_descripcion) SELECT 'ATENCION PRE HOSPITALARIA'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoincidencia x WHERE x.incidencia_descripcion IS NOT DISTINCT FROM 'ATENCION PRE HOSPITALARIA');
    END IF;
END
$catalogo$;

-- subjefatura.tb_tipoemergencia: solo si está vacía
DO $catalogo$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia) THEN
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), 'Declarado'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Declarado');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), 'Incendio'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Incendio');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), 'Amago'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Amago');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), 'Forestal'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Forestal');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), 'Fuga de gas'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Fuga de gas');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), 'Simulacro'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Simulacro');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), 'Inspección con Sirena – Baliza'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Inspección con Sirena – Baliza');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), 'Inspección sin Sirena – Baliza'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Inspección sin Sirena – Baliza');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), 'Falsa Alarma'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Falsa Alarma');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), 'Incendio / apoyo '
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Incendio / apoyo ');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Rescate'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Rescate');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Inundación'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Inundación');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Traslado de ambulancia'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Traslado de ambulancia');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Deslizamiento de tierra'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Deslizamiento de tierra');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Simulacro en Rescate'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Simulacro en Rescate');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Rescate / apoyo'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Rescate / apoyo');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Inundación (apoyo)'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Inundación (apoyo)');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Traslado de paciente'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Traslado de paciente');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Desfile'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Desfile');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Simulacro en Evacuación'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Simulacro en Evacuación');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Salvamento'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Salvamento');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Accidente de transito'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Accidente de transito');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Soporte Vital'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Soporte Vital');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Abrir departamento'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Abrir departamento');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Reparto de agua'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Reparto de agua');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Capacitación'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Capacitación');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Baldeo'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Baldeo');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Evacuación'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Evacuación');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Accidente Aviatorio'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Accidente Aviatorio');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Caída de arboles'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Caída de arboles');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Inspección con Sirena – Baliza'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Inspección con Sirena – Baliza');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Inspección sin Sirena – Baliza'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Inspección sin Sirena – Baliza');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Apoyo'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Apoyo');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Auxilio General'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Auxilio General');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1), 'Traslado de paciente'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Traslado de paciente');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1), 'Salvamento'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Salvamento');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1), 'Soporte Vital'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Soporte Vital');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1), 'Accidente Aviatorio'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Accidente Aviatorio');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1), 'Inspección con Sirena – Baliza'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Inspección con Sirena – Baliza');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1), 'Inspección sin Sirena – Baliza'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Inspección sin Sirena – Baliza');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1), 'Auxilio General'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Auxilio General');
    END IF;
END
$catalogo$;

-- subjefatura.tb_causas: solo si está vacía
DO $catalogo$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas) THEN
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Desconocida'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Desconocida');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Derrame de combustible'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Derrame de combustible');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Eléctrica'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Eléctrica');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Accidente de transito'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Accidente de transito');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Intencional'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Intencional');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Explosión'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Explosión');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Rayo'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Rayo');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Desprendimiento de chispa'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Desprendimiento de chispa');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Imprevisión'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Imprevisión');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Fuga de gas'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Fuga de gas');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Maniobras militares'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Maniobras militares');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Propagación de incendio'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Propagación de incendio');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Descuido'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Descuido');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Combustión espontanea'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Combustión espontanea');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Quema agrícola'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Quema agrícola');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Quema de basura'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Quema de basura');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Instruir a la ciudadanía'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Instruir a la ciudadanía');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Vehicular'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Vehicular');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Caída'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Caída');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Combustible derramado'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Combustible derramado');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Choque'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Choque');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Parto'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Parto');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Evaluación Primaria'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Evaluación Primaria');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Daño de tubería'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Daño de tubería');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Escasez de agua'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Escasez de agua');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Atropellamiento'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Atropellamiento');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Intoxicación'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Intoxicación');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Apuñalamiento'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Apuñalamiento');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Acumulación de agua'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Acumulación de agua');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Caída a pozo de agua'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Caída a pozo de agua');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Volcamiento'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Volcamiento');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Quemaduras'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Quemaduras');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Traslado de animales'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Traslado de animales');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Estado Etílico'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Estado Etílico');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Instruir a la ciudadanía'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Instruir a la ciudadanía');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Traumatismo'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Traumatismo');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Enfermedad'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Enfermedad');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Olvido de llaves'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Olvido de llaves');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Picadura de animales'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Picadura de animales');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Mordedura de animales'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Mordedura de animales');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Material solido derramado'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Material solido derramado');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Acto Cívico'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Acto Cívico');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Otro'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Otro');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1), '10.', 'ATROPELLAMIENTO'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'ATROPELLAMIENTO');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1), '10.', 'TRAUMATISMO'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'TRAUMATISMO');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1), '10.', 'QUEMADURAS'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'QUEMADURAS');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1), '10.', 'INTOXICACIÓN'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'INTOXICACIÓN');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1), '10.', 'PARTO'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'PARTO');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1), '10.', 'APUÑALAMIENTO'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'APUÑALAMIENTO');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1), '10.', 'EVALUACIÓN PRIMARIA'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'EVALUACIÓN PRIMARIA');
    END IF;
END
$catalogo$;

-- subjefatura.tb_naturaleza: solo si está vacía
DO $catalogo$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza) THEN
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), 'Vivienda'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Vivienda');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), 'Clandestino'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Clandestino');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), 'Terreno baldío'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Terreno baldío');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), 'Panadería'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Panadería');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), 'Industria'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Industria');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), 'Mecánica'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Mecánica');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), 'Bosque / Campo'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Bosque / Campo');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), 'Iglesia'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Iglesia');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), 'Comercio'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Comercio');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), 'Restaurante'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Restaurante');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), 'Centro Comercial'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Centro Comercial');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), 'Aserradero'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Aserradero');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), 'Vehículo'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Vehículo');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), 'Est. De Servicio'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Est. De Servicio');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), 'Edificio oficinas'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Edificio oficinas');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), 'Otros'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Otros');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Vivienda'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Vivienda');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Vía pública'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Vía pública');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Casa de Salud'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Casa de Salud');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Escenario deportivo'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Escenario deportivo');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Concentración  pública'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Concentración  pública');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Institución'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Institución');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Pozo de agua'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Pozo de agua');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Campo y bosque'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Campo y bosque');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Carretera'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Carretera');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Otro'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Otro');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1), 'Vivienda'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Vivienda');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1), 'Vía pública'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Vía pública');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1), 'Casa de Salud'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Casa de Salud');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1), 'Escenario deportivo'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Escenario deportivo');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1), 'Concentración  pública'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Concentración  pública');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1), 'Institución'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Institución');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1), 'Pozo de agua'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Pozo de agua');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1), 'Campo y bosque'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Campo y bosque');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1), 'Carretera'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Carretera');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1), 'Otro'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Otro');
    END IF;
END
$catalogo$;

-- Catálogos de partes de servicio
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
-- Pantallas o acciones en desuso: rol_estado = 'INACTIVO' (no salen en el menú ni en Privilegios y su ruta queda bloqueada).
-- NULL o 'ACTIVO' = en uso. Se reactiva con: UPDATE admin.tb_roles SET rol_estado = 'ACTIVO' WHERE rol_codigo = '...';
ALTER TABLE admin.tb_roles ADD COLUMN IF NOT EXISTS rol_estado text;
CREATE OR REPLACE VIEW admin.vw_usuario_privilegios AS
SELECT u.usuario_id, ur.fk_rol_id AS rol_id, 'USUARIO'::text AS origen
  FROM admin.tb_usuarios u JOIN admin.tb_usuario_rol ur ON ur.fk_usuario_id = u.usuario_id
  JOIN admin.tb_roles r ON r.rol_id = ur.fk_rol_id AND r.rol_estado IS DISTINCT FROM 'INACTIVO'
 WHERE COALESCE(u.usuario_estado, 'ACTIVO') = 'ACTIVO'
UNION
SELECT u.usuario_id, pr.fk_rol_id, 'PERFIL'::text
  FROM admin.tb_usuarios u
  JOIN admin.tb_perfiles p ON p.perfil_id = u.fk_perfil_id AND COALESCE(p.perfil_estado, 'ACTIVO') = 'ACTIVO'
  JOIN admin.tb_perfil_rol pr ON pr.fk_perfil_id = p.perfil_id
  JOIN admin.tb_roles r ON r.rol_id = pr.fk_rol_id AND r.rol_estado IS DISTINCT FROM 'INACTIVO'
 WHERE COALESCE(u.usuario_estado, 'ACTIVO') = 'ACTIVO';
COMMENT ON VIEW admin.vw_usuario_privilegios IS 'Privilegios efectivos: perfil + adicionales, solo usuarios, perfiles y privilegios ACTIVOS';

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
-- Esquema del formulario actual: operaciones.tb_partes + detalles (creados en migrations/base/01-estructura.sql). Las tablas antiguas
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
-- Filas de ejemplo del script original (con clave fija): quedan inactivas si ningún parte las usa
UPDATE operaciones.tb_partes_catalogo_tipos_auxilio c SET tipo_auxilio_estado = 'INACTIVO'
 WHERE c.tipo_auxilio_clave <> ''
   AND NOT EXISTS (SELECT 1 FROM operaciones.tb_partes_tipos_auxilio d WHERE d.fk_tipo_auxilio_id = c.tipo_auxilio_id);

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

    -- Datos base: personas, personal, usuarios, vehículos, ubicaciones, CIE-10
    INSERT INTO resources.tb_personas (
        persona_id,
        persona_tipo_doc,
        persona_doc_identidad,
        persona_nombres,
        persona_apellidos,
        persona_sexo,
        persona_imagen,
        persona_direccion,
        persona_telefono,
        persona_correo,
        persona_fingreso,
        fk_usuario_id,
        persona_fnacimiento,
        persona_nacionalidad,
        persona_celular,
        persona_estadocivil,
        persona_tiposangre,
        fk_parroquia_id,
        persona_estatura,
        persona_peso,
        persona_acerca,
        persona_destrezas,
        persona_alergias,
        persona_discapacidad,
        persona_lugarnacimiento,
        persona_etnia,
        persona_senialesparticulares,
        fk_conyugeue_id,
        persona_principal,
        persona_secundaria,
        persona_no_casa,
        persona_referencia,
        persona_barrio_ciudadela,
        persona_barrio_sector,
        persona_titulo,
        persona_anexo_cedula,
        persona_anexo_votacion,
        persona_cemergencia_nombre,
        persona_cemergencia_parentesco,
        persona_cemergencia_direccion,
        persona_cemergencia_telefono,
        persona_discapacidad_tiene,
        persona_discapacidad_tipo,
        persona_discapacidad_porcentaje,
        persona_discapacidad_conadis,
        persona_discapacidad_conadis_numero,
        persona_enfermedad_cronica,
        persona_enfermedad_cronica_describa
    )
    SELECT 
        persona_id,
        persona_tipo_doc,
        persona_doc_identidad,
        persona_nombres,
        persona_apellidos,
        persona_sexo,
        persona_imagen,
        persona_direccion,
        persona_telefono,
        persona_correo,
        persona_fingreso,
        fk_usuario_id,
        persona_fnacimiento,
        persona_nacionalidad,
        persona_celular,
        persona_estadocivil,
        persona_tiposangre,
        fk_parroquia_id,
        persona_estatura,
        persona_peso,
        persona_acerca,
        persona_destrezas,
        persona_alergias,
        persona_discapacidad,
        persona_lugarnacimiento,
        persona_etnia,
        persona_senialesparticulares,
        fk_conyugeue_id,
        persona_principal,
        persona_secundaria,
        persona_no_casa,
        persona_referencia,
        persona_barrio_ciudadela,
        persona_barrio_sector,
        persona_titulo,
        persona_anexo_cedula,
        persona_anexo_votacion,
        persona_cemergencia_nombre,
        persona_cemergencia_parentesco,
        persona_cemergencia_direccion,
        persona_cemergencia_telefono,
        persona_discapacidad_tiene,
        persona_discapacidad_tipo,
        persona_discapacidad_porcentaje,
        persona_discapacidad_conadis,
        persona_discapacidad_conadis_numero,
        persona_enfermedad_cronica,
        persona_enfermedad_cronica_describa
    FROM dblink('legacy',
        $$
        SELECT 
            persona_id,
            persona_tipo_doc,
            persona_doc_identidad,
            persona_nombres,
            persona_apellidos,
            persona_sexo,
            persona_imagen,
            persona_direccion,
            persona_telefono,
            persona_correo,
            persona_fingreso,
            fk_usuario_id,
            persona_fnacimiento,
            persona_nacionalidad,
            persona_celular,
            persona_estadocivil,
            persona_tiposangre,
            fk_parroquia_id,
            persona_estatura,
            persona_peso,
            persona_acerca,
            persona_destrezas,
            persona_alergias,
            persona_discapacidad,
            persona_lugarnacimiento,
            persona_etnia,
            persona_senialesparticulares,
            fk_conyugeue_id,
            persona_principal,
            persona_secundaria,
            persona_no_casa,
            persona_referencia,
            persona_barrio_ciudadela,
            persona_barrio_sector,
            persona_titulo,
            persona_anexo_cedula,
            persona_anexo_votacion,
            persona_cemergencia_nombre,
            persona_cemergencia_parentesco,
            persona_cemergencia_direccion,
            persona_cemergencia_telefono,
            persona_discapacidad_tiene,
            persona_discapacidad_tipo,
            persona_discapacidad_porcentaje,
            persona_discapacidad_conadis,
            persona_discapacidad_conadis_numero,
            persona_enfermedad_cronica,
            persona_enfermedad_cronica_describa
        FROM resources.tb_personas
        $$
    ) AS t (
        persona_id integer,
        persona_tipo_doc text,
        persona_doc_identidad text,
        persona_nombres text,
        persona_apellidos text,
        persona_sexo text,
        persona_imagen text,
        persona_direccion text,
        persona_telefono text,
        persona_correo text,
        persona_fingreso timestamp,
        fk_usuario_id integer,
        persona_fnacimiento date,
        persona_nacionalidad text,
        persona_celular text,
        persona_estadocivil text,
        persona_tiposangre text,
        fk_parroquia_id integer,
        persona_estatura text,
        persona_peso text,
        persona_acerca text,
        persona_destrezas text,
        persona_alergias text,
        persona_discapacidad text,
        persona_lugarnacimiento text,
        persona_etnia text,
        persona_senialesparticulares text,
        fk_conyugeue_id integer,
        persona_principal text,
        persona_secundaria text,
        persona_no_casa text,
        persona_referencia text,
        persona_barrio_ciudadela text,
        persona_barrio_sector text,
        persona_titulo text,
        persona_anexo_cedula text,
        persona_anexo_votacion text,
        persona_cemergencia_nombre text,
        persona_cemergencia_parentesco text,
        persona_cemergencia_direccion text,
        persona_cemergencia_telefono text,
        persona_discapacidad_tiene text,
        persona_discapacidad_tipo text,
        persona_discapacidad_porcentaje text,
        persona_discapacidad_conadis text,
        persona_discapacidad_conadis_numero text,
        persona_enfermedad_cronica text,
        persona_enfermedad_cronica_describa text
    )
    ON CONFLICT DO NOTHING;

    PERFORM setval(pg_get_serial_sequence('resources.tb_personas', 'persona_id'), (SELECT MAX(persona_id) FROM resources.tb_personas));

    INSERT INTO resources.tb_licenciasdeconducir (
        licencia_id,
        licencia_estado,
        licencia_registro,
        fk_usuario_id,
        licencia_tipo,
        licencia_categoria,
        licencia_descripcion
    )
    SELECT 
        licencia_id,
        licencia_estado,
        licencia_registro,
        fk_usuario_id,
        licencia_tipo,
        licencia_categoria,
        licencia_descripcion
    FROM dblink('legacy',
        $$
        SELECT 
            licencia_id,
            licencia_estado,
            licencia_registro,
            fk_usuario_id,
            licencia_tipo,
            licencia_categoria,
            licencia_descripcion
        FROM resources.tb_licenciasdeconducir
        $$
    ) AS t (
        licencia_id integer,
        licencia_estado text,
        licencia_registro timestamp,
        fk_usuario_id integer,
        licencia_tipo text,
        licencia_categoria text,
        licencia_descripcion text
    )
    ON CONFLICT DO NOTHING;

    PERFORM setval(pg_get_serial_sequence('resources.tb_licenciasdeconducir', 'licencia_id'), (SELECT MAX(licencia_id) FROM resources.tb_licenciasdeconducir));

    INSERT INTO admin.tb_perfiles (
        perfil_id,
        perfil_nombre,
        perfil_descripcion,
        perfil_estado
    )
    SELECT 
        perfil_id,
        perfil_nombre,
        perfil_descripcion,
        perfil_estado
    FROM dblink('legacy',
        $$
        SELECT 
            perfil_id,
            perfil_nombre,
            perfil_descripcion,
            perfil_estado
        FROM admin.tb_perfiles
        $$
    ) AS t (
        perfil_id integer,
        perfil_nombre text,
        perfil_descripcion text,
        perfil_estado text
    )
    ON CONFLICT DO NOTHING;

    PERFORM setval(pg_get_serial_sequence('admin.tb_perfiles', 'perfil_id'), (SELECT MAX(perfil_id) FROM admin.tb_perfiles));

    INSERT INTO admin.tb_usuarios (
        usuario_id,
        fk_persona_id,
        fk_perfil_id,
        usuario_login,
        usuario_pass,
        usuario_estado,
        usuario_acceso_correcto,
        usuario_acceso_fallido,
        usuario_cambio_perfil,
        fk_usuario_id,
        usuario_cambiar_pass,
        usuario_idioma,
        usuario_webmail_user,
        usuario_webmail_pass,
        usuario_registro,
        usuario_fingreso
    )
    SELECT 
        usuario_id,
        fk_persona_id,
        fk_perfil_id,
        usuario_login,
        usuario_pass,
        usuario_estado,
        usuario_acceso_correcto,
        usuario_acceso_fallido,
        usuario_cambio_perfil,
        fk_usuario_id,
        usuario_cambiar_pass,
        usuario_idioma,
        usuario_webmail_user,
        usuario_webmail_pass,
        usuario_registro,
        usuario_fingreso
    FROM dblink('legacy',
        $$
        SELECT 
            usuario_id,
            fk_persona_id,
            fk_perfil_id,
            usuario_login,
            usuario_pass,
            usuario_estado,
            usuario_acceso_correcto,
            usuario_acceso_fallido,
            usuario_cambio_perfil,
            fk_usuario_id,
            usuario_cambiar_pass,
            usuario_idioma,
            usuario_webmail_user,
            usuario_webmail_pass,
            usuario_registro,
            usuario_fingreso
        FROM admin.tb_usuarios
        $$
    ) AS t (
        usuario_id integer,
        fk_persona_id integer,
        fk_perfil_id integer,
        usuario_login text,
        usuario_pass text,
        usuario_estado text,
        usuario_acceso_correcto boolean,
        usuario_acceso_fallido boolean,
        usuario_cambio_perfil boolean,
        fk_usuario_id integer,
        usuario_cambiar_pass boolean,
        usuario_idioma text,
        usuario_webmail_user text,
        usuario_webmail_pass text,
        usuario_registro timestamp,
        usuario_fingreso timestamp
    )
    ON CONFLICT DO NOTHING;

    PERFORM setval(pg_get_serial_sequence('admin.tb_usuarios', 'usuario_id'), (SELECT MAX(usuario_id) FROM admin.tb_usuarios));

    INSERT INTO tthh.tb_direcciones (
        direccion_id,
        direccion_registro,
        direccion_estado,
        fk_usuario_id,
        direccion_codigo,
        direccion_nombre,
        direccion_competencias,
        direccion_fecha_creacion,
        direccion_baselegal,
        direccion_tipo
    )
    SELECT 
        direccion_id,
        direccion_registro,
        direccion_estado,
        fk_usuario_id,
        direccion_codigo,
        direccion_nombre,
        direccion_competencias,
        direccion_fecha_creacion,
        direccion_baselegal,
        direccion_tipo
    FROM dblink('legacy',
        $$
        SELECT 
            direccion_id,
            direccion_registro,
            direccion_estado,
            fk_usuario_id,
            direccion_codigo,
            direccion_nombre,
            direccion_competencias,
            direccion_fecha_creacion,
            direccion_baselegal,
            direccion_tipo
        FROM tthh.tb_direcciones
        $$
    ) AS t (
        direccion_id integer,
        direccion_registro timestamp,
        direccion_estado text,
        fk_usuario_id integer,
        direccion_codigo text,
        direccion_nombre text,
        direccion_competencias text,
        direccion_fecha_creacion date,
        direccion_baselegal text,
        direccion_tipo text
    )
    ON CONFLICT DO NOTHING;

    PERFORM setval(pg_get_serial_sequence('tthh.tb_direcciones', 'direccion_id'), (SELECT MAX(direccion_id) FROM tthh.tb_direcciones));

    INSERT INTO administrativo.tb_vehiculos (
        vehiculo_id,
        fk_usuario_id,
        fk_estacion_id,
        fk_marca_id,
        vehiculo_registro,
        vehiculo_estado,
        vehiculo_direccion,
        vehiculo_placa,
        vehiculo_toneladas,
        vehiculo_tipo,
        vehiculo_color1,
        vehiculo_marca,
        vehiculo_fingreso,
        custodio_id,
        vehiculo_modelo,
        vehiculo_chasis,
        vehiculo_motor,
        vehiculo_combustible,
        vehiculo_avaluo,
        vehiculo_anio,
        vehiculo_pais,
        vehiculo_corroceria,
        vehiculo_pasajeros,
        vehiculo_cilindraje,
        vehiculo_color2,
        vehiculo_proposito,
        vehiculo_anio_matricula,
        vehiculo_ramv,
        vehiculo_sigla
    )
    SELECT 
        vehiculo_id,
        fk_usuario_id,
        fk_estacion_id,
        fk_marca_id,
        vehiculo_registro,
        vehiculo_estado,
        vehiculo_direccion,
        vehiculo_placa,
        vehiculo_toneladas,
        vehiculo_tipo,
        vehiculo_color1,
        vehiculo_marca,
        vehiculo_fingreso,
        custodio_id,
        vehiculo_modelo,
        vehiculo_chasis,
        vehiculo_motor,
        vehiculo_combustible,
        vehiculo_avaluo,
        vehiculo_anio,
        vehiculo_pais,
        vehiculo_corroceria,
        vehiculo_pasajeros,
        vehiculo_cilindraje,
        vehiculo_color2,
        vehiculo_proposito,
        vehiculo_anio_matricula,
        vehiculo_ramv,
        vehiculo_sigla
    FROM dblink('legacy',
        $$
        SELECT 
            vehiculo_id,
            fk_usuario_id,
            1 as fk_estacion_id,
            1 as fk_marca_id,
            vehiculo_registro,
            vehiculo_estado,
            vehiculo_direccion,
            vehiculo_placa,
            vehiculo_toneladas,
            vehiculo_tipo,
            vehiculo_color1,
            vehiculo_marca,
            vehiculo_fingreso,
            1 as custodio_id,
            vehiculo_modelo,
            vehiculo_chasis,
            vehiculo_motor,
            vehiculo_combustible,
            vehiculo_avaluo,
            vehiculo_anio,
            vehiculo_pais,
            vehiculo_corroceria,
            vehiculo_pasajeros,
            vehiculo_cilindraje,
            vehiculo_color2,
            vehiculo_proposito,
            vehiculo_anio_matricula,
            vehiculo_ramv,
            (select unidad_nombre from logistica.tb_unidades where resources.tb_vehiculos.vehiculo_id = logistica.tb_unidades.fk_vehiculo_id ) as vehiculo_sigla
        FROM resources.tb_vehiculos where vehiculo_id in (select fk_vehiculo_id from logistica.tb_unidades)
        $$
    ) AS t (
        vehiculo_id integer,
        fk_usuario_id integer,
        fk_estacion_id integer,
        fk_marca_id integer,
        vehiculo_registro timestamp,
        vehiculo_estado text,
        vehiculo_direccion text,
        vehiculo_placa text,
        vehiculo_toneladas numeric(4,2),
        vehiculo_tipo text,
        vehiculo_color1 text,
        vehiculo_marca text,
        vehiculo_fingreso timestamp,
        custodio_id integer,
        vehiculo_modelo text,
        vehiculo_chasis text,
        vehiculo_motor text,
        vehiculo_combustible text,
        vehiculo_avaluo numeric(10,2),
        vehiculo_anio integer,
        vehiculo_pais text,
        vehiculo_corroceria text,
        vehiculo_pasajeros integer,
        vehiculo_cilindraje numeric(6,2),
        vehiculo_color2 text,
        vehiculo_proposito text,
        vehiculo_anio_matricula integer,
        vehiculo_ramv text,
        vehiculo_sigla text
    )
    ON CONFLICT DO NOTHING;

    PERFORM setval(pg_get_serial_sequence('administrativo.tb_vehiculos', 'vehiculo_id'), (SELECT MAX(vehiculo_id) FROM administrativo.tb_vehiculos));

    INSERT INTO tthh.tb_personal (
        personal_id,
        personal_registro,
        personal_estado,
        fk_usuario_id,
        fk_persona_id,
        fk_estacion_id,
        personal_contrasenia,
        personal_cambiar_pass,
        personal_notificar_acceso_exitoso,
        personal_notificar_acceso_fallido,
        personal_notificar_cambios_perfil,
        personal_notificar_permisos,
        personal_notificar_eventos,
        personal_correo_institucional,
        biometrico_id,
        fk_jornada_id
    )
    SELECT 
        personal_id,
        personal_registro,
        personal_estado,
        fk_usuario_id,
        fk_persona_id,
        fk_estacion_id,
        personal_contrasenia,
        personal_cambiar_pass,
        personal_notificar_acceso_exitoso,
        personal_notificar_acceso_fallido,
        personal_notificar_cambios_perfil,
        personal_notificar_permisos,
        personal_notificar_eventos,
        personal_correo_institucional,
        biometrico_id,
        fk_jornada_id
    FROM dblink('legacy',
        $$
        SELECT 
            personal_id,
            personal_registro,
            personal_estado,
            fk_usuario_id,
            fk_persona_id,
            fk_estacion_id,
            personal_contrasenia,
            personal_cambiar_pass,
            personal_notificar_acceso_exitoso,
            personal_notificar_acceso_fallido,
            personal_notificar_cambios_perfil,
            personal_notificar_permisos,
            personal_notificar_eventos,
            personal_correo_institucional,
            biometrico_id,
            fk_jornada_id
        FROM tthh.tb_personal
        $$
    ) AS t (
        personal_id integer,
        personal_registro timestamp,
        personal_estado text,
        fk_usuario_id integer,
        fk_persona_id integer,
        fk_estacion_id integer,
        personal_contrasenia text,
        personal_cambiar_pass text,
        personal_notificar_acceso_exitoso boolean,
        personal_notificar_acceso_fallido boolean,
        personal_notificar_cambios_perfil boolean,
        personal_notificar_permisos boolean,
        personal_notificar_eventos boolean,
        personal_correo_institucional text,
        biometrico_id integer,
        fk_jornada_id integer
    )
    ON CONFLICT DO NOTHING;

    PERFORM setval(pg_get_serial_sequence('tthh.tb_personal', 'personal_id'), (SELECT MAX(personal_id) FROM tthh.tb_personal));

    INSERT INTO tthh.tb_puestos (
        puesto_id,
        puesto_registro,
        puesto_estado,
        fk_usuario_id,
        puesto_departamento,
        puesto_nombre,
        fk_direccion_id,
        puesto_remuneracion,
        puesto_direccion,
        puesto_grado,
        puesto_modalidad,
        puesto_fecha_creacion,
        puesto_baselegal,
        puesto_partida,
        fk_grupo_id
    )
    SELECT 
        puesto_id,
        puesto_registro,
        puesto_estado,
        fk_usuario_id,
        puesto_departamento,
        puesto_nombre,
        fk_direccion_id,
        puesto_remuneracion,
        puesto_direccion,
        puesto_grado,
        puesto_modalidad,
        puesto_fecha_creacion,
        puesto_baselegal,
        puesto_partida,
        fk_grupo_id
    FROM dblink('legacy',
        $$
        SELECT 
            puesto_id,
            puesto_registro,
            puesto_estado,
            fk_usuario_id,
            puesto_departamento,
            puesto_nombre,
            fk_direccion_id,
            puesto_remuneracion,
            puesto_direccion,
            puesto_grado,
            puesto_modalidad,
            puesto_fecha_creacion,
            puesto_baselegal,
            puesto_partida,
            fk_grupo_id
        FROM tthh.tb_puestos
        $$
    ) AS t (
        puesto_id integer,
        puesto_registro timestamp,
        puesto_estado text,
        fk_usuario_id integer,
        puesto_departamento text,
        puesto_nombre text,
        fk_direccion_id integer,
        puesto_remuneracion numeric(10,2),
        puesto_direccion text,
        puesto_grado integer,
        puesto_modalidad text,
        puesto_fecha_creacion date,
        puesto_baselegal text,
        puesto_partida text,
        fk_grupo_id integer
    )
    ON CONFLICT DO NOTHING;

    PERFORM setval(pg_get_serial_sequence('tthh.tb_puestos', 'puesto_id'), (SELECT MAX(puesto_id) FROM tthh.tb_puestos));

    INSERT INTO tthh.tb_personal_puestos (
        ppersonal_id,
        ppersonal_registro,
        ppersonal_estado,
        fk_usuario_id,
        fk_personal_id,
        fk_puesto_id,
        personal_definicion,
        personal_contrato,
        personal_fecha_ingreso,
        personal_fecha_salida,
        personal_fecha_registro,
        personal_motivo_salida,
        personal_observacion,
        personal_baselegal,
        personal_regimen_laboral
    )
    SELECT 
        ppersonal_id,
        ppersonal_registro,
        ppersonal_estado,
        fk_usuario_id,
        fk_personal_id,
        fk_puesto_id,
        personal_definicion,
        personal_contrato,
        personal_fecha_ingreso,
        personal_fecha_salida,
        personal_fecha_registro,
        personal_motivo_salida,
        personal_observacion,
        personal_baselegal,
        personal_regimen_laboral
    FROM dblink('legacy',
        $$
        SELECT 
            ppersonal_id,
            ppersonal_registro,
            ppersonal_estado,
            fk_usuario_id,
            fk_personal_id,
            fk_puesto_id,
            personal_definicion,
            personal_contrato,
            personal_fecha_ingreso,
            personal_fecha_salida,
            personal_fecha_registro,
            personal_motivo_salida,
            personal_observacion,
            personal_baselegal,
            personal_regimen_laboral
        FROM tthh.tb_personal_puestos
        $$
    ) AS t (
        ppersonal_id integer,
        ppersonal_registro timestamp,
        ppersonal_estado text,
        fk_usuario_id integer,
        fk_personal_id integer,
        fk_puesto_id integer,
        personal_definicion text,
        personal_contrato text,
        personal_fecha_ingreso date,
        personal_fecha_salida date,
        personal_fecha_registro date,
        personal_motivo_salida text,
        personal_observacion text,
        personal_baselegal text,
        personal_regimen_laboral text
    )
    ON CONFLICT DO NOTHING;

    PERFORM setval(pg_get_serial_sequence('tthh.tb_personal_puestos', 'ppersonal_id'), (SELECT MAX(ppersonal_id) FROM tthh.tb_personal_puestos));

    INSERT INTO tthh.tb_conductores (
        conductor_id,
        conductor_registro,
        conductor_estado,
        fk_usuario_id,
        fk_personal_id,
        fk_licencia_id,
        conductor_licencia_emision,
        conductor_licencia_validez,
        conductor_pdf
    )
    SELECT 
        conductor_id,
        conductor_registro,
        conductor_estado,
        fk_usuario_id,
        fk_personal_id,
        fk_licencia_id,
        conductor_licencia_emision,
        conductor_licencia_validez,
        conductor_pdf
    FROM dblink('legacy',
        $$
        SELECT 
            conductor_id,
            conductor_registro,
            conductor_estado,
            fk_usuario_id,
            fk_personal_id,
            fk_licencia_id,
            conductor_licencia_emision,
            conductor_licencia_validez,
            conductor_pdf
        FROM tthh.tb_conductores
        $$
    ) AS t (
        conductor_id integer,
        conductor_registro timestamp,
        conductor_estado text,
        fk_usuario_id integer,
        fk_personal_id integer,
        fk_licencia_id integer,
        conductor_licencia_emision date,
        conductor_licencia_validez date,
        conductor_pdf text
    )
    ON CONFLICT DO NOTHING;

    PERFORM setval(pg_get_serial_sequence('tthh.tb_conductores', 'conductor_id'), (SELECT MAX(conductor_id) FROM tthh.tb_conductores));

    INSERT INTO operaciones.tb_pelotones (
        peloton_id,
        peloton_registro,
        peloton_estado,
        fk_usuario_id,
        fk_estacion_id,
        peloton_nombre
    )
    SELECT 
        peloton_id,
        peloton_registro,
        peloton_estado,
        fk_usuario_id,
        fk_estacion_id,
        peloton_nombre
    FROM dblink('legacy',
        $$
        SELECT 
            peloton_id,
            peloton_registro,
            peloton_estado,
            fk_usuario_id,
            fk_estacion_id,
            peloton_nombre
        FROM tthh.tb_pelotones
        $$
    ) AS t (
        peloton_id integer,
        peloton_registro timestamp,
        peloton_estado text,
        fk_usuario_id integer,
        fk_estacion_id integer,
        peloton_nombre text
    )
    ON CONFLICT DO NOTHING;

    PERFORM setval(pg_get_serial_sequence('operaciones.tb_pelotones', 'peloton_id'), (SELECT MAX(peloton_id) FROM operaciones.tb_pelotones));

    INSERT INTO resources.countries (
        country_id,
        country_sortname,
        country_name,
        country_nombre,
        country_gentilicio,
        country_iso3
    )
    SELECT 
        country_id,
        country_sortname,
        country_name,
        country_nombre,
        country_gentilicio,
        country_iso3
    FROM dblink('legacy',
        $$
        SELECT 
            country_id,
            country_sortname,
            country_name,
            country_nombre,
            country_gentilicio,
            country_iso3
        FROM resources.countries
        $$
    ) AS t (
        country_id integer,
        country_sortname character varying(3),
        country_name text,
        country_nombre text,
        country_gentilicio text,
        country_iso3 text
    )
    ON CONFLICT DO NOTHING;

    PERFORM setval(
        pg_get_serial_sequence('resources.countries', 'country_id'),
        (SELECT MAX(country_id) FROM resources.countries)
    );

    INSERT INTO resources.states (
        state_id,
        state_name,
        fk_country_id
    )
    SELECT 
        state_id,
        state_name,
        fk_country_id
    FROM dblink('legacy',
        $$
        SELECT 
            state_id,
            state_name,
            fk_country_id
        FROM resources.states
        $$
    ) AS t (
        state_id integer,
        state_name text,
        fk_country_id integer
    )
    ON CONFLICT DO NOTHING;

    PERFORM setval(
        pg_get_serial_sequence('resources.states', 'state_id'),
        (SELECT MAX(state_id) FROM resources.states)
    );

    INSERT INTO resources.towns (
        town_id,
        town_name,
        fk_state_id
    )
    SELECT 
        town_id,
        town_name,
        fk_state_id
    FROM dblink('legacy',
        $$
        SELECT 
            town_id,
            town_name,
            fk_state_id
        FROM resources.towns
        $$
    ) AS t (
        town_id integer,
        town_name text,
        fk_state_id integer
    )
    ON CONFLICT DO NOTHING;

    PERFORM setval(
        pg_get_serial_sequence('resources.towns', 'town_id'),
        (SELECT MAX(town_id) FROM resources.towns)
    );

    INSERT INTO resources.parishes (
        parish_id,
        parish_name,
        fk_town_id
    )
    SELECT 
        parish_id,
        parish_name,
        fk_town_id
    FROM dblink('legacy',
        $$
        SELECT 
            parish_id,
            parish_name,
            fk_town_id
        FROM resources.parishes
        $$
    ) AS t (
        parish_id integer,
        parish_name text,
        fk_town_id integer
    )
    ON CONFLICT DO NOTHING;

    PERFORM setval(
        pg_get_serial_sequence('resources.parishes', 'parish_id'),
        (SELECT MAX(parish_id) FROM resources.parishes)
    );

    INSERT INTO resources.cie (
        cie_id,
        cie_codigo,
        cie_simbolo,
        cie_descripcion,
        cie_sexo,
        cie_limite_inferior,
        cie_limite_superior,
        cie_no_afeccion,
        cie_observacion
    )
    SELECT
        cie_id,
        cie_codigo,
        cie_simbolo,
        cie_descripcion,
        cie_sexo,
        cie_limite_inferior,
        cie_limite_superior,
        cie_no_afeccion,
        cie_observacion
    FROM dblink('legacy',
        $$
        SELECT
            cie_id,
            cie_codigo,
            cie_simbolo,
            cie_descripcion,
            cie_sexo,
            cie_limite_inferior,
            cie_limite_superior,
            cie_no_afeccion,
            cie_observacion
        FROM resources.cie
        $$
    ) AS t (
        cie_id integer,
        cie_codigo text,
        cie_simbolo text,
        cie_descripcion text,
        cie_sexo text,
        cie_limite_inferior text,
        cie_limite_superior text,
        cie_no_afeccion text,
        cie_observacion text
    )
    ON CONFLICT DO NOTHING;

    PERFORM setval(
        pg_get_serial_sequence('resources.cie', 'cie_id'),
        (SELECT MAX(cie_id) FROM resources.cie)
    );

    -- Mantenimiento vehicular


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
-- 12. REGISTRO INICIAL DE LA INSTITUCIÓN Y USUARIO ADMINISTRADOR (solo si no se importaron ni existen)
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
-- Base nueva sin usuarios: perfil Administrador y usuario "admin" (la clave del script anterior; se pide cambiarla al entrar)
INSERT INTO admin.tb_perfiles (perfil_nombre, perfil_descripcion)
SELECT 'Administrador', 'Administrador del Sistema'
 WHERE NOT EXISTS (SELECT 1 FROM admin.tb_usuarios)
   AND NOT EXISTS (SELECT 1 FROM admin.tb_perfiles WHERE upper(trim(perfil_nombre)) = 'ADMINISTRADOR');
INSERT INTO resources.tb_personas (persona_doc_identidad, persona_nombres, persona_apellidos)
SELECT '9999999999', 'ADMINISTRADOR', 'ADMINISTRADOR'
 WHERE NOT EXISTS (SELECT 1 FROM admin.tb_usuarios)
   AND NOT EXISTS (SELECT 1 FROM resources.tb_personas WHERE persona_doc_identidad = '9999999999');
INSERT INTO admin.tb_usuarios (fk_persona_id, fk_perfil_id, usuario_login, usuario_pass, usuario_cambiar_pass)
SELECT (SELECT persona_id FROM resources.tb_personas WHERE persona_doc_identidad = '9999999999' ORDER BY persona_id LIMIT 1),
       (SELECT perfil_id FROM admin.tb_perfiles WHERE upper(trim(perfil_nombre)) = 'ADMINISTRADOR' ORDER BY perfil_id LIMIT 1),
       'admin', '$2y$10$C64q4N9kT3MqHUyzmqjpIe2x8/GGYSgIK2ZjDmthuP2NasZqazLxO', true
 WHERE NOT EXISTS (SELECT 1 FROM admin.tb_usuarios);


-- ======================================================================================================
-- 13. MENÚ ORDENADO Y AGRUPADO (Panel, Parámetros, Gestión...), privilegio APH y pantallas en desuso
-- ======================================================================================================
-- =============================================================================
-- MENÚ ORDENADO Y AGRUPADO - re-ejecutable (va después de todas las migraciones que crean privilegios)
-- Módulo -> submódulo (grupo del menú) -> pantalla. Cada institución puede ajustar el orden y los grupos en la base:
--   admin.tb_modulos.modulo_orden, admin.tb_submodulos.submodulo_orden / submodulo_menu ('GRUPO' carpeta | 'DIRECTO' sin
--   carpeta), admin.tb_roles.rol_orden / rol_menu (texto corto en el menú; el nombre completo queda en Privilegios).
-- Un grupo con una sola pantalla visible, o un módulo con un solo grupo, se muestra sin carpeta.
-- Este script solo completa valores por defecto: no cambia lo que la institución ya haya ajustado
-- (orden distinto de 100, etiqueta escrita, privilegio movido a otro submódulo, pantalla reactivada).
-- =============================================================================

-- 1. Columnas del menú
ALTER TABLE admin.tb_modulos ADD COLUMN IF NOT EXISTS modulo_orden integer NOT NULL DEFAULT 100;
ALTER TABLE admin.tb_submodulos ADD COLUMN IF NOT EXISTS submodulo_orden integer NOT NULL DEFAULT 100;
ALTER TABLE admin.tb_submodulos ADD COLUMN IF NOT EXISTS submodulo_menu text NOT NULL DEFAULT 'GRUPO';
ALTER TABLE admin.tb_roles ADD COLUMN IF NOT EXISTS rol_orden integer NOT NULL DEFAULT 100;
ALTER TABLE admin.tb_roles ADD COLUMN IF NOT EXISTS rol_menu text;
ALTER TABLE admin.tb_roles ADD COLUMN IF NOT EXISTS rol_estado text;

-- 2. Orden de los módulos
UPDATE admin.tb_modulos m SET modulo_orden = v.orden
  FROM (VALUES ('Dir. Administrativa', 10), ('Operaciones', 20), ('Subjefatura', 30), ('Archivo', 40), ('Administración', 90)) AS v(nombre, orden)
 WHERE m.modulo_nombre = v.nombre AND m.modulo_orden = 100;

-- 3. Grupos (submódulos) nuevos, buscados por módulo y nombre
INSERT INTO admin.tb_submodulos (fk_modulo_id, submodulo_nombre, submodulo_descripcion)
SELECT m.modulo_id, v.nombre, v.descripcion
  FROM (VALUES ('Dir. Administrativa', 'Panel', 'Resumen para la dirección'),
               ('Dir. Administrativa', 'Parámetros', 'Vehículos, operadores, planes y contratos de mantenimiento'),
               ('Dir. Administrativa', 'Gestión', 'Órdenes, informes y peticiones'),
               ('Operaciones', 'Panel', 'Estadística de partes de servicio'),
               ('Subjefatura', 'Panel', 'Estadística de emergencias'),
               ('Subjefatura', 'Atención prehospitalaria', 'Hojas de ruta APH (atenciones del personal paramédico)')) AS v(modulo, nombre, descripcion)
  JOIN admin.tb_modulos m ON m.modulo_nombre = v.modulo
 WHERE NOT EXISTS (SELECT 1 FROM admin.tb_submodulos s WHERE s.fk_modulo_id = m.modulo_id AND s.submodulo_nombre = v.nombre);

UPDATE admin.tb_submodulos s SET submodulo_orden = v.orden, submodulo_menu = v.menu
  FROM (VALUES ('Dir. Administrativa', 'Panel', 10, 'DIRECTO'), ('Dir. Administrativa', 'Parámetros', 20, 'GRUPO'),
               ('Dir. Administrativa', 'Gestión', 30, 'GRUPO'),
               ('Operaciones', 'Panel', 10, 'DIRECTO'), ('Operaciones', 'Partes de servicio', 20, 'GRUPO'),
               ('Operaciones', 'Distributivo', 30, 'GRUPO'),
               ('Subjefatura', 'Panel', 10, 'DIRECTO'), ('Subjefatura', 'Atención prehospitalaria', 20, 'GRUPO'),
               ('Subjefatura', 'Voluntarios', 30, 'GRUPO')) AS v(modulo, nombre, orden, menu)
  JOIN admin.tb_modulos m ON m.modulo_nombre = v.modulo
 WHERE s.fk_modulo_id = m.modulo_id AND s.submodulo_nombre = v.nombre AND s.submodulo_orden = 100;

-- 4. Privilegio nuevo: Hojas de ruta APH (Subjefatura > Atención prehospitalaria)
INSERT INTO admin.tb_roles (rol_nombre, rol_descripcion, fk_submodulo_id, rol_path, rol_codigo)
SELECT 'Hojas de ruta APH', 'Registro de atenciones prehospitalarias (hoja de ruta)', s.submodulo_id, '/sbj/aph-hojas', 'SBJ_APH_HOJAS'
  FROM admin.tb_submodulos s JOIN admin.tb_modulos m ON m.modulo_id = s.fk_modulo_id
 WHERE m.modulo_nombre = 'Subjefatura' AND s.submodulo_nombre = 'Atención prehospitalaria'
   AND NOT EXISTS (SELECT 1 FROM admin.tb_roles r WHERE r.rol_codigo = 'SBJ_APH_HOJAS' OR r.rol_path = '/sbj/aph-hojas');
UPDATE admin.tb_roles SET rol_codigo = 'SBJ_APH_HOJAS'
 WHERE rol_path = '/sbj/aph-hojas' AND rol_codigo IS NULL AND NOT EXISTS (SELECT 1 FROM admin.tb_roles y WHERE y.rol_codigo = 'SBJ_APH_HOJAS');
-- Asignación inicial: administradores y quienes registraban intervenciones
INSERT INTO admin.tb_usuario_rol (fk_usuario_id, fk_rol_id)
SELECT DISTINCT u.usuario_id, a.rol_id
  FROM admin.tb_usuarios u JOIN admin.tb_roles a ON a.rol_codigo = 'SBJ_APH_HOJAS'
 WHERE (admin.fn_es_administrador(u.usuario_id)
        OR EXISTS (SELECT 1 FROM admin.tb_usuario_rol ur JOIN admin.tb_roles r ON r.rol_id = ur.fk_rol_id
                    WHERE ur.fk_usuario_id = u.usuario_id AND r.rol_codigo = 'SBJ_INTERVENCIONES'))
   AND NOT EXISTS (SELECT 1 FROM admin.tb_usuario_rol x WHERE x.fk_usuario_id = u.usuario_id AND x.fk_rol_id = a.rol_id);

-- 5. Cada pantalla y acción en su grupo, con su orden y su texto en el menú.
--    Solo se mueve si sigue en su submódulo de origen (no se deshace lo que la institución haya reubicado).
DO $menu$
BEGIN
    CREATE TEMP TABLE tmp_menu (codigo text, modulo text, grupo text, orden integer, menu text, nombre text, origen text[]) ON COMMIT DROP;
    INSERT INTO tmp_menu VALUES
        -- Dirección Administrativa
        ('ADM_DASHBOARD', 'Dir. Administrativa', 'Panel', 10, 'Panel', 'Resumen gerencial', '{Servicios generales}'),
        ('ADM_VEHICULOS', 'Dir. Administrativa', 'Parámetros', 10, 'Vehículos', 'Vehículos', '{Unidades}'),
        ('ADM_VEHICULO_CREAR', 'Dir. Administrativa', 'Parámetros', 11, NULL, NULL, '{Unidades}'),
        ('ADM_BITACORA_VEHICULOS', 'Dir. Administrativa', 'Parámetros', 20, 'Bitácora de vehículos', 'Bitácora de vehículos', '{Unidades}'),
        ('ADM_OPERADORES', 'Dir. Administrativa', 'Parámetros', 30, 'Operadores', NULL, '{Operadores}'),
        ('ADM_OPERADOR_GESTIONAR', 'Dir. Administrativa', 'Parámetros', 31, NULL, NULL, '{Operadores}'),
        ('MANT_PLANES', 'Dir. Administrativa', 'Parámetros', 40, 'Planes de mantenimiento', 'Planes de mantenimiento', '{Mantenimiento vehicular}'),
        ('MANT_PLAN_GESTIONAR', 'Dir. Administrativa', 'Parámetros', 41, NULL, NULL, '{Mantenimiento vehicular}'),
        ('MANT_CONTRATOS', 'Dir. Administrativa', 'Parámetros', 50, 'Contratos de mantenimiento', 'Contratos de mantenimiento', '{Mantenimiento vehicular}'),
        ('MANT_CONTRATO_GESTIONAR', 'Dir. Administrativa', 'Parámetros', 51, NULL, NULL, '{Mantenimiento vehicular}'),
        ('ADM_MOVILIZACION', 'Dir. Administrativa', 'Gestión', 10, 'Órdenes de movilización', 'Órdenes de movilización', '{Ordenes de movilización}'),
        ('ADM_MOVILIZACION_CREAR', 'Dir. Administrativa', 'Gestión', 11, NULL, NULL, '{Ordenes de movilización}'),
        ('ADM_COMBUSTIBLE', 'Dir. Administrativa', 'Gestión', 20, 'Órdenes de combustible', 'Órdenes de combustible', '{Ordenes de combustible}'),
        ('ADM_COMBUSTIBLE_CREAR', 'Dir. Administrativa', 'Gestión', 21, NULL, NULL, '{Ordenes de combustible}'),
        ('MANT_ORDENES', 'Dir. Administrativa', 'Gestión', 30, 'Órdenes de mantenimiento', 'Órdenes de mantenimiento', '{Mantenimiento vehicular}'),
        ('MANT_ORDEN_CREAR', 'Dir. Administrativa', 'Gestión', 31, NULL, NULL, '{Mantenimiento vehicular}'),
        ('MANT_ORDEN_RECIBIR', 'Dir. Administrativa', 'Gestión', 32, NULL, NULL, '{Mantenimiento vehicular}'),
        ('MANT_ORDEN_ACTA', 'Dir. Administrativa', 'Gestión', 33, NULL, NULL, '{Mantenimiento vehicular}'),
        ('MANT_ORDEN_ANULAR', 'Dir. Administrativa', 'Gestión', 34, NULL, NULL, '{Mantenimiento vehicular}'),
        ('MANT_BITACORAS', 'Dir. Administrativa', 'Gestión', 40, 'Informes de mantenimiento', 'Informes de mantenimiento', '{Mantenimiento vehicular}'),
        ('MANT_BITACORA_GESTIONAR', 'Dir. Administrativa', 'Gestión', 41, NULL, NULL, '{Mantenimiento vehicular}'),
        ('ADM_PETICIONES_MATERIALES', 'Dir. Administrativa', 'Gestión', 50, 'Peticiones de materiales', NULL, '{Servicios generales}'),
        ('ADM_PETICION_MATERIALES_GESTIONAR', 'Dir. Administrativa', 'Gestión', 51, NULL, NULL, '{Servicios generales}'),
        -- Operaciones
        ('OPE_PARTES_ESTADISTICAS', 'Operaciones', 'Panel', 10, 'Panel', 'Estadística de partes', '{Partes de servicio}'),
        ('OPE_PARTES', 'Operaciones', 'Partes de servicio', 10, 'Partes de servicio', NULL, '{Partes de servicio}'),
        ('OPE_PARTE_REGISTRAR', 'Operaciones', 'Partes de servicio', 11, NULL, NULL, '{Partes de servicio}'),
        ('OPE_PARTE_ANULAR', 'Operaciones', 'Partes de servicio', 12, NULL, NULL, '{Partes de servicio}'),
        ('OPE_DISTRIBUTIVO', 'Operaciones', 'Distributivo', 10, 'Distributivo', NULL, '{Distributivo}'),
        -- Subjefatura
        ('SBJ_ESTADISTICAS', 'Subjefatura', 'Panel', 10, 'Panel', 'Estadística de emergencias', '{Parámetros}'),
        ('SBJ_APH_HOJAS', 'Subjefatura', 'Atención prehospitalaria', 10, 'Hojas de ruta APH', NULL, '{Atención prehospitalaria}'),
        ('SBJ_VOLUNTARIOS', 'Subjefatura', 'Voluntarios', 10, 'Voluntarios', NULL, '{Voluntarios}'),
        ('SBJ_UBV_ACTIVIDADES', 'Subjefatura', 'Voluntarios', 20, 'Actividades', 'Actividades de voluntarios', '{Voluntarios}'),
        ('SBJ_UBV_EVENTOS', 'Subjefatura', 'Voluntarios', 30, 'Eventos', 'Eventos de voluntarios', '{Voluntarios}'),
        -- Administración del sistema
        ('SIS_USUARIOS', 'Administración', 'Usuarios y perfiles', 10, 'Usuarios', NULL, '{Usuarios y perfiles}'),
        ('SIS_PERFILES', 'Administración', 'Usuarios y perfiles', 20, 'Perfiles', NULL, '{Usuarios y perfiles}');

    UPDATE admin.tb_roles r SET fk_submodulo_id = destino.submodulo_id
      FROM tmp_menu t
      JOIN admin.tb_modulos m ON m.modulo_nombre = t.modulo
      JOIN admin.tb_submodulos destino ON destino.fk_modulo_id = m.modulo_id AND destino.submodulo_nombre = t.grupo
     WHERE r.rol_codigo = t.codigo AND r.fk_submodulo_id <> destino.submodulo_id
       AND (SELECT s.submodulo_nombre FROM admin.tb_submodulos s WHERE s.submodulo_id = r.fk_submodulo_id) = ANY (t.origen);
    UPDATE admin.tb_roles r SET rol_orden = t.orden FROM tmp_menu t WHERE r.rol_codigo = t.codigo AND r.rol_orden = 100;
    UPDATE admin.tb_roles r SET rol_menu = t.menu FROM tmp_menu t WHERE r.rol_codigo = t.codigo AND r.rol_menu IS NULL AND t.menu IS NOT NULL;
    -- Nombres completos con tildes (solo si conservan el nombre original sin tildes)
    UPDATE admin.tb_roles r SET rol_nombre = t.nombre FROM tmp_menu t
     WHERE r.rol_codigo = t.codigo AND t.nombre IS NOT NULL AND r.rol_nombre <> t.nombre
       AND lower(translate(r.rol_nombre, 'áéíóúÁÉÍÓÚ', 'aeiouAEIOU')) IN (lower(translate(t.nombre, 'áéíóúÁÉÍÓÚ', 'aeiouAEIOU')), 'resumen gerencial',
                                                                             'estadisticas', 'estadistica de partes', 'ubv actividades', 'ubv eventos');
END
$menu$;

-- 6. Pantallas en desuso: Intervenciones (reemplazada por los partes de servicio) y Ausencias (sin pantalla en el sistema).
--    Solo si nunca se cambió su estado: para volver a usarlas, rol_estado = 'ACTIVO'.
UPDATE admin.tb_roles SET rol_estado = 'INACTIVO'
 WHERE rol_codigo IN ('SBJ_INTERVENCIONES', 'SBJ_AUSENCIAS') AND rol_estado IS NULL;


-- ======================================================================================================
-- 14. ACCESO DE LOS ADMINISTRADORES (todos los privilegios; parámetros SIS_ADMINISTRADORES y SIS_PERFILES_ADMINISTRADOR)
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

-- 4. Resultado: administradores, su estado y cuántos privilegios efectivos tienen (debe ser el total de privilegios en uso)
SELECT u.usuario_id, u.usuario_login, COALESCE(u.usuario_estado, 'ACTIVO') AS estado, pf.perfil_nombre,
       (SELECT count(DISTINCT v.rol_id) FROM admin.vw_usuario_privilegios v WHERE v.usuario_id = u.usuario_id) AS privilegios,
       (SELECT count(*) FROM admin.tb_roles r WHERE r.rol_estado IS DISTINCT FROM 'INACTIVO') AS total_privilegios
  FROM admin.tb_usuarios u LEFT JOIN admin.tb_perfiles pf ON pf.perfil_id = u.fk_perfil_id
 WHERE admin.fn_es_administrador(u.usuario_id)
 ORDER BY u.usuario_id;
