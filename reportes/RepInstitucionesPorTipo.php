<?php
//incluir la clase de la Bdd
include_once("../config.php");
include_once("../classes/database.class.php");	
	
include('../classes/pdf/class.ezpdf.php'); //require_once("pdf/class.ezpdf.php");


// verifica que se reciba el parametro
if (!isset($_GET['tipo'])) {
    echo json_encode( array('err' => true,'mensaje'=>"Falta el tipo") );
    //die;
}

// limpia el parametro
$tipo = htmlentities($_GET['tipo']);


$pdf =& new Cezpdf('A4');
//seleccionamos la fuente
$pdf->selectFont('../../fonts/Helvetica.afm');

//seteamos la información del documento que se creará
$datacreator = array (
					'Title'=>'Listado de Instituciones',
					'Author'=>'Buenaño Diego',
					'Subject'=>'Listado de Instituciones Publicas y Privadas',
					'Creator'=>'CNE Sto. Dgo.',
					'Producer'=>'CNE'
					);
$pdf->addInfo($datacreator);

//traemos la data de nuestra base de datos
$database = new Database();

If ($tipo =="") {
	$where = "";
}elseif (is_numeric($tipo)) {
	$where = " WHERE SEINS_TIPOIN ='".$tipo."' ";
	$database->query('SELECT SEREF_DESCRI FROM seref_refere where SEREF_CODIGO='.$tipo);
	$TIPO= $database->single();
}


$database->query("SELECT I.SEINS_RUCINS,I.SEINS_NOMBRE,I.SEINS_NUMEMP,I.SEINS_DIRECC,I.SEINS_CAPRIN,I.SEINS_INTERS,I.SEINS_NCALLE,I.SEINS_REFERE,I.SEINS_TELEFO,R1.SEREF_DESCRI AS TIPOIN,P.SEPER_CEDRUC,CONCAT(P.SEPER_APELLI,' ',P.SEPER_NOMBRE) AS NOMBRE FROM seins_instit I INNER JOIN seref_refere R1 ON R1.SEREF_CODIGO = I.SEINS_TIPOIN INNER JOIN seper_person P ON P.SEPER_CODIGO = I.SEPER_CODIGO".$where);
$rows = $database->resultset();

echo $rows[0]["SEINS_RUCINS"];
echo sizeof($rows);
//$Con=new Consulta();
//$reg=$Con->Get_Consulta("seage_agenda A INNER JOIN seper_person T ON T.SEPER_CODIGO = A.SEAGE_EMPLEA INNER JOIN seper_person C ON C.SEPER_CODIGO = A.SEAGE_CLIENT","SEAGE_CODIGO,CONCAT(T.SEPER_NOMBRE,' ',T.SEPER_APELLI) AS ENCARGADO,CONCAT(C.SEPER_NOMBRE,' ',C.SEPER_APELLI)  AS CLIENTE,SEAGE_LUGART AS DIRECC,C.SEPER_TELEFO AS TELEFONO,SEAGE_FECHAT AS FECHA,SEAGE_HORAEN AS HINI, SEAGE_HORASA AS HSAL,SEAGE_ESTADT as ESTT,SEAGE_OBSERV AS TAREAS,SEAGE_ESTADO AS ESTADO","","","",3);

//cargamos la información en el array multidimensional llamado data
for ($i=0;$i<sizeof($rows);$i++)
{//inicio for
	//$rows[$i] = array_map('utf8_encode', $rows[$i]);
	$data[]=array
	(
		"ruc"=>utf8_decode($rows[$i]["SEINS_RUCINS"]),
		"nomb"=>utf8_decode($rows[$i]["SEINS_NOMBRE"]),
		"dire"=>utf8_decode($rows[$i]["SEINS_DIRECC"]),
		"telf"=>utf8_decode($rows[$i]["SEINS_TELEFO"]),
		"tipo"=>utf8_decode($rows[$i]["TIPOIN"]),
		"nemp"=>utf8_decode($rows[$i]["SEINS_NUMEMP"]),
		"tare"=>utf8_decode($rows[$i]["SEINS_REFERE"])
	);
}//fin for

	$titles=array
	(
		"ruc"=>"RUC",
		"nomb"=>"Nombre",
		"dire"=>"Direccion",
		"telf"=>"Telefono",
		"tipo"=>"Tipo",
		"nemp"=>"N Empl.",
		"tare"=>"Referencia"
	);
	
$pdf->ezImage('../../img/logo_cne.jpg',0, 100, none,array('justification'=>'center')); 

//$pdf->ezText("CNE 2016",10);

// $pdf->ezImage('images\png\r_general.png',0, 500, 'none', array('justification'=>'center'));

$options = array(
              'shadeCol'=>array(0.9,0.9,15.9),//Color de las Celdas.
              'xOrientation'=>'center',//El reporte aparecerá Centrado.
              'width'=>550,//Ancho de la Tabla.
              'fontSize' => 8//Tamaño de letra
            );
//ponemos un título
$pdf->ezText("<b>Listado de las Instituciones del Tipo: ".$TIPO."</b>\n",12,array('justification'=>'center'));
//creamos la tabla dentro del pdf
$pdf->ezTable($data,$titles,'',$options);

//$pdf->ezText("\n\n\n",10);
//$pdf->ezText("<b>Fecha:</b> ".date("d/m/Y"),10);
// $pdf->ezText("<b>Hora:</b> ".date("H:i:s")."\n\n",10);
 
ob_end_clean();
$pdf->ezStream();

?>