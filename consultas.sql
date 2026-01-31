-- INSITUTCIONES DATOS COMPLETOS

SELECT i.ins_documento, i.ins_nombre, i.ins_direccion, i.ins_referencia, i.ins_telefono, i.ins_email, i.ins_empleados, t.tin_descripcion, p.per_documento, CONCAT(p.per_apellido, ' ',p.per_nombre) AS 'Representante', c.can_nombre, pa.par_nombre, z.zon_descripcion, i.ins_recinto FROM instituciones i 
INNER JOIN tipoinstitucion t on t.tin_id = i.tin_id 
INNER JOIN personas p ON p.per_id = i.per_id 
INNER JOIN zonas z ON z.zon_id = i.zon_id 
INNER JOIN parroquias pa on pa.par_id = z.par_id 
INNER join cantones c on c.can_id = pa.can_id
WHERE i.ins_recinto = 'S'
ORDER BY c.can_nombre, pa.par_nombre, z.zon_descripcion, i.ins_nombre
