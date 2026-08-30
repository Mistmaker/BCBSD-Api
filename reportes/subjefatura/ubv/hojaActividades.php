<?php

use Spipu\Html2Pdf\Html2Pdf;
use Spipu\Html2Pdf\Exception\Html2PdfException;
use Spipu\Html2Pdf\Exception\ExceptionFormatter;

// Retorna un json
// header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
date_default_timezone_set('America/Guayaquil');
setlocale(LC_TIME, 'spanish');

// Include Database
include_once("../../../classes/dbconfig.php");
include_once '../../../classes/database.class.php';
// Include html2pdf
require_once '../../../vendor/autoload.php';

$id = htmlentities($_GET['id']);
$desde = htmlentities($_GET['desde']);
$hasta = htmlentities($_GET['hasta']);
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

$estilos = file_get_contents('../../recursos/style.css');
$estilos = str_replace("{{margin_left}}", "10", $estilos); //10mm
$estilos = str_replace("{{margin_right}}", "10", $estilos); //10mm

$html = '<style>{{css}}p{font-size:12px;}table tbody th{background:none;color:black}table td,table th{border-color:#222d32;}.table-orden{font-size:7.5px;}</style>
<page backtop="{{margin_top}}mm" backbottom="{{margin_bottom}}mm" backleft="{{margin_left}}mm" backright="{{margin_right}}mm">
	<!-- HEADER PROCESS CBSD -->
	{{HEADER_PROCESS_CBSD}}
	<!-- FOOTER DE REPORTE -->
	{{FOOTER_PAGE_MAIN}}
	<!-- CUERPO DE REPORTE -->
	{{ACTIVIDADES_VOLUNTARIOS_TEMPLATE}}
</page>';


$html = '<style>{{css}}p{font-size:12px;}table tbody th{background:none;color:black}table td,table th{border-color:#222d32;}.table-orden{font-size:7.5px;}</style>
<page backtop="{{margin_top}}mm" backbottom="{{margin_bottom}}mm" backleft="{{margin_left}}mm" backright="{{margin_right}}mm">
	{{ACTIVIDADES_VOLUNTARIOS_TEMPLATE}}
</page>';

$html = str_replace("{{margin_top}}", "10", $html); //10mm
$html = str_replace("{{margin_bottom}}", "5", $html); //10mm
$html = str_replace("{{margin_left}}", "5", $html); //10mm
$html = str_replace("{{margin_right}}", "5", $html); //10mm

$formato = file_get_contents('../../formatos//ubv/hojaActividades.html');
$formato = str_replace("{{margin_left}}", "10", $formato); //10mm
$formato = str_replace("{{margin_right}}", "10", $formato); //10mm
$HEADER = file_get_contents('../../formatos/HEADER_PROCESS_CBSD.html');
$FOOTER = file_get_contents('../../formatos/FOOTER_PAGE_MAIN.html');
// $HEADER_INFO = file_get_contents('formatos/REPORT_INFO_ENTITY_mini.html');
$html = str_replace("{{css}}", $estilos, $html);
$html = str_replace("{{HEADER_PROCESS_CBSD}}", $HEADER, $html);
$html = str_replace("{{FOOTER_PAGE_MAIN}}", $FOOTER, $html);
$html = str_replace("{{ACTIVIDADES_VOLUNTARIOS_TEMPLATE}}", $formato, $html);
// $html = str_replace("{{report_info_entity}}", $HEADER_INFO, $html);

$infoEntidad = 'UNIDAD DE BOMBEROS VOLUNTARIOS <br> HOJA DE ACTIVIDADES <br> <b>{{voluntario_nombre_completo}}</b>';
$html = str_replace("{{report_info_entity}}", $infoEntidad, $html);
$html = str_replace("{{reporte_jefatura}}", 'UNIDAD DE BOMBEROS VOLUNTARIOS', $html);
$html = str_replace("{{informe}}", 'HOJA DE ACTIVIDADES', $html);


$database = new Database();

$sqlDatosVoluntario = "SELECT CONCAT(voluntario_apellidos, ' ', voluntario_nombres) AS voluntario_nombre_completo 
FROM subjefatura.tb_voluntarios
WHERE voluntario_id = :voluntario_id";
$database = new Database();
$database->query($sqlDatosVoluntario);
$database->bind('voluntario_id', $id);
$datosVoluntario = $database->single();

$sqlDatosResponsable = "SELECT puesto_nombre as jf_definicion, concat( persona_apellidos,' ',persona_nombres ) as jf_nombre 
from tthh.tb_personal p 
inner join tthh.tb_personal_puestos pp ON pp.fk_personal_id = p.personal_id inner join tthh.tb_puestos pu on pu.puesto_id = pp.fk_puesto_id
inner join resources.tb_personas pe on pe.persona_id = fk_persona_id WHERE ppersonal_estado ='EN FUNCIONES' AND pp.fk_puesto_id=79 order by persona_apellidos, persona_nombres";
$database = new Database();
$database->query($sqlDatosResponsable);
$datosResponsable = $database->single();

$sqlActividades = "SELECT a.* FROM subjefatura.tb_voluntarios_actividades a WHERE a.fk_voluntario_id = :fk_voluntario_id AND actividad_estado='FINALIZADA' AND actividad_fecha_inicio::date between '{$desde}' and '{$hasta}' order by actividad_id";
$database->query($sqlActividades);
$database->bind('fk_voluntario_id', $id);
$datos = $database->resultset();

// echo $sqlActividades;


$database->closeConnection();
// print_r($datos);

// $datos = array_merge($datos, $globalCbsdData);

$tbody = '';
// ESTRUCTURA DE TBODY
// <tr>
//     <th>NO.</th>
//     <th>DESDE</th>
//     <th>HASTA</th>
//     <th>ACTIVIDAD</th>
//     <th>DESCRIPCION</th>
//     <th>F. REGISTRO</th>
// </tr>
foreach ($datos as $key => $value) {
    $tbody .= '<tr>';
    $tbody .= '<td>' . ($key + 1) . '</td>';
    $tbody .= '<td>' . strftime("%d/%m/%Y %H:%M", strtotime($value['actividad_fecha_inicio'])) . '</td>';
    $tbody .= '<td>' . strftime("%d/%m/%Y %H:%M", strtotime($value['actividad_fecha_finalizacion'])) . '</td>';
    $tbody .= '<td>' . $value['actividad_actividad'] . '</td>';
    $tbody .= '<td>' . $value['actividad_descripcion'] . '</td>';
    $tbody .= '<td>' . strftime("%d/%m/%Y %H:%M", strtotime($value['actividad_registro'])) . '</td>';
    $tbody .= '</tr>';

}

foreach ($globalCbsdData as $key => $value) {
    $html = str_replace('{{' . $key . '}}', $value, $html);
}

$html = str_replace('{{voluntario_nombre_completo}}', $datosVoluntario['voluntario_nombre_completo'] , $html);
$html = str_replace('{{jf_nombre}}', $datosResponsable['jf_nombre'] , $html);
$html = str_replace('{{jf_definicion}}', $datosResponsable['jf_definicion'] , $html);
$html = str_replace('{{fromDate}}', $desde , $html);
$html = str_replace('{{toDate}}', $hasta , $html);
$html = str_replace('{{tbody}}', $tbody , $html);

// echo ($html);

try {
    ob_start();

    $orientacion = 'L'; // P = portrait    |   L = landscape
    $hoja = 'A4';
    $html2pdf = new Html2Pdf($orientacion, $hoja, 'es', true, 'UTF-8', array(0, 0, 0, 0));
    $html2pdf->pdf->SetDisplayMode('real');
    $html2pdf->pdf->SetCreator('BCBSD');
    $html2pdf->pdf->SetAuthor('BCBSD');
    $html2pdf->pdf->SetTitle('Hoja de Actividades de Voluntarios');
    $html2pdf->pdf->SetSubject('HojaActividades');
    $html2pdf->pdf->SetKeywords('BCBSD, Hoja, Actividades');
    $html2pdf->writeHTML($html);
    $html2pdf->output("HojaActividades-{$id}_{$desde}_{$hasta}.pdf");
} catch (Html2PdfException $e) {
    $html2pdf->clean();

    $formatter = new ExceptionFormatter($e);
    echo $formatter->getHtmlMessage();
}
