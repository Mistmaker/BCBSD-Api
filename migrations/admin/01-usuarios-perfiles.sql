-- =============================================================================
-- USUARIOS Y PERFILES - re-ejecutable
-- Usuario (admin.tb_usuarios) -> persona (resources.tb_personas); puede ser o no funcionario (tthh.tb_personal).
-- Perfil (admin.tb_perfiles) = grupo de privilegios predefinido (admin.tb_perfil_rol).
-- Privilegios efectivos de un usuario ACTIVO = los de su perfil (si está ACTIVO) + los adicionales del usuario
-- (admin.tb_usuario_rol). Vista admin.vw_usuario_privilegios: la usan el login, el menú, getPermisos y requirePermiso.
-- =============================================================================

-- 1. Privilegios de cada perfil
CREATE TABLE IF NOT EXISTS admin.tb_perfil_rol (
    fk_perfil_id integer NOT NULL REFERENCES admin.tb_perfiles(perfil_id) ON DELETE CASCADE,
    fk_rol_id integer NOT NULL REFERENCES admin.tb_roles(rol_id) ON DELETE CASCADE,
    PRIMARY KEY (fk_perfil_id, fk_rol_id)
);
COMMENT ON TABLE admin.tb_perfil_rol IS 'Privilegios predefinidos de cada perfil; los usuarios del perfil los reciben automáticamente';
COMMENT ON TABLE admin.tb_usuario_rol IS 'Privilegios adicionales de un usuario (además de los de su perfil)';

ALTER TABLE admin.tb_perfiles ADD COLUMN IF NOT EXISTS fk_usuario_id integer;
ALTER TABLE admin.tb_perfiles ADD COLUMN IF NOT EXISTS perfil_registro timestamp without time zone DEFAULT ('now'::text)::timestamp(0) with time zone;
-- Nombre de perfil único (solo si ya no hay duplicados; si los hay, el API igual impide crear nuevos repetidos)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM admin.tb_perfiles GROUP BY upper(trim(perfil_nombre)) HAVING count(*) > 1) THEN
        CREATE UNIQUE INDEX IF NOT EXISTS ux_perfiles_nombre ON admin.tb_perfiles (upper(trim(perfil_nombre)));
    ELSE
        RAISE NOTICE 'Hay perfiles con el mismo nombre: no se crea el índice único ux_perfiles_nombre';
    END IF;
END
$$;
ALTER TABLE admin.tb_usuarios ADD COLUMN IF NOT EXISTS usuario_ultimo_acceso timestamp without time zone;
CREATE INDEX IF NOT EXISTS ix_usuarios_persona ON admin.tb_usuarios (fk_persona_id);
CREATE INDEX IF NOT EXISTS ix_usuarios_login ON admin.tb_usuarios (lower(usuario_login));

-- Secuencias al día: las tablas se cargaron con IDs explícitos (migración desde db_cbsd) y el sistema nuevo empieza a
-- insertar usuarios, perfiles y personas desde sus pantallas. Solo se adelantan, nunca se retroceden.
SELECT setval(pg_get_serial_sequence('admin.tb_usuarios', 'usuario_id'),
              GREATEST((SELECT COALESCE(max(usuario_id), 1) FROM admin.tb_usuarios), (SELECT last_value FROM admin.tb_usuarios_usuario_id_seq)));
SELECT setval(pg_get_serial_sequence('admin.tb_perfiles', 'perfil_id'),
              GREATEST((SELECT COALESCE(max(perfil_id), 1) FROM admin.tb_perfiles), (SELECT last_value FROM admin.tb_perfiles_perfil_id_seq)));
SELECT setval(pg_get_serial_sequence('resources.tb_personas', 'persona_id'),
              GREATEST((SELECT COALESCE(max(persona_id), 1) FROM resources.tb_personas), (SELECT last_value FROM resources.tb_personas_persona_id_seq)));

-- Perfil por defecto para usuarios sin uno válido (tb_usuarios.fk_perfil_id es obligatorio)
INSERT INTO admin.tb_perfiles (perfil_nombre, perfil_descripcion)
SELECT 'SIN PERFIL', 'Usuarios sin privilegios predefinidos (solo los adicionales que se les asignen)'
 WHERE NOT EXISTS (SELECT 1 FROM admin.tb_perfiles WHERE upper(trim(perfil_nombre)) = 'SIN PERFIL');

-- 2. Privilegios efectivos
CREATE OR REPLACE VIEW admin.vw_usuario_privilegios AS
SELECT u.usuario_id, ur.fk_rol_id AS rol_id, 'USUARIO'::text AS origen
  FROM admin.tb_usuarios u JOIN admin.tb_usuario_rol ur ON ur.fk_usuario_id = u.usuario_id
 WHERE COALESCE(u.usuario_estado, 'ACTIVO') = 'ACTIVO'
UNION
SELECT u.usuario_id, pr.fk_rol_id, 'PERFIL'::text
  FROM admin.tb_usuarios u
  JOIN admin.tb_perfiles p ON p.perfil_id = u.fk_perfil_id AND COALESCE(p.perfil_estado, 'ACTIVO') = 'ACTIVO'
  JOIN admin.tb_perfil_rol pr ON pr.fk_perfil_id = p.perfil_id
 WHERE COALESCE(u.usuario_estado, 'ACTIVO') = 'ACTIVO';
COMMENT ON VIEW admin.vw_usuario_privilegios IS 'Privilegios efectivos: perfil + adicionales, solo usuarios y perfiles ACTIVOS';

-- 3. Menú y privilegios de la administración del sistema (antes el menú estaba fijo para un usuario)
ALTER TABLE admin.tb_roles ADD COLUMN IF NOT EXISTS rol_codigo text;
INSERT INTO admin.tb_modulos (modulo_nombre, modulo_descripcion)
SELECT 'Administración', 'Usuarios, perfiles y privilegios del sistema'
 WHERE NOT EXISTS (SELECT 1 FROM admin.tb_modulos WHERE modulo_nombre = 'Administración');
INSERT INTO admin.tb_submodulos (fk_modulo_id, submodulo_nombre)
SELECT m.modulo_id, 'Usuarios y perfiles' FROM admin.tb_modulos m
 WHERE m.modulo_nombre = 'Administración'
   AND NOT EXISTS (SELECT 1 FROM admin.tb_submodulos x WHERE x.submodulo_nombre = 'Usuarios y perfiles');

-- Si el menú anterior ya tenía estas pantallas (ruta sin código), se les completa el código en lugar de duplicarlas
UPDATE admin.tb_roles r SET rol_codigo = c.codigo
  FROM (VALUES ('/adm/usuarios', 'SIS_USUARIOS'), ('/adm/perfiles', 'SIS_PERFILES')) AS c(ruta, codigo)
 WHERE r.rol_path = c.ruta AND r.rol_codigo IS NULL
   AND NOT EXISTS (SELECT 1 FROM admin.tb_roles y WHERE y.rol_codigo = c.codigo);

INSERT INTO admin.tb_roles (rol_nombre, rol_descripcion, fk_submodulo_id, rol_path, rol_codigo)
SELECT v.nombre, v.descripcion, s.submodulo_id, v.ruta, v.codigo
  FROM (VALUES
        ('Usuarios', 'Acceso al listado de usuarios del sistema', '/adm/usuarios', 'SIS_USUARIOS'),
        ('Perfiles', 'Acceso a los perfiles (grupos de privilegios predefinidos)', '/adm/perfiles', 'SIS_PERFILES'),
        ('Registrar y editar usuarios', 'Crear usuarios, editar sus datos y su perfil, activarlos o inactivarlos y restablecer su clave', NULL, 'SIS_USUARIO_GESTIONAR'),
        ('Asignar privilegios adicionales', 'Dar a un usuario privilegios ademas de los de su perfil', NULL, 'SIS_USUARIO_PRIVILEGIOS'),
        ('Administrar perfiles', 'Crear y editar perfiles y sus privilegios predefinidos', NULL, 'SIS_PERFIL_GESTIONAR')
       ) AS v(nombre, descripcion, ruta, codigo)
  JOIN admin.tb_submodulos s ON s.submodulo_nombre = 'Usuarios y perfiles'
 WHERE NOT EXISTS (SELECT 1 FROM admin.tb_roles r WHERE r.rol_codigo = v.codigo)
   AND NOT EXISTS (SELECT 1 FROM admin.tb_roles r WHERE v.ruta IS NOT NULL AND r.rol_path = v.ruta);

-- 4. Asignaciones iniciales: el administrador (parámetro SIS_ADMINISTRADORES) y el perfil ADMINISTRADOR reciben toda la administración del sistema
INSERT INTO admin.tb_usuario_rol (fk_usuario_id, fk_rol_id)
SELECT u.usuario_id, r.rol_id FROM admin.tb_usuarios u JOIN admin.tb_roles r ON r.rol_codigo LIKE 'SIS\_%'
 WHERE admin.fn_es_administrador(u.usuario_id)
   AND NOT EXISTS (SELECT 1 FROM admin.tb_usuario_rol x WHERE x.fk_usuario_id = u.usuario_id AND x.fk_rol_id = r.rol_id);
INSERT INTO admin.tb_perfil_rol (fk_perfil_id, fk_rol_id)
SELECT p.perfil_id, r.rol_id FROM admin.tb_perfiles p JOIN admin.tb_roles r ON r.rol_codigo LIKE 'SIS\_%'
 WHERE admin.fn_perfil_es_administrador(p.perfil_id)
ON CONFLICT DO NOTHING;

-- 5. Contraseñas: password_hash (bcrypt, 60 caracteres). Las MD5 existentes se convierten solas en el siguiente login.
COMMENT ON COLUMN admin.tb_usuarios.usuario_pass IS 'password_hash() de PHP; las MD5 heredadas se reemplazan al iniciar sesión';
