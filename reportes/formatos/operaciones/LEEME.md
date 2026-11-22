# Formatos de Operaciones

Plantilla HTML del PDF del parte de servicio (spipu/html2pdf). Se puede editar libremente.

- `parte.html`: parte de auxilio (PA) o de incendio (PI), con las secciones y el orden del formato del área operativa.
  PHP: `reportes/operaciones/parte.php?id=N` (privilegio `OPE_PARTES`); el armado está en `classes/reporteParte.php`.
- Los marcadores `{{campo}}` se reemplazan con datos ya escapados; los que terminan en `_html` son tablas armadas por el PHP.
- `<nobreak>` evita que una sección quede partida entre dos páginas.
- El croquis lleva latitud, longitud y un código QR con el enlace al mapa (o al croquis cargado en el parte).
- Cabecera, escudo de fondo y pie: `../HEADER_PROCESS_CBSD.html` y `../FOOTER_PAGE_MAIN.html` (datos de `admin.tb_sistema`).
