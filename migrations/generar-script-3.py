#!/usr/bin/env python3
"""
Genera script-3.sql (raíz del API): el ÚNICO script de la base de datos (estructura base, catálogos, módulos,
importación opcional y administradores), para pegar en pgAdmin sobre una base vacía o existente. Ejecutar desde la raíz del API:
    python3 migrations/generar-script-3.py
"""
import re
from pathlib import Path

raiz = Path(__file__).resolve().parent.parent
leer = lambda r: (raiz / r).read_text(encoding='utf-8').strip() + '\n'


def importacion_como_bloque(base: str, sql: str) -> str:
    """Un solo bloque DO (para pgAdmin) con la importación de datos base (base/03) y la de mantenimiento (mantenimiento/03)."""
    base = re.sub(r'^--[^\n]*\n', '', base, flags=re.M).strip()
    cuerpo = '-- Datos base: personas, personal, usuarios, vehículos, ubicaciones, CIE-10\n' + base + '\n\n-- Mantenimiento vehicular\n' \
        + sql[sql.index('BEGIN;') + len('BEGIN;'):sql.index('COMMIT;')]
    cuerpo = re.sub(r'^SELECT setval\(', 'PERFORM setval(', cuerpo, flags=re.M)
    cuerpo = '\n'.join('        ' + l if l.strip() else '' for l in cuerpo.strip('\n').split('\n'))
    return f"""CREATE EXTENSION IF NOT EXISTS dblink;

DO $importacion$
DECLARE
    -- >>> EDITE ESTA LÍNEA con los datos de la base del sistema anterior (db_cbsd). Si la deja con CAMBIAR, se omite.
    conexion text := 'dbname=db_cbsd host=localhost port=5432 user=postgres password=CAMBIAR';
    antes_ordenes integer;
    antes_informes integer;
    total_ordenes integer;
    total_informes integer;
    contexto text;
BEGIN
    IF conexion LIKE '%CAMBIAR%' THEN
        RAISE NOTICE 'Importación desde db_cbsd OMITIDA: edite la variable "conexion" para ejecutarla.';
        RETURN;
    END IF;
    -- pgAdmin conserva la sesión: si una ejecución anterior se detuvo con la conexión abierta, se cierra primero
    IF 'legacy' = ANY (COALESCE(dblink_get_connections(), '{{}}'::text[])) THEN
        PERFORM dblink_disconnect('legacy');
    END IF;
    PERFORM dblink_connect('legacy', conexion);
    BEGIN
{cuerpo}

        SELECT n INTO total_ordenes FROM dblink('legacy', 'SELECT count(*) FROM logistica.tb_ordenesmantenimiento') AS t(n integer);
        SELECT n INTO total_informes FROM dblink('legacy', 'SELECT count(*) FROM logistica.tb_informemantenimiento') AS t(n integer);
        SELECT count(*) INTO antes_ordenes FROM logistica.tb_ordenesmantenimiento WHERE fk_contrato_id IS NULL;
        SELECT count(*) INTO antes_informes FROM logistica.tb_informemantenimiento WHERE fk_contrato_id IS NULL;
        RAISE NOTICE 'Importación terminada. Órdenes en db_cbsd: %, sin contrato en la base nueva: %. Informes en db_cbsd: %, en la base nueva: %.',
            total_ordenes, antes_ordenes, total_informes, antes_informes;
    EXCEPTION WHEN OTHERS THEN
        -- Siempre se cierra la conexión y se indica en qué paso se detuvo (no queda nada a medias de esta importación)
        GET STACKED DIAGNOSTICS contexto = PG_EXCEPTION_CONTEXT;
        PERFORM dblink_disconnect('legacy');
        RAISE EXCEPTION 'Importación desde db_cbsd detenida: % (código %)', SQLERRM, SQLSTATE
            USING HINT = 'No se guardó nada de la importación. Paso: ' || split_part(contexto, E'\n', 1)
                         || '. Corrija y vuelva a ejecutar el script (se puede ejecutar varias veces).';
    END;
    PERFORM dblink_disconnect('legacy');
END
$importacion$;
"""


secciones = [
    ("0. ESTRUCTURA BASE: esquemas, tablas y vistas (antes script.sql, script-2.sql y script_sbj_temp.sql)",
     leer('migrations/base/01-estructura.sql')),
    ("0.1 CATÁLOGOS BASE: estaciones, jornadas, menús, documentos y catálogos de subjefatura y partes",
     leer('migrations/base/02-catalogos.sql')),
    ("1. ÓRDENES DE ABASTECIMIENTO DE COMBUSTIBLE (rama joshua)",
     leer('migrations/ordenes-abastecimiento/tabla-ordenes-establecimientos.sql') + '\n' +
     leer('migrations/ordenes-abastecimiento/tabla-detalle-ordenes-establecimientos.sql')),
    ("2. PARAMETRIZACIÓN DE LA INSTITUCIÓN (admin.tb_sistema, admin.tb_params)", leer('migrations/mantenimiento/01-institucion.sql')),
    ("3. MANTENIMIENTO VEHICULAR (planes, contratos, órdenes, bitácoras, vistas)", leer('migrations/mantenimiento/02-mantenimiento.sql')),
    ("4. MENÚS Y PRIVILEGIOS (admin.tb_roles con rol_codigo)", leer('migrations/mantenimiento/04-privilegios.sql')),
    ("5. BITÁCORA DEL VEHÍCULO (galones con decimales, índices, parámetros de alertas, privilegio)",
     leer('migrations/mantenimiento/05-bitacora.sql')),
    ("6. OPERADORES (catálogo de licencias, parámetros y privilegios)",
     leer('migrations/operadores/01-operadores.sql')),
    ("7. USUARIOS Y PERFILES (privilegios por perfil, menú de administración, claves)",
     leer('migrations/admin/01-usuarios-perfiles.sql')),
    ("8. PETICIÓN DE MATERIALES Y RESUMEN GERENCIAL (servicios generales)",
     leer('migrations/servicios-generales/01-peticion-materiales.sql') + '\n' +
     leer('migrations/servicios-generales/02-resumen-gerencial.sql')),
    ("9. REVISIÓN: borrado lógico de documentos de archivo",
     leer('migrations/revision/01-borrado-logico.sql')),
    ("10. PARTES DE SERVICIO (Operaciones): catálogos del formato, enlaces para estadística y privilegios",
     leer('migrations/operaciones/01-partes-servicio.sql')),
    ("11. IMPORTACIÓN DESDE EL SISTEMA ANTERIOR (db_cbsd) - opcional",
     importacion_como_bloque(leer('migrations/base/03-importacion-sistema-anterior.sql'), leer('migrations/mantenimiento/03-importacion-db_cbsd.sql'))),
    ("12. REGISTRO INICIAL DE LA INSTITUCIÓN Y USUARIO ADMINISTRADOR (solo si no se importaron ni existen)", """INSERT INTO admin.tb_sistema (sistema_nombre, sistema_siglas, sistema_slogan, sistema_ciudad, sistema_direccion,
                              sistema_telefono, sistema_correo, sistema_sitioweb, sistema_facebook, sistema_twitter)
SELECT 'CUERPO DE BOMBEROS SANTO DOMINGO', 'CBSD', 'Juntos hacia el crecimiento institucional', 'Santo Domingo',
       'Av. Jacinto Cortez y Jorge Icaza', '(02) 3959-340', 'info@cbsd.gob.ec', 'http://bomberosantodomingo.gob.ec',
       '/CuerpoDeBomberosSantoDomingo', '@BomberosSD'
 WHERE NOT EXISTS (SELECT 1 FROM admin.tb_sistema);
-- Completar siglas/slogan/redes del registro importado si vinieron vacíos
UPDATE admin.tb_sistema SET sistema_slogan = COALESCE(sistema_slogan, 'Juntos hacia el crecimiento institucional'),
                            sistema_facebook = COALESCE(sistema_facebook, '/CuerpoDeBomberosSantoDomingo'),
                            sistema_twitter = COALESCE(sistema_twitter, '@BomberosSD');
-- Base nueva sin usuarios: perfil Administrador y usuario "admin" (la clave del script anterior; se pide cambiarla al entrar)
INSERT INTO admin.tb_perfiles (perfil_nombre, perfil_descripcion)
SELECT 'Administrador', 'Administrador del Sistema'
 WHERE NOT EXISTS (SELECT 1 FROM admin.tb_usuarios)
   AND NOT EXISTS (SELECT 1 FROM admin.tb_perfiles WHERE upper(trim(perfil_nombre)) = 'ADMINISTRADOR');
INSERT INTO resources.tb_personas (persona_doc_identidad, persona_nombres, persona_apellidos)
SELECT '9999999999', 'ADMINISTRADOR', 'ADMINISTRADOR'
 WHERE NOT EXISTS (SELECT 1 FROM admin.tb_usuarios)
   AND NOT EXISTS (SELECT 1 FROM resources.tb_personas WHERE persona_doc_identidad = '9999999999');
INSERT INTO admin.tb_usuarios (fk_persona_id, fk_perfil_id, usuario_login, usuario_pass, usuario_cambiar_pass)
SELECT (SELECT persona_id FROM resources.tb_personas WHERE persona_doc_identidad = '9999999999' ORDER BY persona_id LIMIT 1),
       (SELECT perfil_id FROM admin.tb_perfiles WHERE upper(trim(perfil_nombre)) = 'ADMINISTRADOR' ORDER BY perfil_id LIMIT 1),
       'admin', '$2y$10$C64q4N9kT3MqHUyzmqjpIe2x8/GGYSgIK2ZjDmthuP2NasZqazLxO', true
 WHERE NOT EXISTS (SELECT 1 FROM admin.tb_usuarios);
"""),
    ("13. MENÚ ORDENADO Y AGRUPADO (Panel, Parámetros, Gestión...), privilegio APH y pantallas en desuso",
     leer('migrations/admin/03-menu.sql')),
    ("14. ACCESO DE LOS ADMINISTRADORES (todos los privilegios; parámetros SIS_ADMINISTRADORES y SIS_PERFILES_ADMINISTRADOR)",
     leer('migrations/admin/02-acceso-administradores.sql')),
]

encabezado = """-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- SCRIPT 3: ÚNICO SCRIPT DE LA BASE DE DATOS (reemplaza a script.sql, script-2.sql y script_sbj_temp.sql)
--   Estructura base, catálogos, combustible, institución, mantenimiento vehicular, contratos, menús y privilegios,
--   bitácora, operadores, usuarios y perfiles, servicios generales, partes de servicio e importación de db_cbsd.
--
-- CÓMO USARLO (pgAdmin): abra el Query Tool sobre la base (db_bcbsd), pegue TODO el archivo y ejecútelo.
--   * Sirve para una base VACÍA (la crea completa) y para una base EXISTENTE (solo agrega lo que falta).
--   * Se puede ejecutar varias veces: no borra tablas ni datos; lo que ya existe se omite.
--   * La importación (sección 11) solo corre si edita la línea "conexion" con la clave de la base anterior.
--   * Base nueva sin importar: se crea el usuario "admin" (perfil Administrador); cambie su clave al entrar.
--   * Después: asigne los privilegios nuevos a los usuarios en Administración > Usuarios > Privilegios.
--
-- ARCHIVO GENERADO por migrations/generar-script-3.py a partir de migrations/. No lo edite a mano:
-- edite los archivos de migrations/ y vuelva a generarlo.
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
"""
partes = [encabezado]
for titulo, sql in secciones:
    partes.append(f"\n-- ======================================================================================================\n-- {titulo}\n-- ======================================================================================================\n{sql}")
(raiz / 'script-3.sql').write_text('\n'.join(partes), encoding='utf-8')
print('script-3.sql generado:', sum(p.count('\n') for p in partes), 'líneas')
