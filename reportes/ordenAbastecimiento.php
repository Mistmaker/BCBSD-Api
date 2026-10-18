<?php

use Spipu\Html2Pdf\Html2Pdf;
use Spipu\Html2Pdf\Exception\Html2PdfException;
use Spipu\Html2Pdf\Exception\ExceptionFormatter;

// Retorna un json
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
date_default_timezone_set('America/Guayaquil');
setlocale(LC_TIME, 'spanish');

// Include Database
include_once("../classes/dbconfig.php");
include_once '../classes/database.class.php';
// Include html2pdf
require_once '../vendor/autoload.php';

$id = htmlentities($_GET['id']);
$idsParam = htmlentities($_GET['idsParam']);
$date = strftime("%d de %B del %Y", strtotime(date("m") . '/' . date("d") . '/' . date("Y")));

$globalCbsdData = [
    'INSTITUTION_FULL_NAME' => 'BENEMÉRITO CUERPO DE BOMBEROS DE SANTO DOMINGO',
    'sistema_ruc' => '2360003540001',
    'INSTITUTION_NAME' => 'CUERPO DE BOMBEROS SANTO DOMINGO',
    'sistema_header' => 'Cuerpo de Bomberos Santo Domingo',
    'sistema_direccion' => 'Santo Domingo - Ecuador',
    'sistema_direccion' => 'Av. Jacinto Cortez y Jorge Icaza',
    'sistema_telefono' => '(02) 3959-340',
    'sistema_correo' => 'info@cbsd.gob.ec',
    'sistema_sitioweb' => 'https://www.bomberossantodomingo.gob.ec/',
    'SYSTEM_FACEBOOK_URI' => '/CuerpoDeBomberosSantoDomingo',
    'SYSTEM_TWITTER_URI' => '@BomberosSD',
    'REPORT_HEADER_IMG_PATH' => './recursos/img-reports/escudo.jpg',
    'informe' => 'ORDEN DE ABASTECIMIENTO',
];

$sqlOrdenes = "SELECT orden_id, orden_serie, orden_estado, orden_codigo, vehiculo_combustible, '' as responsable_titulo, vehiculo_sigla, vehiculo_placa, vehiculo_marca, vehiculo_placa, orden_registro, vehiculo_sigla, orden_estacion_servicio,
    orden_codigo_institucion, orden_nro_vales, 
    CASE
           WHEN orden_caneca IS NULL OR orden_caneca = '' THEN 'NO APLICA'
           ELSE orden_caneca
       END AS caneca
    ,(select nombre_completo from tthh.vw_personal_simple p1 where p1.ppersonal_id =  o.director_administrativo)  as dir_administrativo
    ,(select nombre_completo from tthh.vw_personal_simple p1 where p1.ppersonal_id =  o.personal_solicita)  as solicita
    ,(select puesto_nombre from tthh.vw_personal_simple p1 where p1.ppersonal_id =  o.personal_solicita)  as puesto_nombre_solicita
    ,(select nombre_completo from tthh.vw_conductores c1 where c1.conductor_id =  o.operador_id order by c1.ppersonal_id desc limit 1)  as operador
    ,(select puesto_nombre from tthh.vw_conductores c1 where c1.conductor_id =  o.operador_id order by c1.ppersonal_id desc limit 1)  as puesto_nombre_operador
    ,(select usuario_login from admin.tb_usuarios u where u.usuario_id =  o.fk_usuario_id)  as usuario
    ,(SELECT SUM(dor.orden_detalle_precio_total) FROM logistica.tb_detalleordenesabastecimiento dor WHERE dor.orden_id = o.orden_id) as total
    ,(SELECT STRING_AGG(dor.orden_detalle_kilometraje::TEXT, ', ') FROM logistica.tb_detalleordenesabastecimiento dor WHERE dor.orden_id = o.orden_id) as kilometraje
    FROM logistica.tb_ordenesabastecimiento o
    left join administrativo.tb_vehiculos v on v.vehiculo_id = o.fk_unidad_id 
    WHERE o.orden_id::text = ANY(string_to_array(:ids, ','))
    ORDER BY orden_id DESC
    ";
$database = new Database();
$database->query($sqlOrdenes);
$database->bind('ids', $idsParam);
$filas = $database->resultSet(); 
$database->closeConnection();

if (!$filas) {
    http_response_code(404);
    exit('No se encontraron órdenes');
}

$estilos = file_get_contents('recursos/style.css');
$estilos = str_replace("{{margin_left}}", "10", $estilos); //10mm
$estilos = str_replace("{{margin_right}}", "10", $estilos); //10mm

// 5. Un bloque por cada orden
$formatoBase = file_get_contents('formatos/ordenAbastecimiento.html');

$bloques = '';
foreach ($filas as $fila) {
    $datos = array_merge($fila, $globalCbsdData);
    $bloque = $formatoBase;

    foreach ($datos as $key => $value) {
        $valor = ($key === 'REPORT_HEADER_IMG_PATH') ? $value : htmlspecialchars((string)$value);
        $bloque = str_replace('{{' . $key . '}}', $valor, $bloque);
    }

    $bloques .= '<nobreak>' . $bloque . '</nobreak>';
}

$html = '<style>{{css}}p{font-size:12px;}table tbody th{background:none;color:black}table td,table th{border-color:#222d32;}.table-orden{font-size:7.5px;}</style>
<page backtop="5mm" backbottom="5mm" backleft="8mm" backright="8mm">'
    . $bloques .
'</page>';

$html = str_replace('{{css}}', $estilos, $html);

// print_r($datos);

$datos = array_merge($datos, $globalCbsdData);

// echo ($html);

try {
    ob_start();

    $orientacion = 'L'; // P = portrait    |   L = landscape
    $hoja = 'A4';
    $html2pdf = new Html2Pdf($orientacion, $hoja, 'es', true, 'UTF-8', array(0, 0, 0, 0));
    $html2pdf->pdf->SetDisplayMode('real');
    $html2pdf->pdf->SetCreator('BCBSD');
    $html2pdf->pdf->SetAuthor('BCBSD');
    $html2pdf->pdf->SetTitle('Orden de Abastecimiento');
    $html2pdf->pdf->SetSubject('Abastecimiento');
    $html2pdf->pdf->SetKeywords('BCBSD, Orden, Abastecimiento');
    $html2pdf->writeHTML($html);
    $html2pdf->output('OrdenAbastecimiento-.pdf');
} catch (Html2PdfException $e) {
    $html2pdf->clean();

    $formatter = new ExceptionFormatter($e);
    echo $formatter->getHtmlMessage();
}
