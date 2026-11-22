# Despliegue del API BCBSD en Apache

## Requisitos del servidor

| Componente | Versión / módulo | Motivo |
|---|---|---|
| PHP | **8.1 o superior** (recomendado 8.2/8.3) | `firebase/php-jwt` v7 exige PHP ≥ 8.0; 8.0 ya no recibe parches de seguridad. Las pruebas (PHPUnit 10) requieren 8.1. |
| Extensiones PHP | `pdo_pgsql`, `mbstring`, `gd`, `curl`, `json`, `fileinfo` | Base de datos PostgreSQL; `spipu/html2pdf` (gd, mbstring) y `tecnickcom/tcpdf` (curl) para los PDF; `fileinfo` valida los PDF subidos. |
| Apache | 2.4 con `mod_rewrite`, `mod_setenvif`, `mod_alias` | Pasar el encabezado `Authorization` a PHP y bloquear carpetas internas (`.htaccess`). |
| Apache | `AllowOverride All` (o al menos `FileInfo Limit Options`) en la carpeta del API | Para que se apliquen los `.htaccess` del proyecto. |
| PostgreSQL | la versión actual de producción | — |

Verificar extensiones: `php -m | grep -Ei "pdo_pgsql|mbstring|gd|curl"`.

## Instalación

```bash
git pull
composer install --no-dev --optimize-autoloader
cp classes/config.local.example.php classes/config.local.php   # solo la primera vez
```

Editar `classes/config.local.php` con la clave de la base de datos y la clave JWT.
Este archivo **no se versiona** (está en `.gitignore`).

Alternativa sin archivo: definir variables de entorno en el VirtualHost:

```apache
SetEnv BCBSD_DB_HOST localhost
SetEnv BCBSD_DB_PORT 5432
SetEnv BCBSD_DB_USER postgres
SetEnv BCBSD_DB_PASS "..."
SetEnv BCBSD_DB_NAME db_bcbsd
SetEnv BCBSD_JWT_SECRET "..."
SetEnv BCBSD_JWT_EXP_SECONDS 28800
```

## Documentos subidos (licencias, cédulas, certificados)

Los PDF que suben los usuarios (por ahora, la licencia de los operadores) se guardan en `documentos/` con subcarpetas por
tipo y un histórico de las versiones reemplazadas (ver `documentos/LEEME.md`). **Nunca se sirven directamente**: se
descargan con el API, que exige sesión y privilegio (`documentos/.htaccess` y el `.htaccess` raíz bloquean el acceso).

1. **Ubicación** (recomendado fuera de la carpeta pública):
   ```apache
   SetEnv BCBSD_DOCS_DIR /var/lib/bcbsd/documentos
   ```
   o `define('DOCS_DIR', '/var/lib/bcbsd/documentos');` en `classes/config.local.php`. Sin configurarla se usa
   `documentos/` dentro del API.
2. **Permisos**: el usuario de Apache debe poder escribir (las subcarpetas se crean solas):
   ```bash
   sudo mkdir -p /var/lib/bcbsd/documentos && sudo chown -R www-data:www-data /var/lib/bcbsd/documentos && sudo chmod -R 750 /var/lib/bcbsd/documentos
   ```
3. **Tamaño de subida**: PHP permite 2 MB por defecto. Para el máximo del parámetro `OPER_PDF_MAX_MB` (5 MB), en
   `php.ini` (o el `.user.ini` del API con PHP-FPM):
   ```ini
   upload_max_filesize = 8M
   post_max_size = 10M
   ```
4. **Respaldo**: incluir la carpeta de documentos en los respaldos junto con la base de datos.

## JSON Web Token

- El login (`servicios/auth/login.php` y `loginVoluntarios.php`) emite un token HS256.
- **Duración**: `JWT_EXP_SECONDS` (por defecto 28800 s = 8 horas). Se cambia en `config.local.php` o con `BCBSD_JWT_EXP_SECONDS`.
- **Clave**: `JWT_SECPWD`, mínimo 32 caracteres (lo exige `firebase/php-jwt` v7). Generar una con:
  `php -r "echo bin2hex(random_bytes(32)), PHP_EOL;"`. Cambiar la clave invalida todas las sesiones abiertas.
- Todos los demás archivos de `servicios/`, `reportes/` e `impresion/` comienzan con
  `require_once .../classes/auth.php; $auth = requireAuth();`, que responde `401` si el token falta, está vencido o fue alterado.
  La prueba `tests/EndpointsProtegidosTest.php` falla si un endpoint nuevo se olvida de incluirlo.
- En los endpoints, `authUsuarioId()` devuelve el usuario del token (no se puede falsificar desde el navegador).

### Si todas las peticiones devuelven 401 con un token válido

Apache (sobre todo con PHP-FPM) descarta el encabezado `Authorization`. El `.htaccess` lo reenvía con `mod_rewrite`/`mod_setenvif`;
si `AllowOverride` no lo permite, agregar en el VirtualHost:

```apache
<Directory "/ruta/al/api">
    CGIPassAuth On
</Directory>
```

## Migraciones de la base de datos

Orden para crear una base nueva desde cero: `script.sql`, `script-2.sql`, `script_sbj_temp.sql`,
`migrations/ordenes-abastecimiento/*.sql` y luego las migraciones de cada módulo.

### Script único para pgAdmin: `script-3.sql`

Contiene, en orden, todo lo posterior a `script.sql`, `script-2.sql` y `script_sbj_temp.sql`: órdenes de combustible,
institución y parámetros, mantenimiento vehicular y contratos, menús y privilegios, bitácora del vehículo, operadores, usuarios y perfiles, petición de materiales, importación desde `db_cbsd`
(opcional: edite la línea `conexion`) y el registro inicial de la institución. Se pega completo en el Query Tool,
se puede ejecutar varias veces y no borra datos ni toca `operaciones.tb_estaciones`.
Se genera con `python3 migrations/generar-script-3.py` a partir de los archivos de `migrations/`.

### Privilegios (`migrations/mantenimiento/04-privilegios.sql`)

- Rol **con** `rol_path`: acceso a una pantalla (menú). Rol **sin** `rol_path`: permiso de acción dentro de la pantalla.
- `rol_codigo` es la clave fija que usan el front (`AuthService.tienePermiso`) y el API (`requirePermiso`); el login
  la devuelve en `usuario.permisos`. Los usuarios deben volver a iniciar sesión para recibir los privilegios nuevos.
- Mantenimiento: `MANT_ORDENES`, `MANT_BITACORAS`, `MANT_PLANES`, `MANT_CONTRATOS` (pantallas) y `MANT_ORDEN_CREAR`,
  `MANT_ORDEN_RECIBIR`, `MANT_ORDEN_ACTA`, `MANT_ORDEN_ANULAR`, `MANT_BITACORA_GESTIONAR`, `MANT_CONTRATO_GESTIONAR`,
  `MANT_PLAN_GESTIONAR` (acciones; el API los exige). Combustible: `ADM_COMBUSTIBLE`, `ADM_COMBUSTIBLE_CREAR`.
  Movilización: `ADM_MOVILIZACION`, `ADM_MOVILIZACION_CREAR`. Vehículos: `ADM_VEHICULOS`, `ADM_VEHICULO_CREAR`.

### Petición de materiales (`migrations/servicios-generales/01-peticion-materiales.sql`)

Pantalla **Dir. Administrativa > Peticiones de materiales** (`ADM_PETICIONES_MATERIALES` para consultar e imprimir,
`ADM_PETICION_MATERIALES_GESTIONAR` para registrar, editar y anular). Reemplaza el libretín: se digitan cantidad, unidad y
descripción (sin stock ni catálogo), se imprime (`reportes/servicios-generales/peticionMateriales.php?id=`) y se firma.

- Código `{SIGLAS}{AA}PDM{NNNNN}` (p. ej. `CBSD26PDM00001`); la secuencia reinicia cada año.
- Quien autoriza se precarga con el puesto `PDM_AUTORIZA_PUESTO_ID` EN FUNCIONES (editable). Unidades sugeridas:
  `PDM_UNIDADES` (se puede escribir otra). `PDM_FILAS_MINIMAS`: filas de la tabla del PDF, como el libretín.
- Formato editable: `reportes/formatos/servicios-generales/peticion_materiales.html` (encabezado, logo y pie de la
  institución configurada en `admin.tb_sistema`).

### Usuarios y perfiles (`migrations/admin/01-usuarios-perfiles.sql`)

- **Perfil** = grupo de privilegios predefinido (`admin.tb_perfil_rol`). **Privilegios efectivos** de un usuario = los de
  su perfil + sus privilegios adicionales (`admin.tb_usuario_rol`), solo si el usuario y el perfil están ACTIVOS
  (vista `admin.vw_usuario_privilegios`; la usan el login, el menú, `getPermisos` y `requirePermiso`). Cambiar los
  privilegios de un perfil se aplica de inmediato a todos sus usuarios.
- Menú **Administración > Usuarios / Perfiles** por privilegios (`SIS_USUARIOS`, `SIS_PERFILES`, `SIS_USUARIO_GESTIONAR`,
  `SIS_USUARIO_PRIVILEGIOS`, `SIS_PERFIL_GESTIONAR`); antes estaba fijo para el usuario 113. Se asignan al usuario 113 y
  al perfil ADMINISTRADOR. Nadie puede inactivarse ni quitarse a sí mismo la administración de usuarios o perfiles.
- **Claves**: `password_hash` (bcrypt). Las MD5 heredadas siguen funcionando y se convierten solas en el siguiente inicio
  de sesión (no hay que restablecerlas). El login rechaza a los usuarios INACTIVOS.
- Endpoints en `servicios/admin/`: `getUsuarios`, `getPersonaUsuario?doc=`, `setUsuario`, `setClaveUsuario`,
  `getPerfiles`, `setPerfil`; `servicios/auth/getPrivilegios` y `setPrivilegios` (privilegios adicionales) ahora exigen
  privilegio, y `getUsuarios` ya no devuelve las claves.

### Operadores (`migrations/operadores/01-operadores.sql`)

Pantalla **Dir. Administrativa > Operadores** (privilegios `ADM_OPERADORES` para consultar y `ADM_OPERADOR_GESTIONAR`
para registrar y editar). Un operador es un funcionario, operativo o administrativo, con licencia registrada en
`tthh.tb_conductores`.

- **Ingreso rápido** (`servicios/administrativo/operadores/setOperador.php`, POST): cédula, nombres, apellidos, tipo de
  licencia, emisión y validez. Si la cédula ya existe se reutiliza la persona (sus datos los mantiene Talento Humano). Si
  aún no tiene un puesto EN FUNCIONES se pide el puesto. Si ya es operador responde 409 con su id para editarlo.
- **Edición** (PUT, o POST con `conductor_id` cuando lleva archivo): solo la licencia (tipo, emisión, validez) y el estado.
- **Sustento**: el PDF escaneado de la licencia (`multipart/form-data`: `datos` en JSON + `licencia_pdf`) es obligatorio
  al registrar y al cambiar tipo, emisión o validez (`OPER_EXIGIR_PDF_LICENCIA`). Se guarda como
  `documentos/licencias/LIC-{CATEGORÍA}-{CÉDULA}.pdf` y el anterior pasa a `documentos/historico/licencias/`. Se consulta
  con `getLicenciaPdf.php?id=`. Tamaño máximo: `OPER_PDF_MAX_MB` (5). `OPER_BLOQUEAR_SIN_SUSTENTO` (NO por defecto)
  impide además asignar en órdenes a quien no tenga el PDF cargado: activarlo cuando todos los operadores lo tengan.
- `servicios/tthh/getConductores.php` (selectores de movilización y combustible) muestra la licencia en el nombre y marca
  `disabled` a quien no puede conducir. Al emitir movilización o asignar el operador en combustible, el API rechaza a un
  operador inactivo, sin puesto en funciones o con licencia vencida.
- Parámetros: `OPER_DIAS_AVISO_LICENCIA` (30: la licencia se marca POR VENCER) y `OPER_BLOQUEAR_LICENCIA_VENCIDA`
  (SI/NO).
- El catálogo `resources.tb_licenciasdeconducir` se carga con las categorías de Ecuador solo si está vacío.

### Bitácora del vehículo (`migrations/mantenimiento/05-bitacora.sql`)

Pantalla **Unidades > Bitácora de vehículos** (privilegio `ADM_BITACORA_VEHICULOS`). Endpoints
`servicios/administrativo/bitacora/getBitacoraFlota.php` y `getBitacoraVehiculo.php?id=` (`?desde=&hasta=`, por
defecto los últimos 12 meses). Junta por vehículo, ordenado por fecha y kilometraje: cargas de combustible VALIDADAS,
órdenes de mantenimiento no anuladas (valores por rubro de las facturas activas), movilizaciones y partes de emergencia.

- **Rendimiento (km/gal)**, método de tanque lleno: el tramo entre dos cargas rinde los km recorridos divididos para
  los galones de la segunda carga. El del período es Σkm / Σgalones de los tramos válidos. Se usa como punto de partida
  la última carga anterior al período. Una carga sin kilometraje o con uno menor al anterior no tiene rendimiento propio
  y su combustible se suma al siguiente tramo válido. Para que el cálculo sea fiable las cargas deben ser a tanque lleno.
- **Km recorridos**: mayor menos menor lectura del período entre todas las fuentes.
- **Trabajos repetidos**: compara los trabajos a realizar de las órdenes (sin tildes, mayúsculas, sin artículos ni
  preposiciones: "Cambio de motor de arranque" = "CAMBIO MOTOR ARRANQUE"). No cuentan las órdenes
  preventivas, cuyos trabajos se repiten por plan.
- **Comparación**: con los vehículos de la misma marca, modelo y año (sin distinguir mayúsculas ni espacios).
- Parámetros (`admin.tb_params`): `BIT_VENTANA_REPETICION_DIAS` (180: un trabajo repetido dentro de este plazo genera
  alerta), `BIT_ALERTA_RENDIMIENTO_PCT` (15: alerta si rinde ese % menos que los iguales), `BIT_ALERTA_COSTO_PCT`
  (30: alerta si el mantenimiento por km cuesta ese % más que los iguales).
- `orden_cantidad_galones` pasa de entero a `numeric(10,3)` para registrar galones con decimales.

### Mantenimiento vehicular (`migrations/mantenimiento/`)

```bash
psql -d db_bcbsd -v ON_ERROR_STOP=1 -f migrations/mantenimiento/01-institucion.sql
psql -d db_bcbsd -v ON_ERROR_STOP=1 -f migrations/mantenimiento/02-mantenimiento.sql
psql -d db_bcbsd -v ON_ERROR_STOP=1 -f migrations/mantenimiento/04-privilegios.sql
psql -d db_bcbsd -v ON_ERROR_STOP=1 -f migrations/mantenimiento/05-bitacora.sql
# Importar datos del sistema anterior (opcional, re-ejecutable):
psql -d db_bcbsd -v legacy_conn="dbname=db_cbsd host=localhost user=postgres password=XXXX" \
     -f migrations/mantenimiento/03-importacion-db_cbsd.sql
```

- `01` crea `admin.tb_sistema` (nombre, **siglas**, logo, contacto de la institución) y `admin.tb_params`.
  Las siglas son el prefijo de los códigos (`CBSD26MAN00001`); otro cuerpo de bomberos solo cambia ese registro.
- `02` crea las tablas, vistas y roles del menú. Es re-ejecutable.
- `03` importa institución, parámetros, planes, recursos, órdenes e informes desde `db_cbsd`, convirtiendo
  la unidad antigua (`logistica.tb_unidades`) en el vehículo nuevo. Al final muestra cuántos registros se omitieron
  (vehículo, personal o usuario inexistente en la base nueva).
- Parámetros del módulo (`admin.tb_params`, módulo MANTENIMIENTO): `MANT_TOLERANCIA_KM` (anticipación de la alerta),
  `MANT_RUBROS`, `MANT_FORMATO_BITACORA`, `MANT_CARGOS_RESPONSABLE`, `MANT_DIRECTOR_PUESTO_ID`, `MANT_FORMATO_INFORME` (sugerencia del +1 para el número del informe de pago, que es texto libre con la secuencia documental institucional;
  con `{SIGLAS} {AA} {AAAA} {N} {NNN}`), `MANT_TIPOS_CONTRATO`, `MANT_TECNICO_PUESTO`, `MANT_INFORME_CARGO`.
- **Contratos de mantenimiento** (`logistica.tb_contratosmantenimiento`, partidas y vehículos): cada orden nueva se
  registra bajo un contrato vigente que cubra al vehículo; los valores por rubro no pueden superar el saldo de la partida
  (`logistica.vw_contratosmantenimiento_saldo`).
- **Estados de la orden**: MANTENIMIENTO (en el taller) → RECIBIDO (valores y facturas) → ENTREGADO (acta generada); ANULADA.
- **Formatos PDF** editables en `reportes/formatos/mantenimiento/` (ver `LEEME.md` de esa carpeta).

## Pruebas

```bash
composer install            # incluye PHPUnit (dependencia de desarrollo)
vendor/bin/phpunit
```

Sin base de datos prueban: emisión/validación del token, que todos los endpoints estén protegidos, las
respuestas HTTP de autenticación y las reglas del mantenimiento (próximo mantenimiento, códigos, validaciones).

Pruebas de integración del módulo de mantenimiento (se omiten si no se configura una base): usar una base
**desechable** con los scripts y migraciones aplicados:

```bash
BCBSD_TEST_DB_NAME=db_bcbsd_pruebas BCBSD_TEST_DB_HOST=localhost BCBSD_TEST_DB_USER=postgres BCBSD_TEST_DB_PASS=... vendor/bin/phpunit
```

## Pendientes de seguridad conocidos

- **Rotar credenciales**: la clave de PostgreSQL y la clave JWT estuvieron publicadas en `classes/dbconfig.php` en este
  repositorio público. Siguen visibles en el historial de git: cambiarlas en el servidor.
- Las contraseñas se guardan con `md5`; migrar a `password_hash()`/`password_verify()`.
- `Access-Control-Allow-Origin: *`: restringir al dominio del front cuando esté definido.
- Archivos sin uso que incluyen un `config.php` inexistente: `reportes/{Empleados,Instituciones,Personas,RecintosElectorales,RepInstitucionesPorTipo}.php`,
  `impresion/*.php`, `servicios/tthh/{getTotalVacacionesSolicitadas,getVacacionesGeneradas,getTotalPermisosSolicitados,setVacacionesAjuste}.php`.
  `RepInstitucionesPorTipo.php` además tiene un error de sintaxis. Conviene eliminarlos.
