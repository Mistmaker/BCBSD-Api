#!/usr/bin/env python3
"""
Genera script-3.sql (raíz del API): un solo archivo para copiar y pegar en pgAdmin con todos los cambios
posteriores a script.sql / script-2.sql / script_sbj_temp.sql. Ejecutar desde la raíz del API:
    python3 migrations/generar-script-3.py
"""
import re
from pathlib import Path

raiz = Path(__file__).resolve().parent.parent
leer = lambda r: (raiz / r).read_text(encoding='utf-8').strip() + '\n'


def importacion_como_bloque(sql: str) -> str:
    """Convierte 03-importacion-db_cbsd.sql (para psql) en un bloque DO que se puede pegar en pgAdmin."""
    cuerpo = sql[sql.index('BEGIN;') + len('BEGIN;'):sql.index('COMMIT;')]
    cuerpo = re.sub(r'^SELECT setval\(', 'PERFORM setval(', cuerpo, flags=re.M)
    cuerpo = '\n'.join('    ' + l if l.strip() else '' for l in cuerpo.strip('\n').split('\n'))
    return f"""CREATE EXTENSION IF NOT EXISTS dblink;

DO $importacion$
DECLARE
    -- >>> EDITE ESTA LÍNEA con los datos de la base del sistema anterior (db_cbsd). Si la deja con CAMBIAR, se omite.
    conexion text := 'dbname=db_cbsd host=localhost port=5432 user=postgres password=CAMBIAR';
    antes_ordenes integer;
    antes_informes integer;
    total_ordenes integer;
    total_informes integer;
BEGIN
    IF conexion LIKE '%CAMBIAR%' THEN
        RAISE NOTICE 'Importación desde db_cbsd OMITIDA: edite la variable "conexion" para ejecutarla.';
        RETURN;
    END IF;
    PERFORM dblink_connect('legacy', conexion);

{cuerpo}

    SELECT n INTO total_ordenes FROM dblink('legacy', 'SELECT count(*) FROM logistica.tb_ordenesmantenimiento') AS t(n integer);
    SELECT n INTO total_informes FROM dblink('legacy', 'SELECT count(*) FROM logistica.tb_informemantenimiento') AS t(n integer);
    SELECT count(*) INTO antes_ordenes FROM logistica.tb_ordenesmantenimiento WHERE fk_contrato_id IS NULL;
    SELECT count(*) INTO antes_informes FROM logistica.tb_informemantenimiento WHERE fk_contrato_id IS NULL;
    RAISE NOTICE 'Importación terminada. Órdenes en db_cbsd: %, sin contrato en la base nueva: %. Informes en db_cbsd: %, en la base nueva: %.',
        total_ordenes, antes_ordenes, total_informes, antes_informes;
    PERFORM dblink_disconnect('legacy');
END
$importacion$;
"""


secciones = [
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
    ("8. IMPORTACIÓN DESDE EL SISTEMA ANTERIOR (db_cbsd) - opcional",
     importacion_como_bloque(leer('migrations/mantenimiento/03-importacion-db_cbsd.sql'))),
    ("9. REGISTRO INICIAL DE LA INSTITUCIÓN (solo si no se importó ni existe)", """INSERT INTO admin.tb_sistema (sistema_nombre, sistema_siglas, sistema_slogan, sistema_ciudad, sistema_direccion,
                              sistema_telefono, sistema_correo, sistema_sitioweb, sistema_facebook, sistema_twitter)
SELECT 'CUERPO DE BOMBEROS SANTO DOMINGO', 'CBSD', 'Juntos hacia el crecimiento institucional', 'Santo Domingo',
       'Av. Jacinto Cortez y Jorge Icaza', '(02) 3959-340', 'info@cbsd.gob.ec', 'http://bomberosantodomingo.gob.ec',
       '/CuerpoDeBomberosSantoDomingo', '@BomberosSD'
 WHERE NOT EXISTS (SELECT 1 FROM admin.tb_sistema);
-- Completar siglas/slogan/redes del registro importado si vinieron vacíos
UPDATE admin.tb_sistema SET sistema_slogan = COALESCE(sistema_slogan, 'Juntos hacia el crecimiento institucional'),
                            sistema_facebook = COALESCE(sistema_facebook, '/CuerpoDeBomberosSantoDomingo'),
                            sistema_twitter = COALESCE(sistema_twitter, '@BomberosSD');
"""),
]

encabezado = """-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- SCRIPT 3: cambios posteriores a script.sql, script-2.sql y script_sbj_temp.sql
--   combustible, institución, mantenimiento vehicular, contratos, menús y privilegios, bitácora del vehículo, operadores, usuarios y perfiles, importación de db_cbsd.
--
-- CÓMO USARLO (pgAdmin): abra el Query Tool sobre la base NUEVA (db_bcbsd), pegue TODO el archivo y ejecútelo.
--   * Se puede ejecutar varias veces: no borra tablas ni datos; lo que ya existe se omite.
--   * No toca operaciones.tb_estaciones.
--   * La importación (sección 8) solo corre si edita la línea "conexion" con la clave de la base anterior.
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
