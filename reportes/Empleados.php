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

if (!isset($_GET['area'])) {
    $database = new Database();
    $database->query("SELECT e.emp_id,e.per_id,e.area_id,e.car_id,e.emp_estado,a.area_nombre AS 'area',c.car_nombre AS 'cargo', CONCAT(p.per_apellido,' ',p.per_nombre) AS 'nombre' FROM empleados e INNER JOIN areas a ON a.area_id = e.area_id INNER JOIN cargos c ON c.car_id = e.car_id INNER JOIN personas p on p.per_id = e.per_id ORDER BY area, cargo, nombre");
    $rows = $database->resultset();
    $database->closeConnection();
} else {
    // limpia el parametro
    $idArea = htmlentities($_GET['area']);
    $database = new Database();
    $database->query("SELECT e.emp_id,e.per_id,e.area_id,e.car_id,e.emp_estado,a.area_nombre AS 'area',c.car_nombre AS 'cargo', CONCAT(p.per_apellido,' ',p.per_nombre) AS 'nombre' FROM empleados e INNER JOIN areas a ON a.area_id = e.area_id INNER JOIN cargos c ON c.car_id = e.car_id INNER JOIN personas p on p.per_id = e.per_id WHERE e.area_id = :idArea ORDER BY area, cargo, nombre");
    // $database->query('SELECT * FROM empleados WHERE area_id = :idArea');
    $database->bind('idArea', $idArea);
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
                    Listado de Empleados con su cargo y area
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
                    <th class="service">Area</th>
                    <th class="service">Cargo</th>
                    <th class="service">Apellidos / Nombres</th>
                    <th class="service">Estado</th>
                </tr>
            </thead>
            <tbody>';

for ($i = 0; $i < count($rows); $i++) {
    $html .= '
                <tr>
                <td class="service">' . $rows[$i]["area"] . '</td>
                <td class="service">' . $rows[$i]["cargo"] . '</td>
                <td class="service">' . $rows[$i]["nombre"] . '</td>
                <td class="service">' . ($rows[$i]["emp_estado"] === "1" ? "Activo" : "Inactivo") . '</td>
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
