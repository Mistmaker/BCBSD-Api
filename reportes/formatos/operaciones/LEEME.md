# Formatos de Operaciones

Plantilla HTML del PDF del parte de servicio (spipu/html2pdf). Se puede editar libremente.

- `parte.html`: parte de auxilio (PA) o de incendio (PI), con las secciones y el orden del formato del área operativa.
  PHP: `reportes/operaciones/parte.php?id=N` (privilegio `OPE_PARTES`); el armado está en `classes/reporteParte.php`.
- Los marcadores `{{campo}}` se reemplazan con datos ya escapados; los que terminan en `_html` son tablas armadas por el PHP.
- `<nobreak>` evita que una sección quede partida entre dos páginas.
- El croquis lleva la imagen del mapa con el marcador (`classes/mapaUbicacion.php`, generada al guardar el parte), las
  coordenadas y un QR pequeño que abre la ubicación en el teléfono (parámetro `MAPA_QR_URL`).
- Cabecera, escudo de fondo y pie: `../HEADER_PROCESS_CBSD.html` y `../FOOTER_PAGE_MAIN.html` (datos de `admin.tb_sistema`).
