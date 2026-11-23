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
