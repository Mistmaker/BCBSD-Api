-- =============================================================================
-- IMPORTACIÓN DE DATOS DEL SISTEMA ANTERIOR (db_cbsd): personas, personal, puestos, usuarios, perfiles, vehículos,
-- licencias, conductores, ubicaciones y CIE-10. Antes en script.sql y script-2.sql (con la clave escrita).
-- Se ejecuta dentro del bloque de importación de script-3 (conexión "legacy"); lo que ya existe no se repite.
-- =============================================================================

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
