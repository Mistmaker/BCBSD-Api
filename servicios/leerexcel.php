<?php  

//	//INCLUIR LA CLASE
//	require_once("../classes/PHPExcel.php");
//
//	//INSTANCIAR EL OBJETO
//	$objPHPExcel = PHPExcel_IDFactory::load("excel.xlsx");
//
//	//OBTIENE LA MEDIDA DE LA HOJA
//	$objHoja=$objPHPExcel->getActiveSheet()->toArray(null,true,true,true);
//
//	//RECORRER LAS FILAS
//	foreach ($objHoja as $Indice => $objCelda) {
//		echo $objCelda[0]."-";
//		echo $objCelda[1]."-";
//		echo $objCelda[2]."<br>";
//	}

?>

<?php

error_reporting(E_ALL);
set_time_limit(0);

//date_default_timezone_set('Europe/London');

?>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />

<title>PHPExcel Reader Example #01</title>

</head>
<body>

<h1>PHPExcel Reader Example #01</h1>
<h2>Simple File Reader using PHPExcel_IOFactory::load()</h2>
<?php

/** Include path **/
set_include_path(get_include_path() . PATH_SEPARATOR . '../classes/');

/** PHPExcel_IOFactory */
include 'PHPExcel/IOFactory.php';
include_once("../config.php");
include_once("../classes/database.class.php");

$inputFileName = 'excel.xlsx';
echo 'Loading file ',pathinfo($inputFileName,PATHINFO_BASENAME),' using IOFactory to identify the format<br />';
$objPHPExcel = PHPExcel_IOFactory::load($inputFileName);


echo '<hr />';

$sheetData = $objPHPExcel->getActiveSheet()->toArray(null,true,true,true);
var_dump($sheetData);

	foreach ($sheetData as $Indice => $objCelda) {
		echo $objCelda["A"]."-";
		echo $objCelda["B"]."-";
		echo $objCelda["C"]."-";
		echo $objCelda["D"]."<br>";
	}

?>
<body>
</html>