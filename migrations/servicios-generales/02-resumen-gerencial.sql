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
