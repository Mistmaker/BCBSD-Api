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
    vehiculo_sigla text COLLATE pg_catalog."default"
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
    tecnico_servicios integer NOT NULL,
    orden_codigo text COLLATE pg_catalog."default" NOT NULL,
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
INSERT INTO
    admin.tb_perfiles(perfil_id, perfil_nombre, perfil_descripcion)
VALUES
    (1, 'Administrador', 'Administrador del Sistema');

INSERT INTO
    resources.tb_personas(
        persona_doc_identidad,persona_nombres,persona_apellidos
    )
VALUES
    (
        '9999999999','ADMINISTRADOR','ADMINISTRADOR'
    );

INSERT INTO
    admin.tb_usuarios(usuario_id,fk_persona_id,fk_perfil_id,usuario_login,usuario_pass
    )
VALUES
    (1, 1, 1, 'admin', '$2y$10$C64q4N9kT3MqHUyzmqjpIe2x8/GGYSgIK2ZjDmthuP2NasZqazLxO');



INSERT INTO operaciones.tb_estaciones (estacion_nombre) VALUES ('X-1');
INSERT INTO operaciones.tb_estaciones (estacion_nombre) VALUES ('X-2');
INSERT INTO operaciones.tb_estaciones (estacion_nombre) VALUES ('X-3');
INSERT INTO operaciones.tb_estaciones (estacion_nombre) VALUES ('X-4');
INSERT INTO operaciones.tb_estaciones (estacion_nombre) VALUES ('X-5');
INSERT INTO operaciones.tb_estaciones (estacion_nombre) VALUES ('X-6');
INSERT INTO operaciones.tb_estaciones (estacion_nombre) VALUES ('X-7');
INSERT INTO operaciones.tb_estaciones (estacion_nombre) VALUES ('X-8');

INSERT INTO administrativo.tb_vehiculos_marcas (marca_nombre) VALUES ('S/M');

CREATE EXTENSION IF NOT EXISTS dblink;
INSERT INTO administrativo.tb_vehiculos (
    fk_usuario_id, fk_estacion_id, fk_marca_id, vehiculo_estado, vehiculo_direccion,
    vehiculo_placa, vehiculo_toneladas, vehiculo_tipo, vehiculo_color1, vehiculo_marca,
    vehiculo_fingreso, custodio_id, vehiculo_modelo, vehiculo_chasis, vehiculo_motor,
    vehiculo_combustible, vehiculo_avaluo, vehiculo_anio, vehiculo_pais, vehiculo_corroceria,
    vehiculo_pasajeros, vehiculo_cilindraje, vehiculo_color2, vehiculo_proposito,
    vehiculo_anio_matricula, vehiculo_ramv, vehiculo_sigla
)
SELECT 
    fk_usuario_id, fk_estacion_id, fk_marca_id, vehiculo_estado, vehiculo_direccion,
    vehiculo_placa, vehiculo_toneladas, vehiculo_tipo, vehiculo_color1, vehiculo_marca,
    vehiculo_fingreso, custodio_id, vehiculo_modelo, vehiculo_chasis, vehiculo_motor,
    vehiculo_combustible, vehiculo_avaluo, vehiculo_anio, vehiculo_pais, vehiculo_corroceria,
    vehiculo_pasajeros, vehiculo_cilindraje, vehiculo_color2, vehiculo_proposito,
    vehiculo_anio_matricula, vehiculo_ramv, vehiculo_sigla
FROM dblink(
    'dbname=db_cbsd user=postgres password=Cbsd2019 host=localhost',
    'SELECT 
        1 as fk_usuario_id, 1 as fk_estacion_id, 1 as fk_marca_id, vehiculo_estado, vehiculo_direccion,
        vehiculo_placa, vehiculo_toneladas, vehiculo_tipo, vehiculo_color1, vehiculo_marca,
        vehiculo_fingreso, 1 as custodio_id, vehiculo_modelo, vehiculo_chasis, vehiculo_motor,
        vehiculo_combustible, vehiculo_avaluo, vehiculo_anio, vehiculo_pais, vehiculo_corroceria,
        vehiculo_pasajeros, vehiculo_cilindraje, vehiculo_color2, vehiculo_proposito,
        vehiculo_anio_matricula, vehiculo_ramv, (select unidad_nombre from logistica.tb_unidades where resources.tb_vehiculos.vehiculo_id = logistica.tb_unidades.fk_vehiculo_id ) as vehiculo_sigla
     FROM resources.tb_vehiculos where vehiculo_id in (select fk_vehiculo_id from logistica.tb_unidades)'
) AS t(
    fk_usuario_id integer, fk_estacion_id integer, fk_marca_id integer, vehiculo_estado text, vehiculo_direccion text,
    vehiculo_placa text, vehiculo_toneladas numeric(4,2), vehiculo_tipo text, vehiculo_color1 text, vehiculo_marca text,
    vehiculo_fingreso timestamp, custodio_id integer, vehiculo_modelo text, vehiculo_chasis text, vehiculo_motor text,
    vehiculo_combustible text, vehiculo_avaluo numeric(10,2), vehiculo_anio integer, vehiculo_pais text, vehiculo_corroceria text,
    vehiculo_pasajeros integer, vehiculo_cilindraje numeric(6,2), vehiculo_color2 text, vehiculo_proposito text,
    vehiculo_anio_matricula integer, vehiculo_ramv text, vehiculo_sigla text
);

CREATE EXTENSION IF NOT EXISTS dblink;
INSERT INTO resources.tb_personas (
    persona_tipo_doc, persona_doc_identidad, persona_nombres, persona_apellidos,
    persona_sexo, persona_imagen, persona_direccion, persona_telefono, persona_correo,
    persona_fingreso, fk_usuario_id, persona_fnacimiento, persona_nacionalidad,
    persona_celular, persona_estadocivil, persona_tiposangre, fk_parroquia_id,
    persona_estatura, persona_peso, persona_acerca, persona_destrezas, persona_alergias,
    persona_discapacidad, persona_lugarnacimiento, persona_etnia, persona_senialesparticulares,
    fk_conyugeue_id, persona_principal, persona_secundaria, persona_no_casa, persona_referencia,
    persona_barrio_ciudadela, persona_barrio_sector, persona_titulo,
    persona_anexo_cedula, persona_anexo_votacion,
    persona_cemergencia_nombre, persona_cemergencia_parentesco, persona_cemergencia_direccion,
    persona_cemergencia_telefono, persona_discapacidad_tiene, persona_discapacidad_tipo,
    persona_discapacidad_porcentaje, persona_discapacidad_conadis, persona_discapacidad_conadis_numero,
    persona_enfermedad_cronica, persona_enfermedad_cronica_describa
)
SELECT 
    persona_tipo_doc, persona_doc_identidad, persona_nombres, persona_apellidos,
    persona_sexo, persona_imagen, persona_direccion, persona_telefono, persona_correo,
    persona_fingreso, fk_usuario_id, persona_fnacimiento, persona_nacionalidad,
    persona_celular, persona_estadocivil, persona_tiposangre, fk_parroquia_id,
    persona_estatura, persona_peso, persona_acerca, persona_destrezas, persona_alergias,
    persona_discapacidad, persona_lugarnacimiento, persona_etnia, persona_senialesparticulares,
    fk_conyugeue_id, persona_principal, persona_secundaria, persona_no_casa, persona_referencia,
    persona_barrio_ciudadela, persona_barrio_sector, persona_titulo,
    persona_anexo_cedula, persona_anexo_votacion,
    persona_cemergencia_nombre, persona_cemergencia_parentesco, persona_cemergencia_direccion,
    persona_cemergencia_telefono, persona_discapacidad_tiene, persona_discapacidad_tipo,
    persona_discapacidad_porcentaje, persona_discapacidad_conadis, persona_discapacidad_conadis_numero,
    persona_enfermedad_cronica, persona_enfermedad_cronica_describa
FROM dblink(
    'dbname=db_cbsd user=postgres password=Cbsd2019 host=localhost',
    'SELECT 
        persona_tipo_doc, persona_doc_identidad, persona_nombres, persona_apellidos,
        persona_sexo, persona_imagen, persona_direccion, persona_telefono, persona_correo,
        persona_fingreso, fk_usuario_id, persona_fnacimiento, persona_nacionalidad,
        persona_celular, persona_estadocivil, persona_tiposangre, fk_parroquia_id,
        persona_estatura, persona_peso, persona_acerca, persona_destrezas, persona_alergias,
        persona_discapacidad, persona_lugarnacimiento, persona_etnia, persona_senialesparticulares,
        fk_conyugeue_id, persona_principal, persona_secundaria, persona_no_casa, persona_referencia,
        persona_barrio_ciudadela, persona_barrio_sector, persona_titulo,
        persona_anexo_cedula, persona_anexo_votacion,
        persona_cemergencia_nombre, persona_cemergencia_parentesco, persona_cemergencia_direccion,
        persona_cemergencia_telefono, persona_discapacidad_tiene, persona_discapacidad_tipo,
        persona_discapacidad_porcentaje, persona_discapacidad_conadis, persona_discapacidad_conadis_numero,
        persona_enfermedad_cronica, persona_enfermedad_cronica_describa
     FROM resources.tb_personas'
) AS t (
    persona_tipo_doc text, persona_doc_identidad text, persona_nombres text, persona_apellidos text,
    persona_sexo text, persona_imagen text, persona_direccion text, persona_telefono text, persona_correo text,
    persona_fingreso timestamp, fk_usuario_id integer, persona_fnacimiento date, persona_nacionalidad text,
    persona_celular text, persona_estadocivil text, persona_tiposangre text, fk_parroquia_id integer,
    persona_estatura text, persona_peso text, persona_acerca text, persona_destrezas text, persona_alergias text,
    persona_discapacidad text, persona_lugarnacimiento text, persona_etnia text, persona_senialesparticulares text,
    fk_conyugeue_id integer, persona_principal text, persona_secundaria text, persona_no_casa text, persona_referencia text,
    persona_barrio_ciudadela text, persona_barrio_sector text, persona_titulo text,
    persona_anexo_cedula text, persona_anexo_votacion text,
    persona_cemergencia_nombre text, persona_cemergencia_parentesco text, persona_cemergencia_direccion text,
    persona_cemergencia_telefono text, persona_discapacidad_tiene text, persona_discapacidad_tipo text,
    persona_discapacidad_porcentaje text, persona_discapacidad_conadis text, persona_discapacidad_conadis_numero text,
    persona_enfermedad_cronica text, persona_enfermedad_cronica_describa text
);

CREATE EXTENSION IF NOT EXISTS dblink;
INSERT INTO tthh.tb_personal_puestos (
    ppersonal_registro, ppersonal_estado, fk_usuario_id, fk_personal_id, fk_puesto_id,
    personal_definicion, personal_contrato, personal_fecha_ingreso, personal_fecha_salida,
    personal_fecha_registro, personal_motivo_salida, personal_observacion,
    personal_baselegal, personal_regimen_laboral
)
SELECT 
    ppersonal_registro, ppersonal_estado, fk_usuario_id, fk_personal_id, fk_puesto_id,
    personal_definicion, personal_contrato, personal_fecha_ingreso, personal_fecha_salida,
    personal_fecha_registro, personal_motivo_salida, personal_observacion,
    personal_baselegal, personal_regimen_laboral
FROM dblink(
    'dbname=db_cbsd user=postgres password=Cbsd2019 host=localhost',
    $$
    SELECT 
        ppersonal_registro, ppersonal_estado, fk_usuario_id, fk_personal_id, fk_puesto_id,
        personal_definicion, personal_contrato, personal_fecha_ingreso, personal_fecha_salida,
        personal_fecha_registro, personal_motivo_salida, personal_observacion,
        personal_baselegal, personal_regimen_laboral
    FROM tthh.tb_personal_puestos
    $$
) AS t (
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

INSERT INTO tthh.tb_direcciones (
    direccion_registro, direccion_estado, fk_usuario_id,
    direccion_codigo, direccion_nombre, direccion_competencias,
    direccion_fecha_creacion, direccion_baselegal, direccion_tipo
)
SELECT 
    direccion_registro, direccion_estado, fk_usuario_id,
    direccion_codigo, direccion_nombre, direccion_competencias,
    direccion_fecha_creacion, direccion_baselegal, direccion_tipo
FROM dblink(
    'dbname=db_cbsd user=postgres password=Cbsd2019 host=localhost',
    $$
    SELECT 
        direccion_registro, direccion_estado, fk_usuario_id,
        direccion_codigo, direccion_nombre, direccion_competencias,
        direccion_fecha_creacion, direccion_baselegal, direccion_tipo
    FROM tthh.tb_direcciones
    $$
) AS t (
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

INSERT INTO tthh.tb_puestos (
    puesto_registro, puesto_estado, fk_usuario_id,
    puesto_departamento, puesto_nombre, fk_direccion_id,
    puesto_remuneracion, puesto_direccion, puesto_grado,
    puesto_modalidad, puesto_fecha_creacion, puesto_baselegal,
    puesto_partida, fk_grupo_id
)
SELECT 
    puesto_registro, puesto_estado, fk_usuario_id,
    puesto_departamento, puesto_nombre, fk_direccion_id,
    puesto_remuneracion, puesto_direccion, puesto_grado,
    puesto_modalidad, puesto_fecha_creacion, puesto_baselegal,
    puesto_partida, fk_grupo_id
FROM dblink(
    'dbname=db_cbsd user=postgres password=Cbsd2019 host=localhost',
    $$
    SELECT 
        puesto_registro, puesto_estado, fk_usuario_id,
        puesto_departamento, puesto_nombre, fk_direccion_id,
        puesto_remuneracion, puesto_direccion, puesto_grado,
        puesto_modalidad, puesto_fecha_creacion, puesto_baselegal,
        puesto_partida, fk_grupo_id
    FROM tthh.tb_puestos
    $$
) AS t (
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

INSERT INTO operaciones.tb_pelotones (
    peloton_registro, peloton_estado, fk_usuario_id, fk_estacion_id, peloton_nombre
)
SELECT 
    peloton_registro, peloton_estado, fk_usuario_id, fk_estacion_id, peloton_nombre
FROM dblink(
    'dbname=db_cbsd user=postgres password=Cbsd2019 host=localhost',
    $$
    SELECT 
        peloton_registro, peloton_estado, fk_usuario_id, fk_estacion_id, peloton_nombre
    FROM tthh.tb_pelotones
    $$
) AS t (
    peloton_registro timestamp,
    peloton_estado text,
    fk_usuario_id integer,
    fk_estacion_id integer,
    peloton_nombre text
);

INSERT INTO resources.tb_licenciasdeconducir (
    licencia_estado,
    licencia_registro,
    fk_usuario_id,
    licencia_tipo,
    licencia_categoria,
    licencia_descripcion
)
SELECT 
    licencia_estado,
    licencia_registro,
    fk_usuario_id,
    licencia_tipo,
    licencia_categoria,
    licencia_descripcion
FROM dblink(
    'dbname=db_cbsd user=postgres password=Cbsd2019 host=localhost',
    $$
    SELECT 
        licencia_estado,
        licencia_registro,
        fk_usuario_id,
        licencia_tipo,
        licencia_categoria,
        licencia_descripcion
    FROM resources.tb_licenciasdeconducir
    $$
) AS t (
    licencia_estado text,
    licencia_registro timestamp,
    fk_usuario_id integer,
    licencia_tipo text,
    licencia_categoria text,
    licencia_descripcion text
);

INSERT INTO tthh.tb_conductores (
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
    conductor_registro,
    conductor_estado,
    fk_usuario_id,
    fk_personal_id,
    fk_licencia_id,
    conductor_licencia_emision,
    conductor_licencia_validez,
    conductor_pdf
FROM dblink(
    'dbname=db_cbsd user=postgres password=Cbsd2019 host=localhost',
    $$
    SELECT 
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
    conductor_registro timestamp,
    conductor_estado text,
    fk_usuario_id integer,
    fk_personal_id integer,
    fk_licencia_id integer,
    conductor_licencia_emision date,
    conductor_licencia_validez date,
    conductor_pdf text
);

CREATE EXTENSION IF NOT EXISTS dblink;
INSERT INTO resources.tb_personas (
    persona_tipo_doc, persona_doc_identidad, persona_nombres, persona_apellidos,
    persona_sexo, persona_imagen, persona_direccion, persona_telefono, persona_correo,
    persona_fingreso, fk_usuario_id, persona_fnacimiento, persona_nacionalidad,
    persona_celular, persona_estadocivil, persona_tiposangre, fk_parroquia_id,
    persona_estatura, persona_peso, persona_acerca, persona_destrezas, persona_alergias,
    persona_discapacidad, persona_lugarnacimiento, persona_etnia, persona_senialesparticulares,
    fk_conyugeue_id, persona_principal, persona_secundaria, persona_no_casa, persona_referencia,
    persona_barrio_ciudadela, persona_barrio_sector, persona_titulo,
    persona_anexo_cedula, persona_anexo_votacion,
    persona_cemergencia_nombre, persona_cemergencia_parentesco, persona_cemergencia_direccion,
    persona_cemergencia_telefono, persona_discapacidad_tiene, persona_discapacidad_tipo,
    persona_discapacidad_porcentaje, persona_discapacidad_conadis, persona_discapacidad_conadis_numero,
    persona_enfermedad_cronica, persona_enfermedad_cronica_describa
)
SELECT 
    persona_tipo_doc, persona_doc_identidad, persona_nombres, persona_apellidos,
    persona_sexo, persona_imagen, persona_direccion, persona_telefono, persona_correo,
    persona_fingreso, fk_usuario_id, persona_fnacimiento, persona_nacionalidad,
    persona_celular, persona_estadocivil, persona_tiposangre, fk_parroquia_id,
    persona_estatura, persona_peso, persona_acerca, persona_destrezas, persona_alergias,
    persona_discapacidad, persona_lugarnacimiento, persona_etnia, persona_senialesparticulares,
    fk_conyugeue_id, persona_principal, persona_secundaria, persona_no_casa, persona_referencia,
    persona_barrio_ciudadela, persona_barrio_sector, persona_titulo,
    persona_anexo_cedula, persona_anexo_votacion,
    persona_cemergencia_nombre, persona_cemergencia_parentesco, persona_cemergencia_direccion,
    persona_cemergencia_telefono, persona_discapacidad_tiene, persona_discapacidad_tipo,
    persona_discapacidad_porcentaje, persona_discapacidad_conadis, persona_discapacidad_conadis_numero,
    persona_enfermedad_cronica, persona_enfermedad_cronica_describa
FROM dblink(
    'dbname=db_cbsd user=postgres password=Cbsd2019 host=localhost',
    $$
    SELECT 
        persona_tipo_doc, persona_doc_identidad, persona_nombres, persona_apellidos,
        persona_sexo, persona_imagen, persona_direccion, persona_telefono, persona_correo,
        persona_fingreso, fk_usuario_id, persona_fnacimiento, persona_nacionalidad,
        persona_celular, persona_estadocivil, persona_tiposangre, fk_parroquia_id,
        persona_estatura, persona_peso, persona_acerca, persona_destrezas, persona_alergias,
        persona_discapacidad, persona_lugarnacimiento, persona_etnia, persona_senialesparticulares,
        fk_conyugeue_id, persona_principal, persona_secundaria, persona_no_casa, persona_referencia,
        persona_barrio_ciudadela, persona_barrio_sector, persona_titulo,
        persona_anexo_cedula, persona_anexo_votacion,
        persona_cemergencia_nombre, persona_cemergencia_parentesco, persona_cemergencia_direccion,
        persona_cemergencia_telefono, persona_discapacidad_tiene, persona_discapacidad_tipo,
        persona_discapacidad_porcentaje, persona_discapacidad_conadis, persona_discapacidad_conadis_numero,
        persona_enfermedad_cronica, persona_enfermedad_cronica_describa
    FROM resources.tb_personas
    $$
) AS t (
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


INSERT INTO tthh.tb_personal (
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
    'dbname=db_cbsd user=postgres password=Cbsd2019 host=localhost',
    $$
    SELECT 
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

INSERT INTO tthh.tb_conductores (
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
    conductor_registro,
    conductor_estado,
    fk_usuario_id,
    fk_personal_id,
    fk_licencia_id,
    conductor_licencia_emision,
    conductor_licencia_validez,
    conductor_pdf
FROM dblink(
    'dbname=db_cbsd user=postgres password=Cbsd2019 host=localhost',
    $$
    SELECT 
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
    conductor_registro timestamp,
    conductor_estado text,
    fk_usuario_id integer,
    fk_personal_id integer,
    fk_licencia_id integer,
    conductor_licencia_emision date,
    conductor_licencia_validez date,
    conductor_pdf text
);

