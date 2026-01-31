-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CREACION DE SCHEMAS
CREATE SCHEMA IF NOT EXISTS admin AUTHORIZATION postgres;
CREATE SCHEMA IF NOT EXISTS administrativo AUTHORIZATION postgres;
CREATE SCHEMA IF NOT EXISTS resources AUTHORIZATION postgres;
CREATE SCHEMA IF NOT EXISTS operaciones AUTHORIZATION postgres;
CREATE SCHEMA IF NOT EXISTS tthh AUTHORIZATION postgres;
CREATE SCHEMA IF NOT EXISTS logistica AUTHORIZATION postgres;

-- FIN CREACION DE SCHEMAS
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CREACION DE TABLAS
DROP TABLE IF EXISTS resources.tb_personas CASCADE;
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
) WITH (OIDS = FALSE) TABLESPACE pg_default;

DROP TABLE IF EXISTS resources.countries CASCADE;
CREATE TABLE IF NOT EXISTS resources.countries
(
    country_id SERIAL NOT NULL PRIMARY KEY,
    country_sortname character varying(3) COLLATE pg_catalog."default" NOT NULL,
    country_name text COLLATE pg_catalog."default" NOT NULL,
    country_nombre text COLLATE pg_catalog."default",
    country_gentilicio text COLLATE pg_catalog."default",
    country_iso3 text COLLATE pg_catalog."default"
);

DROP TABLE IF EXISTS resources.states CASCADE;
CREATE TABLE IF NOT EXISTS resources.states
(
    state_id SERIAL NOT NULL PRIMARY KEY,
    state_name text COLLATE pg_catalog."default" NOT NULL,
    fk_country_id integer NOT NULL REFERENCES resources.countries(country_id)
);

DROP TABLE IF EXISTS resources.towns CASCADE;
CREATE TABLE IF NOT EXISTS resources.towns
(
    town_id SERIAL NOT NULL PRIMARY KEY,
    town_name text COLLATE pg_catalog."default" NOT NULL,
    fk_state_id integer NOT NULL REFERENCES resources.states(state_id) 
);

DROP TABLE IF EXISTS resources.parishes CASCADE;
CREATE TABLE IF NOT EXISTS resources.parishes
(
    parish_id SERIAL NOT NULL PRIMARY KEY,
    parish_name text COLLATE pg_catalog."default" NOT NULL,
    fk_town_id integer NOT NULL REFERENCES resources.towns(town_id)
);

DROP TABLE IF EXISTS resources.cie CASCADE;
CREATE TABLE IF NOT EXISTS resources.cie
(
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

DROP TABLE IF EXISTS resources.tb_licenciasdeconducir CASCADE;
CREATE TABLE IF NOT EXISTS resources.tb_licenciasdeconducir (
    licencia_id SERIAL NOT NULL PRIMARY KEY,
    licencia_estado text COLLATE pg_catalog."default" DEFAULT 'ACTIVO'::text,
    licencia_registro timestamp without time zone DEFAULT ('now'::text)::timestamp(0) with time zone,
    fk_usuario_id integer,
    licencia_tipo text COLLATE pg_catalog."default",
    licencia_categoria text COLLATE pg_catalog."default",
    licencia_descripcion text COLLATE pg_catalog."default"
) WITH (OIDS = FALSE) TABLESPACE pg_default;

DROP TABLE IF EXISTS admin.tb_modulos CASCADE;
CREATE TABLE IF NOT EXISTS admin.tb_modulos
(
    modulo_id SERIAL NOT NULL PRIMARY KEY,
    modulo_nombre text COLLATE pg_catalog."default" NOT NULL,
    modulo_descripcion text COLLATE pg_catalog."default"
);

DROP TABLE IF EXISTS admin.tb_submodulos CASCADE;
CREATE TABLE IF NOT EXISTS admin.tb_submodulos
(
    submodulo_id SERIAL NOT NULL PRIMARY KEY,
    fk_modulo_id integer NOT NULL REFERENCES admin.tb_modulos(modulo_id),
    submodulo_nombre text COLLATE pg_catalog."default" NOT NULL,
    submodulo_descripcion text COLLATE pg_catalog."default"
);

DROP TABLE IF EXISTS admin.tb_roles CASCADE;
CREATE TABLE IF NOT EXISTS admin.tb_roles
(
    rol_id SERIAL NOT NULL PRIMARY KEY,
    rol_nombre text COLLATE pg_catalog."default" NOT NULL,
    rol_descripcion text COLLATE pg_catalog."default",
    fk_submodulo_id integer NOT NULL REFERENCES admin.tb_submodulos(submodulo_id),
    rol_path text COLLATE pg_catalog."default"
);

DROP TABLE IF EXISTS admin.tb_perfiles CASCADE;
CREATE TABLE IF NOT EXISTS admin.tb_perfiles (
    perfil_id SERIAL NOT NULL PRIMARY KEY,
    perfil_nombre text COLLATE pg_catalog."default" NOT NULL,
    perfil_descripcion text COLLATE pg_catalog."default",
    perfil_estado text COLLATE pg_catalog."default" DEFAULT 'ACTIVO' :: text
) WITH (OIDS = FALSE) TABLESPACE pg_default;

DROP TABLE IF EXISTS admin.tb_usuarios CASCADE;
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
    usuario_fingreso timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0)
) WITH (OIDS = FALSE) TABLESPACE pg_default;

DROP TABLE IF EXISTS admin.tb_usuario_rol CASCADE;
CREATE TABLE IF NOT EXISTS admin.tb_usuario_rol
(
    fk_usuario_id integer NOT NULL,
    fk_rol_id integer NOT NULL
);

DROP TABLE IF EXISTS administrativo.tb_vehiculos_marcas CASCADE;
CREATE TABLE IF NOT EXISTS administrativo.tb_vehiculos_marcas (
    marca_id SERIAL NOT NULL PRIMARY KEY,
    marca_nombre text COLLATE pg_catalog."default" NOT NULL,
    marca_estado text COLLATE pg_catalog."default" DEFAULT 'ACTIVO' :: text
) WITH (OIDS = FALSE) TABLESPACE pg_default;

DROP TABLE IF EXISTS operaciones.tb_estaciones CASCADE;

CREATE TABLE IF NOT EXISTS operaciones.tb_estaciones (
    estacion_id SERIAL NOT NULL PRIMARY KEY,
    estacion_nombre text COLLATE pg_catalog."default" NOT NULL,
    estacion_ubicacion_x text COLLATE pg_catalog."default",
    estacion_ubicacion_y text COLLATE pg_catalog."default",
    estacion_estado text COLLATE pg_catalog."default" DEFAULT 'ACTIVO' :: text
) WITH (OIDS = FALSE) TABLESPACE pg_default;

DROP TABLE IF EXISTS administrativo.tb_vehiculos CASCADE;
CREATE TABLE IF NOT EXISTS administrativo.tb_vehiculos (
    vehiculo_id SERIAL NOT NULL PRIMARY KEY,
    fk_usuario_id integer REFERENCES admin.tb_usuarios(usuario_id) NOT NULL,
    fk_estacion_id integer REFERENCES operaciones.tb_estaciones(estacion_id) NOT NULL,
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
) WITH (OIDS = FALSE) TABLESPACE pg_default;

DROP TABLE IF EXISTS tthh.tb_personal CASCADE;
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
) WITH (OIDS = FALSE) TABLESPACE pg_default;

DROP TABLE IF EXISTS tthh.tb_direcciones CASCADE;
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
) WITH (OIDS = FALSE) TABLESPACE pg_default;

DROP TABLE IF EXISTS tthh.tb_grupos CASCADE;
CREATE TABLE IF NOT EXISTS tthh.tb_grupos (
    grupo_id SERIAL NOT NULL PRIMARY KEY,
    grupo_registro timestamp without time zone DEFAULT ('now' :: text) :: timestamp(0) with time zone,
    grupo_estado text COLLATE pg_catalog."default" DEFAULT 'ACTIVO' :: text,
    fk_usuario_id integer,
    grupo_nombre text COLLATE pg_catalog."default" NOT NULL,
    grupo_grado text COLLATE pg_catalog."default" NOT NULL,
    grupo_salario_sri numeric(8, 2) NOT NULL,
    grupo_salario_interno numeric(8, 2) DEFAULT 0
) WITH (OIDS = FALSE) TABLESPACE pg_default;

DROP TABLE IF EXISTS tthh.tb_puestos CASCADE;
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
) WITH (OIDS = FALSE) TABLESPACE pg_default;

DROP TABLE IF EXISTS tthh.tb_personal_puestos CASCADE;
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
) WITH (OIDS = FALSE) TABLESPACE pg_default;

DROP TABLE IF EXISTS tthh.tb_conductores CASCADE;
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
) WITH (OIDS = FALSE) TABLESPACE pg_default;

DROP TABLE IF EXISTS operaciones.tb_distributivo CASCADE;
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
) WITH (OIDS = FALSE) TABLESPACE pg_default;


DROP TABLE IF EXISTS operaciones.tb_pelotones CASCADE;
CREATE TABLE IF NOT EXISTS operaciones.tb_pelotones (
    peloton_id SERIAL NOT NULL PRIMARY KEY,
    peloton_registro timestamp without time zone DEFAULT ('now'::text)::timestamp(0) with time zone,
    peloton_estado text COLLATE pg_catalog."default" DEFAULT 'ACTIVO'::text,
    fk_usuario_id integer,
    fk_estacion_id integer NOT NULL,
    peloton_nombre text COLLATE pg_catalog."default"
) WITH (OIDS = FALSE) TABLESPACE pg_default;

DROP TABLE IF EXISTS operaciones.tb_distributivo_peloton CASCADE;
CREATE TABLE IF NOT EXISTS operaciones.tb_distributivo_peloton (
    dist_pelo_id SERIAL NOT NULL PRIMARY KEY,
    fk_peloton_id integer NOT NULL,
    fk_distributivo_id integer NOT NULL
) WITH (OIDS = FALSE) TABLESPACE pg_default;

DROP TABLE IF EXISTS operaciones.tb_tropas CASCADE;
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
) WITH (OIDS = FALSE) TABLESPACE pg_default;

DROP TABLE IF EXISTS logistica.tb_ordenesmovilizacion CASCADE;
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
) WITH (OIDS = FALSE) TABLESPACE pg_default;

-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- SCRIPTS INICIALES
-- INSERT INTO
--     admin.tb_perfiles(perfil_id, perfil_nombre, perfil_descripcion)
-- VALUES
--     (1, 'Administrador', 'Administrador del Sistema');

-- INSERT INTO
--     resources.tb_personas(
--         persona_doc_identidad,persona_nombres,persona_apellidos
--     )
-- VALUES
--     (
--         '9999999999','ADMINISTRADOR','ADMINISTRADOR'
--     );

-- INSERT INTO
--     admin.tb_usuarios(usuario_id,fk_persona_id,fk_perfil_id,usuario_login,usuario_pass
--     )
-- VALUES
--     (1, 1, 1, 'admin', '$2y$10$C64q4N9kT3MqHUyzmqjpIe2x8/GGYSgIK2ZjDmthuP2NasZqazLxO');

INSERT INTO admin.tb_modulos (modulo_nombre) VALUES ('ROOT');
INSERT INTO admin.tb_modulos (modulo_nombre) VALUES ('DIRECCIÓN ADMINISTRATIVA');
INSERT INTO admin.tb_modulos (modulo_nombre) VALUES ('SUBJEFATURA');
INSERT INTO admin.tb_modulos (modulo_nombre) VALUES ('SCI');
INSERT INTO admin.tb_modulos (modulo_nombre) VALUES ('OPERACIONES');

--DIRECCIÓN ADMINISTRATIVA
INSERT INTO admin.tb_submodulos (fk_modulo_id, submodulo_nombre) VALUES (2, 'UNIDADES');
INSERT INTO admin.tb_submodulos (fk_modulo_id, submodulo_nombre) VALUES (2, 'ORDENES DE MOVILIZACIÓN');

--SUBJEFATURA
INSERT INTO admin.tb_submodulos (fk_modulo_id, submodulo_nombre) VALUES (3, 'PARÁMETROS');
INSERT INTO admin.tb_submodulos (fk_modulo_id, submodulo_nombre) VALUES (3, 'INTERVENCIONES');

--OPERACIONES
INSERT INTO admin.tb_submodulos (fk_modulo_id, submodulo_nombre) VALUES (5, 'DISTRIBUTIVO');
INSERT INTO admin.tb_submodulos (fk_modulo_id, submodulo_nombre) VALUES (5, 'PARTES DE SERVICIO');

--DIRECCIÓN ADMINISTRATIVA
INSERT INTO admin.tb_roles (rol_nombre, rol_descripcion, fk_submodulo_id, rol_path) VALUES ('Visualizar listado de vehiculos', 'Administrar vehiculos',1,'/admin/vehiculos');
INSERT INTO admin.tb_roles (rol_nombre, rol_descripcion, fk_submodulo_id, rol_path) VALUES ('Visualizar listado de ordenes', 'Administrar ordenes de movilizacion',2,'/admin/ordenes-movilizacion');
INSERT INTO admin.tb_roles (rol_nombre, rol_descripcion, fk_submodulo_id, rol_path) VALUES ('Ingresar nuevo vehiculo', 'Poder registrar nuevas unidades',1,null);

--SUBJEFATURA
INSERT INTO admin.tb_roles (rol_nombre, rol_descripcion, fk_submodulo_id, rol_path) VALUES ('Estadisticas', 'Estadisticas operaticas',3,'/sbj/dashboard');
INSERT INTO admin.tb_roles (rol_nombre, rol_descripcion, fk_submodulo_id, rol_path) VALUES ('Intervenciones', 'Administración de intervenciones de emergencias',4,'/sbj/intervenciones');
INSERT INTO admin.tb_roles (rol_nombre, rol_descripcion, fk_submodulo_id, rol_path) VALUES ('Ausencias', 'Registros de ausencias del presonal',3,'/sbj/ausencias');

--OPERACIONES
INSERT INTO admin.tb_roles (rol_nombre, rol_descripcion, fk_submodulo_id, rol_path) VALUES ('Visualizar listado de distributivos', 'Administrar distributivos de personal',5,'/ops/distributivos');
INSERT INTO admin.tb_roles (rol_nombre, rol_descripcion, fk_submodulo_id, rol_path) VALUES ('Visualizar listado de partes de servicio', 'Administrar partes de servicio',6,'/ops/partes-servicio');



INSERT INTO operaciones.tb_estaciones (estacion_nombre) VALUES ('X-1');
INSERT INTO operaciones.tb_estaciones (estacion_nombre) VALUES ('X-2');
INSERT INTO operaciones.tb_estaciones (estacion_nombre) VALUES ('X-3');
INSERT INTO operaciones.tb_estaciones (estacion_nombre) VALUES ('X-4');
INSERT INTO operaciones.tb_estaciones (estacion_nombre) VALUES ('X-5');
INSERT INTO operaciones.tb_estaciones (estacion_nombre) VALUES ('X-6');
INSERT INTO operaciones.tb_estaciones (estacion_nombre) VALUES ('X-7');
INSERT INTO operaciones.tb_estaciones (estacion_nombre) VALUES ('X-8');

INSERT INTO administrativo.tb_vehiculos_marcas (marca_nombre) VALUES ('S/M');

-- CREACIÓN DE VISTAS

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


CREATE EXTENSION IF NOT EXISTS dblink;


-- Migración completa de admin.tb_perfiles
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
FROM dblink(
    'dbname=db_cbsd_old user=postgres password=root host=localhost',
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
);
SELECT setval(pg_get_serial_sequence('admin.tb_perfiles', 'perfil_id'), (SELECT MAX(perfil_id) FROM admin.tb_perfiles));

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
FROM dblink(
    'dbname=db_cbsd_old user=postgres password=root host=localhost',
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
);

-- Ajustar la secuencia del SERIAL
SELECT setval(
    pg_get_serial_sequence('resources.cie', 'cie_id'),
    (SELECT MAX(cie_id) FROM resources.cie)
);

-- Migración completa de admin.tb_usuarios (versión actualizada)
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
FROM dblink(
    'dbname=db_cbsd_old user=postgres password=root host=localhost',
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
);
SELECT setval(pg_get_serial_sequence('admin.tb_usuarios', 'usuario_id'), (SELECT MAX(usuario_id) FROM admin.tb_usuarios));



-- Migración completa de administrativo.tb_vehiculos
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
FROM dblink(
    'dbname=db_cbsd_old user=postgres password=root host=localhost',
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
);
SELECT setval(pg_get_serial_sequence('administrativo.tb_vehiculos', 'vehiculo_id'), (SELECT MAX(vehiculo_id) FROM administrativo.tb_vehiculos));

CREATE EXTENSION IF NOT EXISTS dblink;
-- Migración completa de resources.countries
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
FROM dblink(
    'dbname=db_cbsd_old user=postgres password=root host=localhost',
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
);
-- Ajustar la secuencia para que siga desde el último ID insertado
SELECT setval(
    pg_get_serial_sequence('resources.countries', 'country_id'),
    (SELECT MAX(country_id) FROM resources.countries)
);

-- Migración completa de resources.states
INSERT INTO resources.states (
    state_id,
    state_name,
    fk_country_id
)
SELECT 
    state_id,
    state_name,
    fk_country_id
FROM dblink(
    'dbname=db_cbsd_old user=postgres password=root host=localhost',
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
);

-- Ajustar la secuencia para que continúe desde el último ID insertado
SELECT setval(
    pg_get_serial_sequence('resources.states', 'state_id'),
    (SELECT MAX(state_id) FROM resources.states)
);

-- Migración completa de resources.towns
INSERT INTO resources.towns (
    town_id,
    town_name,
    fk_state_id
)
SELECT 
    town_id,
    town_name,
    fk_state_id
FROM dblink(
    'dbname=db_cbsd_old user=postgres password=root host=localhost',
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
);

-- Ajustar la secuencia para que continúe desde el último ID insertado
SELECT setval(
    pg_get_serial_sequence('resources.towns', 'town_id'),
    (SELECT MAX(town_id) FROM resources.towns)
);

-- Migración completa de resources.parishes
INSERT INTO resources.parishes (
    parish_id,
    parish_name,
    fk_town_id
)
SELECT 
    parish_id,
    parish_name,
    fk_town_id
FROM dblink(
    'dbname=db_cbsd_old user=postgres password=root host=localhost',
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
);

-- Ajustar la secuencia para continuar desde el último ID insertado
SELECT setval(
    pg_get_serial_sequence('resources.parishes', 'parish_id'),
    (SELECT MAX(parish_id) FROM resources.parishes)
);


CREATE EXTENSION IF NOT EXISTS dblink;
-- Migración completa de resources.tb_personas
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
FROM dblink(
    'dbname=db_cbsd_old user=postgres password=root host=localhost',
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
);
SELECT setval(pg_get_serial_sequence('resources.tb_personas', 'persona_id'), (SELECT MAX(persona_id) FROM resources.tb_personas));



CREATE EXTENSION IF NOT EXISTS dblink;
-- Migración completa de tthh.tb_personal_puestos
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
FROM dblink(
    'dbname=db_cbsd_old user=postgres password=root host=localhost',
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
);
SELECT setval(pg_get_serial_sequence('tthh.tb_personal_puestos', 'ppersonal_id'), (SELECT MAX(ppersonal_id) FROM tthh.tb_personal_puestos));



-- Migración completa de tthh.tb_direcciones
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
FROM dblink(
    'dbname=db_cbsd_old user=postgres password=root host=localhost',
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
);
SELECT setval(pg_get_serial_sequence('tthh.tb_direcciones', 'direccion_id'), (SELECT MAX(direccion_id) FROM tthh.tb_direcciones));



-- Migración completa de tthh.tb_puestos
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
FROM dblink(
    'dbname=db_cbsd_old user=postgres password=root host=localhost',
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
);
SELECT setval(pg_get_serial_sequence('tthh.tb_puestos', 'puesto_id'), (SELECT MAX(puesto_id) FROM tthh.tb_puestos));



-- Migración completa de operaciones.tb_pelotones
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
FROM dblink(
    'dbname=db_cbsd_old user=postgres password=root host=localhost',
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
);
SELECT setval(pg_get_serial_sequence('operaciones.tb_pelotones', 'peloton_id'), (SELECT MAX(peloton_id) FROM operaciones.tb_pelotones));



-- Migración completa de resources.tb_licenciasdeconducir
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
FROM dblink(
    'dbname=db_cbsd_old user=postgres password=root host=localhost',
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
);
SELECT setval(pg_get_serial_sequence('resources.tb_licenciasdeconducir', 'licencia_id'), (SELECT MAX(licencia_id) FROM resources.tb_licenciasdeconducir));



-- Migración completa de tthh.tb_conductores
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
FROM dblink(
    'dbname=db_cbsd_old user=postgres password=root host=localhost',
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
);
SELECT setval(pg_get_serial_sequence('tthh.tb_conductores', 'conductor_id'), (SELECT MAX(conductor_id) FROM tthh.tb_conductores));


-- Migración completa de tthh.tb_personal
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
FROM dblink(
    'dbname=db_cbsd_old user=postgres password=root host=localhost',
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
);

SELECT setval(pg_get_serial_sequence('tthh.tb_personal', 'personal_id'), (SELECT MAX(personal_id) FROM tthh.tb_personal));



