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
               ('Subjefatura', 'Voluntarios', 30, 'GRUPO'),
               ('Administración', 'Usuarios y perfiles', 10, 'GRUPO'), ('Administración', 'Parámetros', 20, 'GRUPO')) AS v(modulo, nombre, orden, menu)
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
        ('SIS_PERFILES', 'Administración', 'Usuarios y perfiles', 20, 'Perfiles', NULL, '{Usuarios y perfiles}'),
        ('SIS_PARAMETROS', 'Administración', 'Parámetros', 10, 'Parámetros', NULL, '{Parámetros}'),
        ('SIS_PARAMETRO_EDITAR', 'Administración', 'Parámetros', 11, NULL, NULL, '{Parámetros}');

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
