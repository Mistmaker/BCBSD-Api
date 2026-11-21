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

## Pruebas

```bash
composer install            # incluye PHPUnit (dependencia de desarrollo)
vendor/bin/phpunit
```

No necesitan base de datos: prueban emisión/validación del token, que todos los endpoints estén protegidos
y, levantando el API con el servidor embebido de PHP, las respuestas HTTP (preflight, 401, token válido).

## Pendientes de seguridad conocidos

- **Rotar credenciales**: la clave de PostgreSQL y la clave JWT estuvieron publicadas en `classes/dbconfig.php` en este
  repositorio público. Siguen visibles en el historial de git: cambiarlas en el servidor.
- Las contraseñas se guardan con `md5`; migrar a `password_hash()`/`password_verify()`.
- `Access-Control-Allow-Origin: *`: restringir al dominio del front cuando esté definido.
- Archivos sin uso que incluyen un `config.php` inexistente: `reportes/{Empleados,Instituciones,Personas,RecintosElectorales,RepInstitucionesPorTipo}.php`,
  `impresion/*.php`, `servicios/tthh/{getTotalVacacionesSolicitadas,getVacacionesGeneradas,getTotalPermisosSolicitados,setVacacionesAjuste}.php`.
  `RepInstitucionesPorTipo.php` además tiene un error de sintaxis. Conviene eliminarlos.
