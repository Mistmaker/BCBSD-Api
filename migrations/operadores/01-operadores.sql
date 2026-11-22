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

-- Acceso de consulta para quien ya emite órdenes de movilización o combustible; ambos privilegios para el administrador (113)
INSERT INTO admin.tb_usuario_rol (fk_usuario_id, fk_rol_id)
SELECT DISTINCT u.usuario_id, o.rol_id
  FROM admin.tb_usuarios u
  JOIN admin.tb_roles o ON o.rol_codigo IN ('ADM_OPERADORES', 'ADM_OPERADOR_GESTIONAR')
 WHERE (u.usuario_id = 113
        OR (o.rol_codigo = 'ADM_OPERADORES'
            AND EXISTS (SELECT 1 FROM admin.tb_usuario_rol ur JOIN admin.tb_roles r ON r.rol_id = ur.fk_rol_id
                         WHERE ur.fk_usuario_id = u.usuario_id AND r.rol_codigo IN ('ADM_MOVILIZACION', 'ADM_COMBUSTIBLE'))))
   AND NOT EXISTS (SELECT 1 FROM admin.tb_usuario_rol x WHERE x.fk_usuario_id = u.usuario_id AND x.fk_rol_id = o.rol_id);
