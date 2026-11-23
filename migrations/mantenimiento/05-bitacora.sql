-- =============================================================================
-- BITÁCORA DEL VEHÍCULO - re-ejecutable
-- Historial por fecha y kilometraje (combustible, mantenimiento, movilización, partes) y estadísticas:
-- rendimiento de combustible, frecuencia y gasto de mantenimiento, trabajos repetidos y comparación
-- con vehículos de la misma marca, modelo y año.
-- =============================================================================

-- 1. Galones con decimales (antes int4: 12,35 galones se guardaba como 12 y distorsionaba el rendimiento).
--    Cambio de tipo seguro: los valores enteros existentes se conservan.
DO $$
BEGIN
    IF (SELECT data_type FROM information_schema.columns
         WHERE table_schema = 'logistica' AND table_name = 'tb_ordenesabastecimiento' AND column_name = 'orden_cantidad_galones') = 'integer' THEN
        ALTER TABLE logistica.tb_ordenesabastecimiento ALTER COLUMN orden_cantidad_galones TYPE numeric(10,3);
    END IF;
    IF (SELECT data_type FROM information_schema.columns
         WHERE table_schema = 'logistica' AND table_name = 'tb_detalleordenesabastecimiento' AND column_name = 'orden_detalle_cantidad_galones') = 'integer' THEN
        ALTER TABLE logistica.tb_detalleordenesabastecimiento ALTER COLUMN orden_detalle_cantidad_galones TYPE numeric(10,3);
    END IF;
END
$$;

-- 2. Índices para consultar el historial de un vehículo
CREATE INDEX IF NOT EXISTS ix_ordenesabastecimiento_unidad_fecha ON logistica.tb_ordenesabastecimiento (fk_unidad_id, orden_fecha);
CREATE INDEX IF NOT EXISTS ix_ordenesmovilizacion_unidad_salida ON logistica.tb_ordenesmovilizacion (fk_unidad_id, orden_hora_salida);
CREATE INDEX IF NOT EXISTS ix_parte_unidades_vehiculo ON operaciones.tb_parte_unidades (fk_vehiculo_id, parte_unidad_despacho);

-- 3. Parámetros de las alertas
INSERT INTO admin.tb_params (param_key, param_value, param_type, param_name, param_modulo) VALUES
    ('BIT_VENTANA_REPETICION_DIAS', '180', 'integer', 'Bitácora: días en los que un mismo trabajo repetido genera alerta', 'MANTENIMIENTO'),
    ('BIT_ALERTA_RENDIMIENTO_PCT', '15', 'integer', 'Bitácora: % por debajo del rendimiento (km/gal) de vehículos iguales que genera alerta', 'MANTENIMIENTO'),
    ('BIT_ALERTA_COSTO_PCT', '30', 'integer', 'Bitácora: % por encima del costo de mantenimiento por km de vehículos iguales que genera alerta', 'MANTENIMIENTO')
ON CONFLICT (param_key) DO NOTHING;

-- 4. Privilegio de acceso (pantalla) en el submódulo Unidades
ALTER TABLE admin.tb_roles ADD COLUMN IF NOT EXISTS rol_codigo text;
INSERT INTO admin.tb_roles (rol_nombre, rol_descripcion, fk_submodulo_id, rol_path, rol_codigo)
SELECT 'Bitacora de vehiculos', 'Historial, consumo de combustible, gasto de mantenimiento y alertas por vehiculo', s.submodulo_id,
       '/admin/bitacora-vehiculos', 'ADM_BITACORA_VEHICULOS'
  FROM admin.tb_submodulos s
 WHERE s.submodulo_nombre = 'Unidades'
   AND NOT EXISTS (SELECT 1 FROM admin.tb_roles r WHERE r.rol_codigo = 'ADM_BITACORA_VEHICULOS' OR r.rol_path = '/admin/bitacora-vehiculos')
 LIMIT 1;

-- Quien ya accede a vehículos o a órdenes de mantenimiento recibe la bitácora; también el administrador (parámetro SIS_ADMINISTRADORES)
INSERT INTO admin.tb_usuario_rol (fk_usuario_id, fk_rol_id)
SELECT DISTINCT u.usuario_id, b.rol_id
  FROM admin.tb_usuarios u
  JOIN admin.tb_roles b ON b.rol_codigo = 'ADM_BITACORA_VEHICULOS'
 WHERE (admin.fn_es_administrador(u.usuario_id)
        OR EXISTS (SELECT 1 FROM admin.tb_usuario_rol ur JOIN admin.tb_roles r ON r.rol_id = ur.fk_rol_id
                    WHERE ur.fk_usuario_id = u.usuario_id AND r.rol_codigo IN ('ADM_VEHICULOS', 'MANT_ORDENES')))
   AND NOT EXISTS (SELECT 1 FROM admin.tb_usuario_rol x WHERE x.fk_usuario_id = u.usuario_id AND x.fk_rol_id = b.rol_id);
