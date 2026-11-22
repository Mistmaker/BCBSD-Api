# Despliegue del API BCBSD en Apache

## Requisitos del servidor

| Componente | Versión / módulo | Motivo |
|---|---|---|
| PHP | **8.1 o superior** (recomendado 8.2/8.3) | `firebase/php-jwt` v7 exige PHP ≥ 8.0; 8.0 ya no recibe parches de seguridad. Las pruebas (PHPUnit 10) requieren 8.1. |
| Extensiones PHP | `pdo_pgsql`, `mbstring`, `gd`, `curl`, `json` | Base de datos PostgreSQL; `spipu/html2pdf` (gd, mbstring) y `tecnickcom/tcpdf` (curl) para los PDF. |
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
institución y parámetros, mantenimiento vehicular y contratos, menús y privilegios, importación desde `db_cbsd`
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

### Mantenimiento vehicular (`migrations/mantenimiento/`)

```bash
psql -d db_bcbsd -v ON_ERROR_STOP=1 -f migrations/mantenimiento/01-institucion.sql
psql -d db_bcbsd -v ON_ERROR_STOP=1 -f migrations/mantenimiento/02-mantenimiento.sql
psql -d db_bcbsd -v ON_ERROR_STOP=1 -f migrations/mantenimiento/04-privilegios.sql
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
