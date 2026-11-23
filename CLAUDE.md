# BCBSD API (PHP + PostgreSQL)

API del sistema del Cuerpo de Bomberos de Santo Domingo. El front es el repositorio BCBSD-Web (Angular 19 + CoreUI).
Despliegue en Apache + PHP 8.1+. Debe poder usarlo otro cuerpo de bomberos: lo propio de la institución va en
`admin.tb_sistema` y en parámetros (`admin.tb_params`), no en el código. Textos y mensajes en español.

## Nuevas pantallas y privilegios (OBLIGATORIO)

Cada vez que se crea una pantalla o ruta nueva en el front, o una acción que deba restringirse, se agrega en la misma
tarea el INSERT del privilegio en `admin.tb_roles` dentro de una migración de `migrations/`, para que se pueda asignar
en Administración > Usuarios > Privilegios:

- **Acceso a pantalla (menú)**: `rol_path` = ruta del front (`/admin/operadores`), `rol_codigo` = clave fija
  (`ADM_OPERADORES`). Aparece en el menú del usuario que lo tenga.
- **Permiso de acción** (registrar, editar, anular...): `rol_path` = NULL, `rol_codigo` propio (`ADM_OPERADOR_GESTIONAR`).
- Va dentro del submódulo que corresponda (`admin.tb_submodulos`, del módulo `admin.tb_modulos`); si no existe, crearlo.
- Re-ejecutable: `WHERE NOT EXISTS (... rol_codigo = ...)`. Modelo: `migrations/operadores/01-operadores.sql`, sección 4.
- Asignación inicial: a los administradores con `admin.fn_es_administrador(u.usuario_id)` (parámetro `SIS_ADMINISTRADORES`,
  nunca un usuario_id fijo), al perfil de administrador con `admin.fn_perfil_es_administrador(p.perfil_id)` y a quienes
  ya usan pantallas relacionadas. La sección final de `script-3.sql` (`migrations/admin/02-acceso-administradores.sql`)
  da además todos los privilegios a los administradores.
- En el API: `requirePermiso($db, 'CODIGO')` en el endpoint. En el front: `data: { permiso: 'CODIGO' }` en la ruta
  con `canActivate: [AuthGuard, permisoGuard]`, y `auth.tienePermiso('CODIGO')` para botones de acción.
- Agregar la migración nueva a `migrations/generar-script-3.py` y regenerar `script-3.sql`.
- Al terminar, entregar al usuario el SQL de los privilegios para ejecutarlo de inmediato si lo necesita.
- `tests/PrivilegiosMigracionTest.php` falla si un endpoint exige un privilegio que ninguna migración crea.

## Base de datos y migraciones

- `script-3.sql` es el ÚNICO script de la base (vacía o existente; reemplaza a script.sql, script-2.sql y
  script_sbj_temp.sql): se GENERA con `python3 migrations/generar-script-3.py` a partir de `migrations/` (estructura y
  catálogos base en `migrations/base/`). Nunca editarlo a mano; `tests/Script3Test.php` verifica que esté al día.
- Antes de entregar un cambio de base: ejecutar `script-3.sql` dos veces sobre una base VACÍA y dos sobre una copia de
  la base de prueba (sin errores y sin duplicar datos).
- Migraciones re-ejecutables (`IF NOT EXISTS`, `ON CONFLICT DO NOTHING`, `WHERE NOT EXISTS`); no borran datos.
- `Database` comparte una sola sentencia: llamar `parametro()` / `institucion()` antes de preparar otras consultas.

## Endpoints

- Todo endpoint empieza con `require_once .../classes/auth.php; $auth = requireAuth();` (`tests/EndpointsProtegidosTest.php`).
- Usuario de la sesión: `authUsuarioId()` (nunca un id enviado por el cliente).
- Errores de validación: `throw new ValidacionException('mensaje')` -> 422; `apiError()` para el resto.

## Documentos subidos

- Carpeta `DOCS_DIR` (`documentos/` por defecto): subcarpetas por tipo, histórico, nombres normalizados
  (`documentos/LEEME.md`). Usar `classes/documentos.php`. Nunca servir archivos directamente: descargar con un endpoint
  que exija sesión y privilegio.

## Pruebas

- `vendor/bin/phpunit` (unitarias). Integración contra PostgreSQL desechable:
  `BCBSD_TEST_DB_NAME=... BCBSD_TEST_DB_HOST=... BCBSD_TEST_DB_PORT=... vendor/bin/phpunit`.
- Las pruebas de integración solo borran lo que crean (IDs propios o `fk_usuario_id` de prueba).

## Seguridad

- Nunca versionar claves ni datos sensibles (`classes/config.local.php` está en `.gitignore`).
