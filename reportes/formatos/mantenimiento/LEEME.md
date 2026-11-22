# Formatos de mantenimiento vehicular

Plantillas HTML de los reportes PDF (spipu/html2pdf). Se pueden editar libremente.

- Los marcadores `{{campo}}` se reemplazan con datos ya escapados; los que terminan en `_html`
  (`{{trabajos_html}}`, `{{facturas_html}}`, ...) contienen tablas o listas armadas por el PHP.
- Cabecera, escudo de fondo y pie: `../HEADER_PROCESS_CBSD.html` y `../FOOTER_PAGE_MAIN.html` (comunes a todos los reportes).
- Datos de la institución (`{{institucion}}`, `{{ciudad}}`, `{{slogan}}`): tabla `admin.tb_sistema`.

| Archivo | Reporte | PHP |
|---|---|---|
| `orden.html` | Orden de mantenimiento | `reportes/mantenimiento/ordenMantenimiento.php?doc=orden` |
| `informe.html` | Informe individual (recepción conforme y facturas). Lleva el mismo número de serie de la orden (`{{numero_orden}}`); el número del informe de pago está en `{{numero_informe}}` | `...?doc=informe` |
| `acta.html` | Acta entrega-recepción de satisfacción vehicular | `...?doc=acta` |
| `bitacora.html` + `bitacora_orden.html` | Informe de grupo (bitácora); `bitacora_orden.html` se repite por cada orden | `reportes/mantenimiento/informeMantenimiento.php` |
