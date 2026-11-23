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
