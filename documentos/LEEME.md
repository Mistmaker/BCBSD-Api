# Documentos del sistema

Archivos subidos por los usuarios. **No se sirven directamente** (`.htaccess` con `Require all denied`): se descargan
a través del API, que exige sesión y privilegio. Los archivos no se versionan en git (solo esta estructura).

La ubicación se configura con `BCBSD_DOCS_DIR` (variable de entorno o `classes/config.local.php`). En producción se
recomienda una carpeta fuera de la raíz pública de Apache, con permiso de escritura para el usuario del servidor web
(`www-data`).

| Carpeta | Contenido | Nombre del archivo |
|---|---|---|
| `licencias/` | Licencias de conducir de los operadores (PDF) | `LIC-{CATEGORÍA}-{CÉDULA}.pdf`, p. ej. `LIC-C1-1712345675.pdf` |
| `cedulas/` | Cédulas escaneadas (Talento Humano) | `CED-{CÉDULA}.pdf` |
| `cursos/` | Certificados de cursos | `CUR-{CÉDULA}-{CÓDIGO}.pdf` |
| `capacitaciones/` | Certificados de capacitaciones | `CAP-{CÉDULA}-{CÓDIGO}.pdf` |
| `reconocimientos/` | Reconocimientos | `REC-{CÉDULA}-{CÓDIGO}.pdf` |
| `cargas-familiares/` | Cédulas de las cargas familiares | `CFA-{CÉDULA FUNCIONARIO}-{CÉDULA CARGA}.pdf` |
| `ubicaciones/{módulo}/` | Imagen de ubicación (mapa con el marcador) generada por el sistema, p. ej. `ubicaciones/partes/` | `MAPA-{NÚMERO}.png`; la anterior pasa a `ubicaciones/{módulo}/historico/` |
| `cache/mapas/` | Cuadros del mapa descargados (caché de 30 días, se pueden borrar) | |
| `historico/` | Versiones reemplazadas, en la misma subcarpeta y con fecha: `historico/licencias/LIC-B-1712345675_20261122-153000.pdf` | |

La base de datos guarda la ruta relativa (p. ej. `licencias/LIC-C-1712345675.pdf` en `tthh.tb_conductores.conductor_pdf`).
