-- =============================================================================
-- CATÁLOGOS BASE (antes en script.sql, script-2.sql y script_sbj_temp.sql) - re-ejecutable
-- Cada catálogo se carga solo si su tabla está vacía (base nueva): no duplica filas renombradas por la institución.
-- Los menús (admin.tb_roles) se cargan por ruta. Las referencias a otros catálogos se buscan por nombre.
-- =============================================================================

-- operaciones.tb_estaciones: solo si está vacía
DO $catalogo$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM operaciones.tb_estaciones) THEN
        INSERT INTO operaciones.tb_estaciones (estacion_nombre, estacion_tipo) SELECT 'X-1', 'ESTACION'
         WHERE NOT EXISTS (SELECT 1 FROM operaciones.tb_estaciones x WHERE x.estacion_nombre IS NOT DISTINCT FROM 'X-1');
        INSERT INTO operaciones.tb_estaciones (estacion_nombre, estacion_tipo) SELECT 'X-2', 'ESTACION'
         WHERE NOT EXISTS (SELECT 1 FROM operaciones.tb_estaciones x WHERE x.estacion_nombre IS NOT DISTINCT FROM 'X-2');
        INSERT INTO operaciones.tb_estaciones (estacion_nombre, estacion_tipo) SELECT 'X-3', 'ESTACION'
         WHERE NOT EXISTS (SELECT 1 FROM operaciones.tb_estaciones x WHERE x.estacion_nombre IS NOT DISTINCT FROM 'X-3');
        INSERT INTO operaciones.tb_estaciones (estacion_nombre, estacion_tipo) SELECT 'X-4', 'ESTACION'
         WHERE NOT EXISTS (SELECT 1 FROM operaciones.tb_estaciones x WHERE x.estacion_nombre IS NOT DISTINCT FROM 'X-4');
        INSERT INTO operaciones.tb_estaciones (estacion_nombre, estacion_tipo) SELECT 'X-5', 'ESTACION'
         WHERE NOT EXISTS (SELECT 1 FROM operaciones.tb_estaciones x WHERE x.estacion_nombre IS NOT DISTINCT FROM 'X-5');
        INSERT INTO operaciones.tb_estaciones (estacion_nombre, estacion_tipo) SELECT 'X-6', 'ESTACION'
         WHERE NOT EXISTS (SELECT 1 FROM operaciones.tb_estaciones x WHERE x.estacion_nombre IS NOT DISTINCT FROM 'X-6');
        INSERT INTO operaciones.tb_estaciones (estacion_nombre, estacion_tipo) SELECT 'X-7', 'ESTACION'
         WHERE NOT EXISTS (SELECT 1 FROM operaciones.tb_estaciones x WHERE x.estacion_nombre IS NOT DISTINCT FROM 'X-7');
        INSERT INTO operaciones.tb_estaciones (estacion_nombre, estacion_tipo) SELECT 'X-8', 'ESTACION'
         WHERE NOT EXISTS (SELECT 1 FROM operaciones.tb_estaciones x WHERE x.estacion_nombre IS NOT DISTINCT FROM 'X-8');
        INSERT INTO operaciones.tb_estaciones (estacion_nombre, estacion_tipo) SELECT 'Grupo de Canes', 'GRUPO'
         WHERE NOT EXISTS (SELECT 1 FROM operaciones.tb_estaciones x WHERE x.estacion_nombre IS NOT DISTINCT FROM 'Grupo de Canes');
        INSERT INTO operaciones.tb_estaciones (estacion_nombre, estacion_tipo) SELECT 'Grupo de Drones', 'GRUPO'
         WHERE NOT EXISTS (SELECT 1 FROM operaciones.tb_estaciones x WHERE x.estacion_nombre IS NOT DISTINCT FROM 'Grupo de Drones');
        INSERT INTO operaciones.tb_estaciones (estacion_nombre, estacion_tipo) SELECT 'Escuela EFEESB', 'DIRECCION'
         WHERE NOT EXISTS (SELECT 1 FROM operaciones.tb_estaciones x WHERE x.estacion_nombre IS NOT DISTINCT FROM 'Escuela EFEESB');
    END IF;
END
$catalogo$;

-- tthh.tb_jornadas_trabajo: solo si está vacía
DO $catalogo$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM tthh.tb_jornadas_trabajo) THEN
        INSERT INTO tthh.tb_jornadas_trabajo (jornada_estado, jornada_nombre, jornada_rancho, jornada_diasminimo, jornada_diasmaximo, jornada_dias_semana, jornada_horas_dia, jornada_entrada, jornada_salida, jornada_break, jornada_entrada_break, jornada_salida_break) SELECT 'ACTIVO', 'OPERATIVOS 24H/48H', 6.00, 20, 20, '["1","2","3","4","5","6","0"]', 24, '08:00', '08:00', 'NO', NULL, NULL
         WHERE NOT EXISTS (SELECT 1 FROM tthh.tb_jornadas_trabajo x WHERE x.jornada_nombre IS NOT DISTINCT FROM 'OPERATIVOS 24H/48H');
        INSERT INTO tthh.tb_jornadas_trabajo (jornada_estado, jornada_nombre, jornada_rancho, jornada_diasminimo, jornada_diasmaximo, jornada_dias_semana, jornada_horas_dia, jornada_entrada, jornada_salida, jornada_break, jornada_entrada_break, jornada_salida_break) SELECT 'ACTIVO', 'ADMINISTRATIVO 8H', 0.00, 5, 10, '["1","2","3","4","5"]', 8, '08:00', '17:00', 'SI', '13:00', '14:00'
         WHERE NOT EXISTS (SELECT 1 FROM tthh.tb_jornadas_trabajo x WHERE x.jornada_nombre IS NOT DISTINCT FROM 'ADMINISTRATIVO 8H');
        INSERT INTO tthh.tb_jornadas_trabajo (jornada_estado, jornada_nombre, jornada_rancho, jornada_diasminimo, jornada_diasmaximo, jornada_dias_semana, jornada_horas_dia, jornada_entrada, jornada_salida, jornada_break, jornada_entrada_break, jornada_salida_break) SELECT 'ACTIVO', 'OPERATIVOS 8H', 3.00, 20, 20, '["1","2","3","4","5"]', 9, '08:00', '18:00', 'NO', NULL, NULL
         WHERE NOT EXISTS (SELECT 1 FROM tthh.tb_jornadas_trabajo x WHERE x.jornada_nombre IS NOT DISTINCT FROM 'OPERATIVOS 8H');
    END IF;
END
$catalogo$;

-- administrativo.tb_vehiculos_marcas: solo si está vacía
DO $catalogo$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM administrativo.tb_vehiculos_marcas) THEN
        INSERT INTO administrativo.tb_vehiculos_marcas (marca_nombre) SELECT 'S/M'
         WHERE NOT EXISTS (SELECT 1 FROM administrativo.tb_vehiculos_marcas x WHERE x.marca_nombre IS NOT DISTINCT FROM 'S/M');
    END IF;
END
$catalogo$;

-- archivo.direcciones: solo si está vacía
DO $catalogo$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM archivo.direcciones) THEN
        INSERT INTO archivo.direcciones (direccion_sigla, direccion_nombre_direccion) SELECT 'JB', 'Jefatura de Bomberos'
         WHERE NOT EXISTS (SELECT 1 FROM archivo.direcciones x WHERE x.direccion_sigla IS NOT DISTINCT FROM 'JB');
        INSERT INTO archivo.direcciones (direccion_sigla, direccion_nombre_direccion) SELECT 'DA', 'Dirección Administrativa'
         WHERE NOT EXISTS (SELECT 1 FROM archivo.direcciones x WHERE x.direccion_sigla IS NOT DISTINCT FROM 'DA');
        INSERT INTO archivo.direcciones (direccion_sigla, direccion_nombre_direccion) SELECT 'DJ', 'Dirección Jurídica'
         WHERE NOT EXISTS (SELECT 1 FROM archivo.direcciones x WHERE x.direccion_sigla IS NOT DISTINCT FROM 'DJ');
        INSERT INTO archivo.direcciones (direccion_sigla, direccion_nombre_direccion) SELECT 'DPCE', 'Dirección Planificación y Control Estratégico'
         WHERE NOT EXISTS (SELECT 1 FROM archivo.direcciones x WHERE x.direccion_sigla IS NOT DISTINCT FROM 'DPCE');
    END IF;
END
$catalogo$;

-- archivo.tipo_documentos: solo si está vacía
DO $catalogo$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM archivo.tipo_documentos) THEN
        INSERT INTO archivo.tipo_documentos (tipodocumento_tipo) SELECT 'Memorando'
         WHERE NOT EXISTS (SELECT 1 FROM archivo.tipo_documentos x WHERE x.tipodocumento_tipo IS NOT DISTINCT FROM 'Memorando');
        INSERT INTO archivo.tipo_documentos (tipodocumento_tipo) SELECT 'Informe'
         WHERE NOT EXISTS (SELECT 1 FROM archivo.tipo_documentos x WHERE x.tipodocumento_tipo IS NOT DISTINCT FROM 'Informe');
        INSERT INTO archivo.tipo_documentos (tipodocumento_tipo) SELECT 'Oficio'
         WHERE NOT EXISTS (SELECT 1 FROM archivo.tipo_documentos x WHERE x.tipodocumento_tipo IS NOT DISTINCT FROM 'Oficio');
    END IF;
END
$catalogo$;

-- admin.tb_modulos: solo si está vacía
DO $catalogo$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM admin.tb_modulos) THEN
        INSERT INTO admin.tb_modulos (modulo_nombre) SELECT 'ROOT'
         WHERE NOT EXISTS (SELECT 1 FROM admin.tb_modulos x WHERE x.modulo_nombre IS NOT DISTINCT FROM 'ROOT');
        INSERT INTO admin.tb_modulos (modulo_nombre) SELECT 'Dir. Administrativa'
         WHERE NOT EXISTS (SELECT 1 FROM admin.tb_modulos x WHERE x.modulo_nombre IS NOT DISTINCT FROM 'Dir. Administrativa');
        INSERT INTO admin.tb_modulos (modulo_nombre) SELECT 'Subjefatura'
         WHERE NOT EXISTS (SELECT 1 FROM admin.tb_modulos x WHERE x.modulo_nombre IS NOT DISTINCT FROM 'Subjefatura');
        INSERT INTO admin.tb_modulos (modulo_nombre) SELECT 'SCI'
         WHERE NOT EXISTS (SELECT 1 FROM admin.tb_modulos x WHERE x.modulo_nombre IS NOT DISTINCT FROM 'SCI');
        INSERT INTO admin.tb_modulos (modulo_nombre) SELECT 'Operaciones'
         WHERE NOT EXISTS (SELECT 1 FROM admin.tb_modulos x WHERE x.modulo_nombre IS NOT DISTINCT FROM 'Operaciones');
    END IF;
END
$catalogo$;

-- admin.tb_submodulos: solo si está vacía
DO $catalogo$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM admin.tb_submodulos) THEN
        INSERT INTO admin.tb_submodulos (fk_modulo_id, submodulo_nombre) SELECT (SELECT modulo_id FROM admin.tb_modulos WHERE modulo_nombre = 'Dir. Administrativa' ORDER BY modulo_id LIMIT 1), 'Unidades'
         WHERE NOT EXISTS (SELECT 1 FROM admin.tb_submodulos x WHERE x.submodulo_nombre IS NOT DISTINCT FROM 'Unidades');
        INSERT INTO admin.tb_submodulos (fk_modulo_id, submodulo_nombre) SELECT (SELECT modulo_id FROM admin.tb_modulos WHERE modulo_nombre = 'Dir. Administrativa' ORDER BY modulo_id LIMIT 1), 'Ordenes de movilización'
         WHERE NOT EXISTS (SELECT 1 FROM admin.tb_submodulos x WHERE x.submodulo_nombre IS NOT DISTINCT FROM 'Ordenes de movilización');
        INSERT INTO admin.tb_submodulos (fk_modulo_id, submodulo_nombre) SELECT (SELECT modulo_id FROM admin.tb_modulos WHERE modulo_nombre = 'Subjefatura' ORDER BY modulo_id LIMIT 1), 'Parámetros'
         WHERE NOT EXISTS (SELECT 1 FROM admin.tb_submodulos x WHERE x.submodulo_nombre IS NOT DISTINCT FROM 'Parámetros');
        INSERT INTO admin.tb_submodulos (fk_modulo_id, submodulo_nombre) SELECT (SELECT modulo_id FROM admin.tb_modulos WHERE modulo_nombre = 'Subjefatura' ORDER BY modulo_id LIMIT 1), 'Intervenciones'
         WHERE NOT EXISTS (SELECT 1 FROM admin.tb_submodulos x WHERE x.submodulo_nombre IS NOT DISTINCT FROM 'Intervenciones');
        INSERT INTO admin.tb_submodulos (fk_modulo_id, submodulo_nombre) SELECT (SELECT modulo_id FROM admin.tb_modulos WHERE modulo_nombre = 'Subjefatura' ORDER BY modulo_id LIMIT 1), 'Voluntarios'
         WHERE NOT EXISTS (SELECT 1 FROM admin.tb_submodulos x WHERE x.submodulo_nombre IS NOT DISTINCT FROM 'Voluntarios');
        INSERT INTO admin.tb_submodulos (fk_modulo_id, submodulo_nombre) SELECT (SELECT modulo_id FROM admin.tb_modulos WHERE modulo_nombre = 'Operaciones' ORDER BY modulo_id LIMIT 1), 'Distributivo'
         WHERE NOT EXISTS (SELECT 1 FROM admin.tb_submodulos x WHERE x.submodulo_nombre IS NOT DISTINCT FROM 'Distributivo');
        INSERT INTO admin.tb_submodulos (fk_modulo_id, submodulo_nombre) SELECT (SELECT modulo_id FROM admin.tb_modulos WHERE modulo_nombre = 'Operaciones' ORDER BY modulo_id LIMIT 1), 'Partes de servicio'
         WHERE NOT EXISTS (SELECT 1 FROM admin.tb_submodulos x WHERE x.submodulo_nombre IS NOT DISTINCT FROM 'Partes de servicio');
    END IF;
END
$catalogo$;

-- admin.tb_roles (por ruta)
INSERT INTO admin.tb_roles (rol_nombre, rol_descripcion, fk_submodulo_id, rol_path) SELECT 'Vehiculos', 'Administrar vehiculos', (SELECT submodulo_id FROM admin.tb_submodulos WHERE submodulo_nombre = 'Unidades' ORDER BY submodulo_id LIMIT 1), '/admin/vehiculos'
 WHERE NOT EXISTS (SELECT 1 FROM admin.tb_roles x WHERE x.rol_path IS NOT DISTINCT FROM '/admin/vehiculos');
INSERT INTO admin.tb_roles (rol_nombre, rol_descripcion, fk_submodulo_id, rol_path) SELECT 'Ordenes de Movilizacion', 'Administrar ordenes de movilizacion', (SELECT submodulo_id FROM admin.tb_submodulos WHERE submodulo_nombre = 'Ordenes de movilización' ORDER BY submodulo_id LIMIT 1), '/admin/ordenes-movilizacion'
 WHERE NOT EXISTS (SELECT 1 FROM admin.tb_roles x WHERE x.rol_path IS NOT DISTINCT FROM '/admin/ordenes-movilizacion');
INSERT INTO admin.tb_roles (rol_nombre, rol_descripcion, fk_submodulo_id, rol_path) SELECT 'Ingresar nuevo vehiculo', 'Poder registrar nuevas unidades', (SELECT submodulo_id FROM admin.tb_submodulos WHERE submodulo_nombre = 'Unidades' ORDER BY submodulo_id LIMIT 1), null
 WHERE NOT EXISTS (SELECT 1 FROM admin.tb_roles x WHERE x.rol_nombre IS NOT DISTINCT FROM 'Ingresar nuevo vehiculo');
INSERT INTO admin.tb_roles (rol_nombre, rol_descripcion, fk_submodulo_id, rol_path) SELECT 'Estadisticas', 'Estadisticas operaticas', (SELECT submodulo_id FROM admin.tb_submodulos WHERE submodulo_nombre = 'Parámetros' ORDER BY submodulo_id LIMIT 1), '/sbj/dashboard'
 WHERE NOT EXISTS (SELECT 1 FROM admin.tb_roles x WHERE x.rol_path IS NOT DISTINCT FROM '/sbj/dashboard');
INSERT INTO admin.tb_roles (rol_nombre, rol_descripcion, fk_submodulo_id, rol_path) SELECT 'Intervenciones', 'Administración de intervenciones de emergencias', (SELECT submodulo_id FROM admin.tb_submodulos WHERE submodulo_nombre = 'Intervenciones' ORDER BY submodulo_id LIMIT 1), '/sbj/intervenciones'
 WHERE NOT EXISTS (SELECT 1 FROM admin.tb_roles x WHERE x.rol_path IS NOT DISTINCT FROM '/sbj/intervenciones');
INSERT INTO admin.tb_roles (rol_nombre, rol_descripcion, fk_submodulo_id, rol_path) SELECT 'Ausencias', 'Registros de ausencias del presonal', (SELECT submodulo_id FROM admin.tb_submodulos WHERE submodulo_nombre = 'Parámetros' ORDER BY submodulo_id LIMIT 1), '/sbj/ausencias'
 WHERE NOT EXISTS (SELECT 1 FROM admin.tb_roles x WHERE x.rol_path IS NOT DISTINCT FROM '/sbj/ausencias');
INSERT INTO admin.tb_roles (rol_nombre, rol_descripcion, fk_submodulo_id, rol_path) SELECT 'Voluntarios', 'Registros de voluntarios', (SELECT submodulo_id FROM admin.tb_submodulos WHERE submodulo_nombre = 'Voluntarios' ORDER BY submodulo_id LIMIT 1), '/sbj/ubv-voluntarios'
 WHERE NOT EXISTS (SELECT 1 FROM admin.tb_roles x WHERE x.rol_path IS NOT DISTINCT FROM '/sbj/ubv-voluntarios');
INSERT INTO admin.tb_roles (rol_nombre, rol_descripcion, fk_submodulo_id, rol_path) SELECT 'UBV Actividades', 'Registros de actividades de personal voluntario', (SELECT submodulo_id FROM admin.tb_submodulos WHERE submodulo_nombre = 'Voluntarios' ORDER BY submodulo_id LIMIT 1), '/sbj/ubv-actividades'
 WHERE NOT EXISTS (SELECT 1 FROM admin.tb_roles x WHERE x.rol_path IS NOT DISTINCT FROM '/sbj/ubv-actividades');
INSERT INTO admin.tb_roles (rol_nombre, rol_descripcion, fk_submodulo_id, rol_path) SELECT 'UBV Eventos', 'Registros de eventos de personal voluntario', (SELECT submodulo_id FROM admin.tb_submodulos WHERE submodulo_nombre = 'Voluntarios' ORDER BY submodulo_id LIMIT 1), '/sbj/ubv-eventos'
 WHERE NOT EXISTS (SELECT 1 FROM admin.tb_roles x WHERE x.rol_path IS NOT DISTINCT FROM '/sbj/ubv-eventos');
INSERT INTO admin.tb_roles (rol_nombre, rol_descripcion, fk_submodulo_id, rol_path) SELECT 'Distributivo', 'Administrar distributivos de personal', (SELECT submodulo_id FROM admin.tb_submodulos WHERE submodulo_nombre = 'Distributivo' ORDER BY submodulo_id LIMIT 1), '/operaciones/distributivo'
 WHERE NOT EXISTS (SELECT 1 FROM admin.tb_roles x WHERE x.rol_path IS NOT DISTINCT FROM '/operaciones/distributivo');
INSERT INTO admin.tb_roles (rol_nombre, rol_descripcion, fk_submodulo_id, rol_path) SELECT 'Partes de servicio', 'Administrar partes de servicio', (SELECT submodulo_id FROM admin.tb_submodulos WHERE submodulo_nombre = 'Partes de servicio' ORDER BY submodulo_id LIMIT 1), '/operaciones/partes'
 WHERE NOT EXISTS (SELECT 1 FROM admin.tb_roles x WHERE x.rol_path IS NOT DISTINCT FROM '/operaciones/partes');

-- subjefatura.tb_aph_hojaruta_tipoemergencia: solo si está vacía
DO $catalogo$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM subjefatura.tb_aph_hojaruta_tipoemergencia) THEN
        INSERT INTO subjefatura.tb_aph_hojaruta_tipoemergencia (aph_hojaruta_tipoemergencia_descripcion) SELECT 'TRASLADO DE PACIENTE'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_aph_hojaruta_tipoemergencia x WHERE x.aph_hojaruta_tipoemergencia_descripcion IS NOT DISTINCT FROM 'TRASLADO DE PACIENTE');
        INSERT INTO subjefatura.tb_aph_hojaruta_tipoemergencia (aph_hojaruta_tipoemergencia_descripcion) SELECT 'ATROPELLAMIENTO'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_aph_hojaruta_tipoemergencia x WHERE x.aph_hojaruta_tipoemergencia_descripcion IS NOT DISTINCT FROM 'ATROPELLAMIENTO');
        INSERT INTO subjefatura.tb_aph_hojaruta_tipoemergencia (aph_hojaruta_tipoemergencia_descripcion) SELECT 'OBSTETRICA'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_aph_hojaruta_tipoemergencia x WHERE x.aph_hojaruta_tipoemergencia_descripcion IS NOT DISTINCT FROM 'OBSTETRICA');
    END IF;
END
$catalogo$;

-- subjefatura.tb_tipoincidencia: solo si está vacía
DO $catalogo$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoincidencia) THEN
        INSERT INTO subjefatura.tb_tipoincidencia (incidencia_descripcion) SELECT 'INCENDIO'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoincidencia x WHERE x.incidencia_descripcion IS NOT DISTINCT FROM 'INCENDIO');
        INSERT INTO subjefatura.tb_tipoincidencia (incidencia_descripcion) SELECT 'AUXILIO'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoincidencia x WHERE x.incidencia_descripcion IS NOT DISTINCT FROM 'AUXILIO');
        INSERT INTO subjefatura.tb_tipoincidencia (incidencia_descripcion) SELECT 'ATENCION PRE HOSPITALARIA'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoincidencia x WHERE x.incidencia_descripcion IS NOT DISTINCT FROM 'ATENCION PRE HOSPITALARIA');
    END IF;
END
$catalogo$;

-- subjefatura.tb_tipoemergencia: solo si está vacía
DO $catalogo$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia) THEN
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), 'Declarado'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Declarado');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), 'Incendio'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Incendio');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), 'Amago'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Amago');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), 'Forestal'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Forestal');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), 'Fuga de gas'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Fuga de gas');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), 'Simulacro'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Simulacro');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), 'Inspección con Sirena – Baliza'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Inspección con Sirena – Baliza');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), 'Inspección sin Sirena – Baliza'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Inspección sin Sirena – Baliza');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), 'Falsa Alarma'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Falsa Alarma');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), 'Incendio / apoyo '
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Incendio / apoyo ');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Rescate'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Rescate');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Inundación'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Inundación');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Traslado de ambulancia'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Traslado de ambulancia');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Deslizamiento de tierra'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Deslizamiento de tierra');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Simulacro en Rescate'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Simulacro en Rescate');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Rescate / apoyo'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Rescate / apoyo');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Inundación (apoyo)'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Inundación (apoyo)');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Traslado de paciente'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Traslado de paciente');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Desfile'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Desfile');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Simulacro en Evacuación'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Simulacro en Evacuación');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Salvamento'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Salvamento');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Accidente de transito'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Accidente de transito');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Soporte Vital'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Soporte Vital');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Abrir departamento'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Abrir departamento');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Reparto de agua'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Reparto de agua');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Capacitación'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Capacitación');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Baldeo'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Baldeo');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Evacuación'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Evacuación');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Accidente Aviatorio'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Accidente Aviatorio');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Caída de arboles'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Caída de arboles');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Inspección con Sirena – Baliza'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Inspección con Sirena – Baliza');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Inspección sin Sirena – Baliza'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Inspección sin Sirena – Baliza');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Apoyo'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Apoyo');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Auxilio General'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Auxilio General');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1), 'Traslado de paciente'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Traslado de paciente');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1), 'Salvamento'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Salvamento');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1), 'Soporte Vital'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Soporte Vital');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1), 'Accidente Aviatorio'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Accidente Aviatorio');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1), 'Inspección con Sirena – Baliza'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Inspección con Sirena – Baliza');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1), 'Inspección sin Sirena – Baliza'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Inspección sin Sirena – Baliza');
        INSERT INTO subjefatura.tb_tipoemergencia (fk_incidencia_id, emergencia_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1), 'Auxilio General'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_tipoemergencia x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1) AND x.emergencia_descripcion IS NOT DISTINCT FROM 'Auxilio General');
    END IF;
END
$catalogo$;

-- subjefatura.tb_causas: solo si está vacía
DO $catalogo$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas) THEN
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Desconocida'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Desconocida');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Derrame de combustible'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Derrame de combustible');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Eléctrica'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Eléctrica');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Accidente de transito'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Accidente de transito');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Intencional'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Intencional');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Explosión'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Explosión');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Rayo'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Rayo');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Desprendimiento de chispa'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Desprendimiento de chispa');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Imprevisión'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Imprevisión');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Fuga de gas'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Fuga de gas');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Maniobras militares'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Maniobras militares');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Propagación de incendio'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Propagación de incendio');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Descuido'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Descuido');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Combustión espontanea'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Combustión espontanea');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Quema agrícola'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Quema agrícola');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Quema de basura'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Quema de basura');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Instruir a la ciudadanía'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Instruir a la ciudadanía');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Vehicular'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Vehicular');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Caída'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Caída');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Combustible derramado'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Combustible derramado');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Choque'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Choque');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Parto'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Parto');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Evaluación Primaria'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Evaluación Primaria');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Daño de tubería'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Daño de tubería');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Escasez de agua'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Escasez de agua');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Atropellamiento'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Atropellamiento');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Intoxicación'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Intoxicación');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Apuñalamiento'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Apuñalamiento');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Acumulación de agua'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Acumulación de agua');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Caída a pozo de agua'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Caída a pozo de agua');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Volcamiento'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Volcamiento');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Quemaduras'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Quemaduras');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Traslado de animales'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Traslado de animales');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Estado Etílico'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Estado Etílico');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Instruir a la ciudadanía'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Instruir a la ciudadanía');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Traumatismo'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Traumatismo');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Enfermedad'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Enfermedad');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Olvido de llaves'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Olvido de llaves');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Picadura de animales'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Picadura de animales');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Mordedura de animales'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Mordedura de animales');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Material solido derramado'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Material solido derramado');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Acto Cívico'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Acto Cívico');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), '10.', 'Otro'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'Otro');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1), '10.', 'ATROPELLAMIENTO'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'ATROPELLAMIENTO');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1), '10.', 'TRAUMATISMO'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'TRAUMATISMO');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1), '10.', 'QUEMADURAS'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'QUEMADURAS');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1), '10.', 'INTOXICACIÓN'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'INTOXICACIÓN');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1), '10.', 'PARTO'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'PARTO');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1), '10.', 'APUÑALAMIENTO'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'APUÑALAMIENTO');
        INSERT INTO subjefatura.tb_causas (fk_incidencia_id, causa_codigo, causa_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1), '10.', 'EVALUACIÓN PRIMARIA'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_causas x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1) AND x.causa_codigo IS NOT DISTINCT FROM '10.' AND x.causa_descripcion IS NOT DISTINCT FROM 'EVALUACIÓN PRIMARIA');
    END IF;
END
$catalogo$;

-- subjefatura.tb_naturaleza: solo si está vacía
DO $catalogo$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza) THEN
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), 'Vivienda'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Vivienda');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), 'Clandestino'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Clandestino');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), 'Terreno baldío'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Terreno baldío');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), 'Panadería'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Panadería');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), 'Industria'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Industria');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), 'Mecánica'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Mecánica');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), 'Bosque / Campo'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Bosque / Campo');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), 'Iglesia'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Iglesia');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), 'Comercio'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Comercio');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), 'Restaurante'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Restaurante');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), 'Centro Comercial'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Centro Comercial');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), 'Aserradero'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Aserradero');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), 'Vehículo'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Vehículo');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), 'Est. De Servicio'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Est. De Servicio');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), 'Edificio oficinas'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Edificio oficinas');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1), 'Otros'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'INCENDIO' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Otros');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Vivienda'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Vivienda');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Vía pública'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Vía pública');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Casa de Salud'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Casa de Salud');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Escenario deportivo'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Escenario deportivo');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Concentración  pública'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Concentración  pública');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Institución'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Institución');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Pozo de agua'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Pozo de agua');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Campo y bosque'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Campo y bosque');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Carretera'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Carretera');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1), 'Otro'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'AUXILIO' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Otro');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1), 'Vivienda'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Vivienda');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1), 'Vía pública'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Vía pública');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1), 'Casa de Salud'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Casa de Salud');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1), 'Escenario deportivo'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Escenario deportivo');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1), 'Concentración  pública'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Concentración  pública');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1), 'Institución'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Institución');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1), 'Pozo de agua'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Pozo de agua');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1), 'Campo y bosque'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Campo y bosque');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1), 'Carretera'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Carretera');
        INSERT INTO subjefatura.tb_naturaleza (fk_incidencia_id, naturaleza_descripcion) SELECT (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1), 'Otro'
         WHERE NOT EXISTS (SELECT 1 FROM subjefatura.tb_naturaleza x WHERE x.fk_incidencia_id IS NOT DISTINCT FROM (SELECT incidencia_id FROM subjefatura.tb_tipoincidencia WHERE incidencia_descripcion = 'ATENCION PRE HOSPITALARIA' ORDER BY incidencia_id LIMIT 1) AND x.naturaleza_descripcion IS NOT DISTINCT FROM 'Otro');
    END IF;
END
$catalogo$;

-- Catálogos de partes de servicio
INSERT INTO operaciones.tb_partes_catalogo_tipos_incendio (
    tipo_incendio_codigo,
    tipo_incendio_descripcion
) VALUES
    ('DECLARADO', 'Declarado'),
    ('INCENDIO', 'Incendio'),
    ('AMAGO', 'Amago'),
    ('FORESTAL', 'Forestal'),
    ('FUGA_GAS', 'Fuga de gas'),
    ('INSPECCION_SIRENA_BALIZA', 'Inspección con sirena - baliza'),
    ('INSPECCION_SIN_SIRENA_BALIZA', 'Inspección sin sirena - baliza'),
    ('FALSA_ALARMA', 'Falsa alarma'),
    ('SIMULACRO', 'Simulacro'),
    ('INCENDIO_APOYO', 'Incendio / apoyo')
ON CONFLICT (tipo_incendio_codigo) DO NOTHING;

INSERT INTO operaciones.tb_partes_catalogo_causas_incendio (
    causa_incendio_codigo,
    causa_incendio_descripcion
) VALUES
    ('DESCONOCIDA', 'Desconocida'),
    ('DERRAME_COMBUSTIBLE', 'Derrame de combustible'),
    ('ELECTRICA', 'Eléctrica'),
    ('ACCIDENTE_TRANSITO', 'Accidente de tránsito'),
    ('INTENCIONAL', 'Intencional'),
    ('EXPLOSION', 'Explosión'),
    ('RAYO', 'Rayo'),
    ('DESPRENDIMIENTO_CHISPAS', 'Desprendimiento de chispas'),
    ('IMPREVISION', 'Imprevisión'),
    ('FUGA_GAS', 'Fuga de gas'),
    ('MANIOBRAS_MILITARES', 'Maniobras militares'),
    ('PROPAGACION_INCENDIO', 'Propagación de incendio'),
    ('DESCUIDO', 'Descuido'),
    ('COMBUSTION_ESPONTANEA', 'Combustión espontánea'),
    ('QUEMA_AGRICOLA', 'Quema agrícola'),
    ('QUEMA_BASURA', 'Quema de basura'),
    ('INSTRUIR_CIUDADANIA', 'Instruir a la ciudadanía'),
    ('VEHICULAR', 'Vehicular')
ON CONFLICT (causa_incendio_codigo) DO NOTHING;

INSERT INTO operaciones.tb_partes_catalogo_naturalezas (
    naturaleza_codigo,
    naturaleza_descripcion
) VALUES
    ('VIVIENDA', 'Vivienda'),
    ('CLANDESTINO', 'Clandestino'),
    ('TERRENO_BALDIO', 'Terreno baldío'),
    ('PANADERIA', 'Panadería'),
    ('INDUSTRIA', 'Industria'),
    ('MECANICA', 'Mecánica'),
    ('BOSQUE_CAMPO', 'Bosque / campo'),
    ('IGLESIA', 'Iglesia'),
    ('COMERCIO', 'Comercio'),
    ('RESTAURANTE', 'Restaurante'),
    ('CENTRO_COMERCIAL', 'Centro comercial'),
    ('ASERRADERO', 'Aserradero'),
    ('VEHICULO', 'Vehículo'),
    ('ESTACION_SERVICIO', 'Estación de servicio'),
    ('EDIFICIO_OFICINAS', 'Edificio de oficinas'),
    ('OTROS', 'Otros')
ON CONFLICT (naturaleza_codigo) DO NOTHING;

INSERT INTO operaciones.tb_partes_catalogo_causas_afectacion_humana (
    causa_afectacion_humana_codigo,
    causa_afectacion_humana_descripcion
) VALUES
    ('ASFIXIA', 'Asfixia'),
    ('QUEMADURAS', 'Quemaduras'),
    ('CAIDA', 'Caída'),
    ('OTRAS', 'Otras')
ON CONFLICT (causa_afectacion_humana_codigo) DO NOTHING;

INSERT INTO operaciones.tb_partes_catalogo_tipo_afectado (
    tipo_afectado_codigo,
    tipo_afectado_descripcion
) VALUES
    ('PROPIO', 'Propio'),
    ('ARRENDADO', 'Arrendado')
ON CONFLICT (tipo_afectado_codigo) DO NOTHING;

INSERT INTO operaciones.tb_partes_catalogo_forma_aviso (
    forma_aviso_codigo,
    forma_aviso_descripcion
) VALUES
    ('CR', 'Central de radio'),
    ('CABINA_RADIO', 'Cabina de radio'),
    ('TELEFONO', 'Teléfono'),
    ('PERSONAL', 'Personal')
ON CONFLICT (forma_aviso_codigo) DO NOTHING;

INSERT INTO operaciones.tb_partes_catalogo_apoyo (
    apoyo_codigo,
    apoyo_descripcion
) VALUES
    ('POLICIA', 'Policía'),
    ('CRUZ_ROJA', 'Cruz Roja'),
    ('EJERCITO', 'Ejército'),
    ('PERSONAS_PARTICULARES', 'Personas particulares'),
    ('OTROS', 'Otros')
ON CONFLICT (apoyo_codigo) DO NOTHING;

INSERT INTO operaciones.tb_partes_catalogo_tipos_auxilio (
    tipo_auxilio_clave,
    tipo_auxilio_clasificacion,
    tipo_auxilio_subclasificacion,
    tipo_auxilio_uso_tipo
) VALUES
    ('10-1', 'Auxilio', 'Evacuación', 'Menaje + personas'),
    ('10-1', 'Auxilio', 'Tala de árboles', '')
ON CONFLICT (
    tipo_auxilio_clave,
    tipo_auxilio_clasificacion,
    tipo_auxilio_subclasificacion,
    tipo_auxilio_uso_tipo
) DO NOTHING;
