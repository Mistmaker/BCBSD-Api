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
    fk_unidad_id INTEGER NOT NULL,
    operador_id INTEGER DEFAULT NULL,
    director_administrativo INTEGER NOT NULL,
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
	
 	orden_total DECIMAL(2) DEFAULT 0,
 	
    orden_observaciones TEXT,

    CONSTRAINT pk_tb_ordenesabastecimiento
        PRIMARY KEY (orden_id)
);

-- Vincular la secuencia con la columna orden_id
ALTER SEQUENCE logistica.tb_ordenesabastecimiento_orden_id_seq
    OWNED BY logistica.tb_ordenesabastecimiento.orden_id;