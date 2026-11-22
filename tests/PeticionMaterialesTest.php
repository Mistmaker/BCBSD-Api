<?php

use PHPUnit\Framework\TestCase;

require_once __DIR__ . '/../classes/peticionMateriales.php';

final class PeticionMaterialesTest extends TestCase
{
    private function peticion(array $extra = []): object
    {
        return json_decode(json_encode($extra + [
            'peticion_destino' => 'Mantenimiento de la estación 1', 'solicitante_id' => 5, 'peticion_fecha' => '2026-11-22',
            'detalle' => [['detalle_cantidad' => 3, 'detalle_unidad' => ' caja ', 'detalle_descripcion' => 'Guantes  de nitrilo'],
                          ['detalle_cantidad' => '', 'detalle_unidad' => '', 'detalle_descripcion' => ''],
                          ['detalle_cantidad' => '2.5', 'detalle_unidad' => 'Galón', 'detalle_descripcion' => 'Pintura blanca']],
        ]));
    }

    public function testValidaYNormalizaItems(): void
    {
        $items = pdmValidar($this->peticion());
        $this->assertCount(2, $items); // la fila vacía se omite
        $this->assertSame(['detalle_cantidad' => 3.0, 'detalle_unidad' => 'CAJA', 'detalle_descripcion' => 'Guantes de nitrilo'], $items[0]);
        $this->assertSame('GALÓN', $items[1]['detalle_unidad']);
        $this->assertSame(2.5, $items[1]['detalle_cantidad']);
    }

    public function testErrores(): void
    {
        $casos = [
            [['peticion_destino' => '  '], 'qué se utilizarán'],
            [['solicitante_id' => null], 'solicitante'],
            [['peticion_fecha' => '22/11/2026'], 'Fecha'],
            [['peticion_autorizado_para' => 'OTRO'], 'Adquisición o Bodega'],
            [['detalle' => []], 'al menos un material'],
            [['detalle' => [['detalle_cantidad' => 0, 'detalle_unidad' => 'U', 'detalle_descripcion' => 'X']]], 'Ítem 1: la cantidad'],
            [['detalle' => [['detalle_cantidad' => 1, 'detalle_unidad' => '', 'detalle_descripcion' => 'X']]], 'Ítem 1: ingrese la unidad'],
        ];
        foreach ($casos as [$cambio, $mensaje]) {
            try {
                pdmValidar($this->peticion($cambio));
                $this->fail("Debió fallar: $mensaje");
            } catch (ValidacionException $e) {
                $this->assertStringContainsString($mensaje, $e->getMessage());
            }
        }
    }

    public function testFormatos(): void
    {
        $this->assertSame('3', pdmCantidad('3.00'));
        $this->assertSame('2,50', pdmCantidad(2.5));
        $this->assertSame('Santo Domingo, 5 de marzo de 2026', pdmLugarFecha('Santo Domingo', '2026-03-05'));
        $this->assertSame('22 de noviembre de 2026', pdmLugarFecha('', '2026-11-22'));
        $this->assertSame('CBSD26PDM00001', mantCodigo('CBSD', PDM_TIPO, 1, 2026));
    }
}
