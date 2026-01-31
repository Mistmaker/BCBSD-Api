<?php
// Retorna un json
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
//Define configuration
include_once("../config.php");

// Include database class
include '../classes/database.class.php';

// Include mpdf
require_once '../vendor/autoload.php';

date_default_timezone_set('America/Bogota');
setlocale(LC_TIME, 'spanish');
$date = strftime("%d de %B del %Y", strtotime(date("m") . '/' . date("d") . '/' . date("Y")));

if (!isset($_GET['tipo'])) {
    $database = new Database();
    $database->query('SELECT * FROM personas ORDER BY per_apellido, per_nombre');
    $rows = $database->resultset();
    $database->closeConnection();
} else {
    // limpia el parametro
    $idTipo = htmlentities($_GET['tipo']);
    $database = new Database();
    $database->query('SELECT * FROM personas WHERE tpe_id = :idTipo ORDER BY per_apellido, per_nombre');
    $database->bind('idTipo', $idTipo);
    $rows = $database->resultset();
    $database->closeConnection();
}

$html = '
<body>
    <header class="clearfix">
        <div id="logo" class="row">
            <div class="columna1">
                <img src="plantilla/logo.png" width="80px">
            </div>
            <div class="columna2 izq">
                <div>
                    DELEGACIÓN PROVINCIAL ELECTORAL - ORGANIZACIONES POLÍTICAS <br>
                    <b>SANTO DOMINGO DE LOS TSÁCHILAS</b> <br>
                    Listado de personas
                    <hr>
                    Santo Domingo, ' . $date . '
                </div>
            </div>
        </div>
    </header>
    <main>
        <table>
            <thead>
                <tr>
                    <th class="service">C.I./RUC</th>
                    <th class="service">Nombres</th>
                    <th class="service">Dirección</th>
                    <th class="service">Teléfono</th>
                    <th class="service">Email</th>
                </tr>
            </thead>
            <tbody>';

for ($i = 0; $i < count($rows); $i++) {
    $html .= '
                <tr>
                <td class="service">' . $rows[$i]["per_documento"] . '</td>
                <td class="service">' . $rows[$i]["per_apellido"] . ' ' . $rows[$i]["per_nombre"] . '</td>
                <td class="service">' . $rows[$i]["per_direccion"] . '</td>
                <td class="service">' . $rows[$i]["per_telefono"] . '</td>
                <td class="service">' . $rows[$i]["per_email"] . '</td>
                </tr>';
}


$html .= '
            </tbody>
        </table>
        <div id="notices">
        </div>
    </main>
    <footer>
        
    </footer>
</body>
';

$stylesheet = file_get_contents('plantilla/style.css');

$mpdf = new \Mpdf\Mpdf();
$mpdf->WriteHTML($stylesheet, \Mpdf\HTMLParserMode::HEADER_CSS);

$mpdf->WriteHTML($html);
// $mpdf->addPage();
$mpdf->Output();
    // $mpdf->Output('filename.pdf','F');
