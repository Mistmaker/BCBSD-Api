-- =============================================================================
-- PETICIÓN DE MATERIALES (Servicios generales) - re-ejecutable
-- Documento simple que reemplaza el libretín: se digitan cantidad, unidad y descripción (sin stock ni catálogo de
-- productos), se imprime y se firma. Código {SIGLAS}{AA}PDM{NNNNN}, secuencia que reinicia cada año.
-- =============================================================================

CREATE TABLE IF NOT EXISTS logistica.tb_peticionesmateriales (
    peticion_id SERIAL NOT NULL PRIMARY KEY,
    peticion_registro timestamp without time zone DEFAULT ('now'::text)::timestamp(0) with time zone,
    fk_usuario_id integer NOT NULL REFERENCES admin.tb_usuarios(usuario_id),
    peticion_codigo text NOT NULL UNIQUE,
    peticion_anio integer NOT NULL,
    peticion_serie integer NOT NULL,
    peticion_fecha date NOT NULL DEFAULT CURRENT_DATE,
    peticion_lugar text,                                   -- "Lugar y fecha" (por defecto, la ciudad de la institución)
    peticion_destino text NOT NULL,                        -- "Sírvase autorizar ... para ser utilizados en:"
    peticion_autorizado_para text CHECK (peticion_autorizado_para IN ('ADQUISICION', 'BODEGA')),
    solicitante_id integer NOT NULL REFERENCES tthh.tb_personal_puestos(ppersonal_id),
    solicitante_cargo text,
    autoriza_id integer REFERENCES tthh.tb_personal_puestos(ppersonal_id),
    autoriza_cargo text,
    peticion_observaciones text,
    peticion_estado text NOT NULL DEFAULT 'EMITIDA' CHECK (peticion_estado IN ('EMITIDA', 'ANULADA')),
    UNIQUE (peticion_anio, peticion_serie)
);
CREATE INDEX IF NOT EXISTS ix_peticionesmateriales_fecha ON logistica.tb_peticionesmateriales (peticion_fecha DESC);

CREATE TABLE IF NOT EXISTS logistica.tb_peticionesmateriales_detalle (
    detalle_id SERIAL NOT NULL PRIMARY KEY,
    fk_peticion_id integer NOT NULL REFERENCES logistica.tb_peticionesmateriales(peticion_id) ON DELETE CASCADE,
    detalle_orden integer NOT NULL,
    detalle_cantidad numeric(12,2) NOT NULL CHECK (detalle_cantidad > 0),
    detalle_unidad text NOT NULL,
    detalle_descripcion text NOT NULL
);
CREATE INDEX IF NOT EXISTS ix_peticionesmateriales_detalle ON logistica.tb_peticionesmateriales_detalle (fk_peticion_id, detalle_orden);

-- Parámetros
INSERT INTO admin.tb_params (param_key, param_value, param_type, param_name, param_modulo) VALUES
    ('PDM_UNIDADES', 'UNIDAD|CAJA|PAQUETE|RESMA|ROLLO|METRO|LITRO|GALÓN|KILOGRAMO|LIBRA|PAR|JUEGO|FUNDA|CANECA|BIDÓN|FRASCO|SACO',
     'list', 'Petición de materiales: unidades sugeridas (se puede escribir otra)', 'SERVICIOS GENERALES'),
    ('PDM_AUTORIZA_PUESTO_ID', '4', 'integer',
     'Petición de materiales: puesto (tthh.tb_puestos.puesto_id) de quien autoriza; se precarga quien lo tenga EN FUNCIONES', 'SERVICIOS GENERALES'),
    ('PDM_FILAS_MINIMAS', '15', 'integer', 'Petición de materiales: filas que muestra la tabla del PDF aunque haya menos ítems (como el libretín)', 'SERVICIOS GENERALES')
ON CONFLICT (param_key) DO NOTHING;

-- Menú y privilegios: Dir. Administrativa > Servicios generales
ALTER TABLE admin.tb_roles ADD COLUMN IF NOT EXISTS rol_codigo text;
INSERT INTO admin.tb_submodulos (fk_modulo_id, submodulo_nombre)
SELECT m.modulo_id, 'Servicios generales' FROM admin.tb_modulos m
 WHERE m.modulo_nombre = 'Dir. Administrativa'
   AND NOT EXISTS (SELECT 1 FROM admin.tb_submodulos x WHERE x.submodulo_nombre = 'Servicios generales');

INSERT INTO admin.tb_roles (rol_nombre, rol_descripcion, fk_submodulo_id, rol_path, rol_codigo)
SELECT v.nombre, v.descripcion, s.submodulo_id, v.ruta, v.codigo
  FROM (VALUES
        ('Peticiones de materiales', 'Acceso a las peticiones de materiales y su impresion', '/admin/peticiones-materiales', 'ADM_PETICIONES_MATERIALES'),
        ('Registrar peticiones de materiales', 'Crear, editar y anular peticiones de materiales', NULL, 'ADM_PETICION_MATERIALES_GESTIONAR')
       ) AS v(nombre, descripcion, ruta, codigo)
  JOIN admin.tb_submodulos s ON s.submodulo_nombre = 'Servicios generales'
 WHERE NOT EXISTS (SELECT 1 FROM admin.tb_roles r WHERE r.rol_codigo = v.codigo)
   AND NOT EXISTS (SELECT 1 FROM admin.tb_roles r WHERE v.ruta IS NOT NULL AND r.rol_path = v.ruta);

-- Asignación inicial: el administrador (113) y quienes ya emiten órdenes de movilización (servicios generales)
INSERT INTO admin.tb_usuario_rol (fk_usuario_id, fk_rol_id)
SELECT DISTINCT u.usuario_id, p.rol_id
  FROM admin.tb_usuarios u
  JOIN admin.tb_roles p ON p.rol_codigo IN ('ADM_PETICIONES_MATERIALES', 'ADM_PETICION_MATERIALES_GESTIONAR')
 WHERE (u.usuario_id = 113
        OR EXISTS (SELECT 1 FROM admin.tb_usuario_rol ur JOIN admin.tb_roles r ON r.rol_id = ur.fk_rol_id
                    WHERE ur.fk_usuario_id = u.usuario_id AND r.rol_codigo = 'ADM_MOVILIZACION_CREAR'))
   AND NOT EXISTS (SELECT 1 FROM admin.tb_usuario_rol x WHERE x.fk_usuario_id = u.usuario_id AND x.fk_rol_id = p.rol_id);
-- y el perfil ADMINISTRADOR
INSERT INTO admin.tb_perfil_rol (fk_perfil_id, fk_rol_id)
SELECT pf.perfil_id, r.rol_id FROM admin.tb_perfiles pf JOIN admin.tb_roles r ON r.rol_codigo IN ('ADM_PETICIONES_MATERIALES', 'ADM_PETICION_MATERIALES_GESTIONAR')
 WHERE upper(trim(pf.perfil_nombre)) = 'ADMINISTRADOR'
ON CONFLICT DO NOTHING;
