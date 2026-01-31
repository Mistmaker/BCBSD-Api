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
$date = strftime("%d de %B del %Y", strtotime(date("m") . '/' . date("d") . '/' . date("Y")));

$globalCbsdData = [
    'INSTITUTION_FULL_NAME' => 'BENEMÉRITO CUERPO DE BOMBEROS DE SANTO DOMINGO',
    'sistema_ruc' => '2360003540001',
    'sistema_direccion' => 'Av. Jacinto Cortez y Jorge Icaza',
    'sistema_telefono' => '(02) 3959-340',
    'sistema_correo' => 'info@cbsd.gob.ec',
    'sistema_sitioweb' => 'https://www.bomberossantodomingo.gob.ec/',
    'SYSTEM_FACEBOOK_URI' => '/CuerpoDeBomberosSantoDomingo',
    'SYSTEM_TWITTER_URI' => '@BomberosSD'
];

$estilos = file_get_contents('recursos/style.css');
$estilos = str_replace("{{margin_left}}", "10", $estilos); //10mm
$estilos = str_replace("{{margin_right}}", "10", $estilos); //10mm

$html = '<style>{{css}}p{font-size:12px;}table tbody th{background:none;color:black}table td,table th{border-color:#222d32;}.table-orden{font-size:7.5px;}</style>
<page backtop="{{margin_top}}mm" backbottom="{{margin_bottom}}mm" backleft="{{margin_left}}mm" backright="{{margin_right}}mm">
	<!-- HEADER PROCESS CBSD -->
	{{HEADER_PROCESS_CBSD}}
	<!-- FOOTER DE REPORTE -->
	{{FOOTER_PAGE_MAIN}}
	<!-- CUERPO DE REPORTE -->
	{{ORDEN_MOVILIZACION_TEMPLATE}}
</page>';


$html = '<style>{{css}}p{font-size:12px;}table tbody th{background:none;color:black}table td,table th{border-color:#222d32;}.table-orden{font-size:7.5px;}</style>
<page backtop="{{margin_top}}mm" backbottom="{{margin_bottom}}mm" backleft="{{margin_left}}mm" backright="{{margin_right}}mm">
	{{ORDEN_MOVILIZACION_TEMPLATE}}
</page>';

$html = str_replace("{{margin_top}}", "2", $html); //10mm
$html = str_replace("{{margin_bottom}}", "2", $html); //10mm
$html = str_replace("{{margin_left}}", "2", $html); //10mm
$html = str_replace("{{margin_right}}", "2", $html); //10mm

$formato = file_get_contents('formatos/ordenMovilizacion.html');
$formato = str_replace("{{margin_left}}", "10", $formato); //10mm
$formato = str_replace("{{margin_right}}", "10", $formato); //10mm
$HEADER = file_get_contents('formatos/HEADER_PROCESS_CBSD.html');
$FOOTER = file_get_contents('formatos/FOOTER_PAGE_MAIN.html');
// $HEADER_INFO = file_get_contents('formatos/REPORT_INFO_ENTITY_mini.html');
$html = str_replace("{{css}}", $estilos, $html);
$html = str_replace("{{HEADER_PROCESS_CBSD}}", $HEADER, $html);
$html = str_replace("{{FOOTER_PAGE_MAIN}}", $FOOTER, $html);
$html = str_replace("{{ORDEN_MOVILIZACION_TEMPLATE}}", $formato, $html);
// $html = str_replace("{{report_info_entity}}", $HEADER_INFO, $html);

$infoEntidad = 'DIRECCIÓN ADMINISTRATIVA <br> ORDEN DE MOVILIZACIÓN <br> <b>{{orden_codigo}}</b>';
$html = str_replace("{{report_info_entity}}", $infoEntidad, $html);
$html = str_replace("{{reporte_jefatura}}", 'DIRECCIÓN ADMINISTRATIVA', $html);
$html = str_replace("{{informe}}", 'ORDEN DE MOVILIZACIÓN', $html);

$sqlOrdenes = "SELECT *
    FROM logistica.vw_ordenesomvilizacion
    WHERE orden_id = :orden_id";
$database = new Database();
$database->query($sqlOrdenes);
$database->bind('orden_id', $id);
$datos = $database->single();
$database->closeConnection();
// print_r($datos);

$datos = array_merge($datos, $globalCbsdData);

foreach ($datos as $key => $value) {
    $html = str_replace('{{' . $key . '}}', $value, $html);
}

// echo ($html);

try {
    ob_start();

    $orientacion = 'L'; // P = portrait    |   L = landscape
    $hoja = 'A4';
    $html2pdf = new Html2Pdf($orientacion, $hoja, 'es', true, 'UTF-8', array(0, 0, 0, 0));
    $html2pdf->pdf->SetDisplayMode('real');
    $html2pdf->pdf->SetCreator('CBSD');
    $html2pdf->pdf->SetAuthor('CBSD');
    $html2pdf->pdf->SetTitle('Orden de Movilización');
    $html2pdf->pdf->SetSubject('OrdenMovilizacion');
    $html2pdf->pdf->SetKeywords('CBSD, Orden, Movilizacion');
    $html2pdf->writeHTML($html);
    $html2pdf->output('OrdenMovilizacion-.pdf');
} catch (Html2PdfException $e) {
    $html2pdf->clean();

    $formatter = new ExceptionFormatter($e);
    echo $formatter->getHtmlMessage();
}
