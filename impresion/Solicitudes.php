<?php
// Retorna un json
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
//Define configuration
include_once("../config.php");

date_default_timezone_set('America/Bogota');
setlocale(LC_TIME, 'spanish');

// Include database class
include '../classes/database.class.php';

// Include mpdf
require_once '../vendor/autoload.php';

if (!isset($_GET['idOficio'])) {
    echo json_encode(array('err' => true, 'mensaje' => "Falta el id del oficio"));
    die;
}

if (!isset($_GET['tipo'])) {
    // echo json_encode( array('err' => true,'mensaje'=>"Falta el tipo de institución") );
    // die;
    $database = new Database();
    // $database->query('SELECT * FROM instituciones i INNER JOIN tipoinstitucion t ON i.tin_id = t.tin_id INNER JOIN personas p ON i.per_id = p.per_id');
    $database->query('SELECT ins_nombre FROM instituciones');
    $rows = $database->resultset();
    $database->closeConnection();
} else {
    // limpia el parametro
    $idTipo = htmlentities($_GET['tipo']);

    $database = new Database();
    $database->query('SELECT ins_nombre FROM instituciones WHERE tin_id = :idTipo');
    $database->bind('idTipo', $idTipo);
    $rows = $database->resultset();
    $database->closeConnection();
}

$encabezado = '';
$cuerpo = '';
$despedida = '';
$firma = '';
$pie = '';

$date = strftime("%d de %B del %Y", strtotime(date("m") . '/' . date("d") . '/' . date("Y")));

$html = array();
$html_temp = '';

if (count($rows) > 0) {

    // Obteniendo el formato
    $database = new Database();
    $database->query('SELECT * FROM oficios WHERE ofi_id = :idOficio');
    $database->bind('idOficio', $_GET['idOficio']);
    $datos = $database->resultset();
    $database->closeConnection();

    if (count($datos) > 0) {
        // $encabezado = str_replace(PHP_EOL, '<br>', $datos[0]["ofi_encabezado"]);
        // $cuerpo = str_replace(PHP_EOL, '<br>', $datos[0]["ofi_cuerpo"]);
        // $despedida = str_replace(PHP_EOL, '<br>', $datos[0]["ofi_despedida"]);
        // $firma = str_replace(PHP_EOL, '<br>', $datos[0]["ofi_firma"]);
        // $pie = str_replace(PHP_EOL, '<br>', $datos[0]["ofi_pie"]);

        //nl2br 
        // $encabezado = nl2br($encabezado);
        // $cuerpo = nl2br($cuerpo);
        // $despedida = nl2br($despedida);
        // $firma = nl2br($firma);
        // $pie = nl2br($pie);

        $encabezado = nl2br($datos[0]["ofi_encabezado"]);
        $cuerpo = nl2br($datos[0]["ofi_cuerpo"]);
        $despedida = nl2br($datos[0]["ofi_despedida"]);
        $firma = nl2br($datos[0]["ofi_firma"]);
        $pie = nl2br($datos[0]["ofi_pie"]);

    }

    for ($i = 0; $i < count($rows); $i++) {
        $html_temp = '
            <body>
                <header class="clearfix">
                    <div id="logo" class="row">
                        <div class="columna1">
                            <img src="assets/img/logo.png" width="80px">
                        </div>
                        <div class="columna2 izq">
                            <div>
                                DELEGACIÓN PROVINCIAL ELECTORAL - ORGANIZACIONES POLÍTICAS <br>
                                <b>SANTO DOMINGO DE LOS TSÁCHILAS</b>
                                <hr>
                                Santo Domingo, ' . $date . '
                            </div>
                        </div>
                    </div>
                </header>
                <main>
                    <div class ="jus">

                    Señores <br>
                    <b>' . $rows[$i]["ins_nombre"] . '</b>
                    <br>
                    Presente.- 
                    <br>
                    <br>
                    
                    ' . $cuerpo . '
                    <br>
                    <br>
                    ' . $despedida . '
                    <br>
                    <br>
                    ' . $firma . '
                    </div>
                    <div id="notices">
                        
                    </div>
                </main>
                <footer>
                    ' . $pie . '
                </footer>
            </body>
            ';
        $html[] = $html_temp;
    }

    $stylesheet = file_get_contents('assets/css/style.css');
    // $stylesheet1 = file_get_contents('assets/css/bootstrap.css');

    $mpdf = new \Mpdf\Mpdf();
    $mpdf->WriteHTML($stylesheet, \Mpdf\HTMLParserMode::HEADER_CSS);
    // $mpdf->WriteHTML($stylesheet1, \Mpdf\HTMLParserMode::HEADER_CSS);

    for ($i = 0; $i < count($html); $i++) {
        $mpdf->WriteHTML($html[$i]);
        if ($i < (count($html) - 1)) {
            $mpdf->addPage();
        }
    }
    // $mpdf->WriteHTML($html1);
    // $mpdf->addPage();
    // $mpdf->WriteHTML($html1);
    $mpdf->Output();
    // $mpdf->Output('filename.pdf','F');

} else {
    echo json_encode(array('err' => true, 'mensaje' => "No hay registros"));
}


// $html1 = '
// <body>
//     <header class="clearfix">
//         <div id="logo" class="row">
//             <div class="columna1">
//                 <img src="assets/img/logo.png" width="80px">
//             </div>
//             <div class="columna2 izq">
//                 <div>
//                     DELEGACIÓN PROVINCIAL ELECTORAL - ORGANIZACIONES POLÍTICAS <br>
//                     <b>SANTO DOMINGO DE LOS TSÁCHILAS</b>
//                     <hr>
//                     Santo Domingo, 21 de Febrero del 2021
//                 </div>
//             </div>
//         </div>
//     </header>
//     <main>
//         <div class ="jus">

//         Señores <br>
//         SUPERMERCADO "GRAN AKÍ" '.count($rows).'<br>
//         Presente.- <br>
//         <br>
//         De mi consideración:<br>
//         <br>
//         Reciba un cordial y atento saludo de quienes conformamos el Consejo Nacional Electorial - Delegación Santo Domingo de los Tsáchilas, a la vez hacemos votos de éxitos en las actividades que diariamente desempeña.<br>
//         <br>
//         Como es de vuestro conocimiento, nos encontramos dentro del Calendario Electoral para las Elecciones Generales 2021, lo que conlleva la ejecución de la actividad principal denominada "Actualización de Circunscripciones Electorales"; por esta razón solicito a Usted, a fin de que autorice a quien corresponda se nos facilite la ubicación de un punto de atención ciudadana para los cambios y actualización de domicilio electoral, cuyo objetivo es la ubicación de la carpa del CNE, mobiliario, un punto eléctrico, acceso a internet y el encargo del mobiliario y equipos informáticos dentro del periodo: 30 de Octubre hasta 30 de Noviembre del 2020. <br>
//         <br>
        
//         </div>
//         <div id="notices">
//         </div>
//     </main>
//     <footer>
        
//     </footer>
// </body>
// ';

    // $stylesheet = file_get_contents('assets/css/style.css');
    // // $stylesheet1 = file_get_contents('assets/css/bootstrap.css');
    
    // $mpdf = new \Mpdf\Mpdf();
    // $mpdf->WriteHTML($stylesheet, \Mpdf\HTMLParserMode::HEADER_CSS);
    // // $mpdf->WriteHTML($stylesheet1, \Mpdf\HTMLParserMode::HEADER_CSS);

    // for ($i=0; $i < ; $i++) { 
    //     # code...
    // }
    // $mpdf->WriteHTML($html1);
    // $mpdf->addPage();
    // $mpdf->WriteHTML($html1);
    // $mpdf->Output();
    // // $mpdf->Output('filename.pdf','F');
