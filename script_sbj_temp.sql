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
