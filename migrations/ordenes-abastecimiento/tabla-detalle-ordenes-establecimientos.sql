CREATE TABLE logistica.tb_detalleordenesabastecimiento (
	orden_detalle_id serial4 NOT NULL,
	orden_id int4 NOT NULL,
	orden_detalle_linea int4 NOT NULL,
	fk_unidad_id int4 DEFAULT NULL,
	orden_detalle_nro_canecas int4 DEFAULT NULL,
	orden_detalle_kilometraje int4 DEFAULT NULL,
	orden_detalle_tipo_combustible VARCHAR(30) DEFAULT NULL,
	orden_detalle_cantidad_galones int4 DEFAULT NULL,
	orden_detalle_precio_total DECIMAL(10,2) DEFAULT 0,
	CONSTRAINT tb_detalleordenesabastecimiento_pk PRIMARY KEY (orden_detalle_id, orden_id, orden_detalle_linea),
	CONSTRAINT tb_detalleordenesabastecimiento_fk_orden_id_fkey FOREIGN KEY (orden_id) 
	REFERENCES logistica.tb_ordenesabastecimiento(orden_id) ON DELETE RESTRICT ON UPDATE RESTRICT 
);