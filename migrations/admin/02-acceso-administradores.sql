-- =============================================================================
-- ACCESO DE LOS ADMINISTRADORES - re-ejecutable, va AL FINAL de script-3
-- Los administradores (parámetro SIS_ADMINISTRADORES: usuario_id o login) y los perfiles de administrador
-- (parámetro SIS_PERFILES_ADMINISTRADOR) reciben TODOS los privilegios existentes, incluidos los que agreguen
-- migraciones nuevas. Para cambiar quién es administrador:
--   UPDATE admin.tb_params SET param_value = '113|mi.usuario' WHERE param_key = 'SIS_ADMINISTRADORES';
-- y volver a ejecutar esta sección (o script-3 completo).
-- =============================================================================

-- 1. Perfiles de administrador: todos los privilegios
INSERT INTO admin.tb_perfil_rol (fk_perfil_id, fk_rol_id)
SELECT p.perfil_id, r.rol_id
  FROM admin.tb_perfiles p CROSS JOIN admin.tb_roles r
 WHERE admin.fn_perfil_es_administrador(p.perfil_id)
ON CONFLICT DO NOTHING;

-- 2. Usuarios administradores: todos los privilegios como adicionales (no dependen de su perfil ni de su estado)
INSERT INTO admin.tb_usuario_rol (fk_usuario_id, fk_rol_id)
SELECT u.usuario_id, r.rol_id
  FROM admin.tb_usuarios u CROSS JOIN admin.tb_roles r
 WHERE admin.fn_es_administrador(u.usuario_id)
   AND NOT EXISTS (SELECT 1 FROM admin.tb_usuario_rol x WHERE x.fk_usuario_id = u.usuario_id AND x.fk_rol_id = r.rol_id);

-- 3. Perfil de administrador activo (un perfil inactivo no da privilegios)
UPDATE admin.tb_perfiles p SET perfil_estado = 'ACTIVO'
 WHERE admin.fn_perfil_es_administrador(p.perfil_id) AND perfil_estado IS DISTINCT FROM 'ACTIVO';

-- 4. Resultado: administradores, su estado y cuántos privilegios efectivos tienen (debe ser el total de privilegios)
SELECT u.usuario_id, u.usuario_login, COALESCE(u.usuario_estado, 'ACTIVO') AS estado, pf.perfil_nombre,
       (SELECT count(DISTINCT v.rol_id) FROM admin.vw_usuario_privilegios v WHERE v.usuario_id = u.usuario_id) AS privilegios,
       (SELECT count(*) FROM admin.tb_roles) AS total_privilegios
  FROM admin.tb_usuarios u LEFT JOIN admin.tb_perfiles pf ON pf.perfil_id = u.fk_perfil_id
 WHERE admin.fn_es_administrador(u.usuario_id)
 ORDER BY u.usuario_id;
