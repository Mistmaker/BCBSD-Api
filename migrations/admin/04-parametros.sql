-- =============================================================================
-- PARÁMETROS DEL SISTEMA (admin.tb_params) - re-ejecutable, va después de las migraciones que crean parámetros
-- Pantalla Administración > Parámetros (/adm/parametros): buscar por llave, nombre o valor y editar el valor con un
-- editor según el tipo. Los parámetros los crean las migraciones (el código los lee por su llave): en la pantalla
-- solo se edita el valor; el tipo y la llave los define el sistema.
-- Tipos: NUMERO, TEXTO (una línea), TEXTO_LARGO, LISTA (valores separados por |), SI_NO, JSON, HTML, COLOR (#RRGGBB).
-- =============================================================================

-- 1. Auditoría: quién y cuándo cambió el valor por última vez, e historial de cambios
ALTER TABLE admin.tb_params ADD COLUMN IF NOT EXISTS param_actualizado timestamp;
ALTER TABLE admin.tb_params ADD COLUMN IF NOT EXISTS fk_usuario_actualiza integer;
CREATE TABLE IF NOT EXISTS admin.tb_params_historial (
    historial_id serial PRIMARY KEY,
    fk_param_id integer NOT NULL REFERENCES admin.tb_params (param_id),
    historial_valor_anterior text,
    historial_valor_nuevo text,
    fk_usuario_id integer,
    historial_fecha timestamp NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS tb_params_historial_param_idx ON admin.tb_params_historial (fk_param_id, historial_fecha DESC);
COMMENT ON TABLE admin.tb_params_historial IS 'Cambios del valor de cada parámetro hechos desde Administración > Parámetros';

-- 2. Tipos unificados (las migraciones anteriores usaban integer, text, list y lista)
UPDATE admin.tb_params SET param_type = 'NUMERO' WHERE lower(param_type) IN ('integer', 'int', 'numeric', 'number', 'numero', 'numérico', 'numerico');
UPDATE admin.tb_params SET param_type = 'LISTA' WHERE lower(param_type) IN ('list', 'lista');
UPDATE admin.tb_params SET param_type = 'JSON' WHERE lower(param_type) = 'json' AND param_type <> 'JSON';
UPDATE admin.tb_params SET param_type = 'HTML' WHERE lower(param_type) = 'html' AND param_type <> 'HTML';
UPDATE admin.tb_params SET param_type = 'SI_NO'
 WHERE lower(param_type) IN ('text', 'texto') AND upper(trim(param_value)) IN ('SI', 'NO')
   AND param_key IN ('OPER_BLOQUEAR_LICENCIA_VENCIDA', 'OPER_BLOQUEAR_SIN_SUSTENTO', 'OPER_EXIGIR_PDF_LICENCIA');
UPDATE admin.tb_params SET param_type = 'COLOR' WHERE param_key = 'MAPA_MARCADOR_COLOR' AND lower(param_type) IN ('text', 'texto');
UPDATE admin.tb_params SET param_type = CASE WHEN param_value LIKE '%' || chr(10) || '%' THEN 'TEXTO_LARGO' ELSE 'TEXTO' END
 WHERE param_type IS NULL OR lower(param_type) IN ('text', 'texto', 'texto simple', 'string')
    OR param_type NOT IN ('NUMERO', 'TEXTO', 'TEXTO_LARGO', 'LISTA', 'SI_NO', 'JSON', 'HTML', 'COLOR');
UPDATE admin.tb_params SET param_modulo = 'GENERAL' WHERE param_modulo IS NULL OR trim(param_modulo) = '';

-- 3. Privilegios: Administración > Parámetros
INSERT INTO admin.tb_submodulos (fk_modulo_id, submodulo_nombre, submodulo_descripcion)
SELECT m.modulo_id, 'Parámetros', 'Parámetros y configuración del sistema'
  FROM admin.tb_modulos m
 WHERE m.modulo_nombre = 'Administración'
   AND NOT EXISTS (SELECT 1 FROM admin.tb_submodulos s WHERE s.fk_modulo_id = m.modulo_id AND s.submodulo_nombre = 'Parámetros');

INSERT INTO admin.tb_roles (rol_nombre, rol_descripcion, fk_submodulo_id, rol_path, rol_codigo)
SELECT v.nombre, v.descripcion, s.submodulo_id, v.ruta, v.codigo
  FROM (VALUES
        ('Parámetros del sistema', 'Consultar los parámetros del sistema (valores configurables de cada módulo)', '/adm/parametros', 'SIS_PARAMETROS'),
        ('Editar parámetros', 'Cambiar el valor de los parámetros (los de Administración solo los administradores)', NULL, 'SIS_PARAMETRO_EDITAR')
       ) AS v(nombre, descripcion, ruta, codigo)
  JOIN admin.tb_modulos m ON m.modulo_nombre = 'Administración'
  JOIN admin.tb_submodulos s ON s.fk_modulo_id = m.modulo_id AND s.submodulo_nombre = 'Parámetros'
 WHERE NOT EXISTS (SELECT 1 FROM admin.tb_roles r WHERE r.rol_codigo = v.codigo)
   AND NOT EXISTS (SELECT 1 FROM admin.tb_roles r WHERE v.ruta IS NOT NULL AND r.rol_path = v.ruta);

-- 4. Asignación inicial: administradores y perfiles de administrador
INSERT INTO admin.tb_usuario_rol (fk_usuario_id, fk_rol_id)
SELECT u.usuario_id, r.rol_id
  FROM admin.tb_usuarios u JOIN admin.tb_roles r ON r.rol_codigo IN ('SIS_PARAMETROS', 'SIS_PARAMETRO_EDITAR')
 WHERE admin.fn_es_administrador(u.usuario_id)
   AND NOT EXISTS (SELECT 1 FROM admin.tb_usuario_rol x WHERE x.fk_usuario_id = u.usuario_id AND x.fk_rol_id = r.rol_id);
INSERT INTO admin.tb_perfil_rol (fk_perfil_id, fk_rol_id)
SELECT p.perfil_id, r.rol_id
  FROM admin.tb_perfiles p JOIN admin.tb_roles r ON r.rol_codigo IN ('SIS_PARAMETROS', 'SIS_PARAMETRO_EDITAR')
 WHERE admin.fn_perfil_es_administrador(p.perfil_id)
ON CONFLICT DO NOTHING;
