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
    $database->query("SELECT i.ins_documento, i.ins_nombre, i.ins_direccion, i.ins_referencia, i.ins_telefono, i.ins_email, i.ins_empleados, t.tin_descripcion, p.per_documento, CONCAT(p.per_apellido, ' ',p.per_nombre) AS 'Representante', c.can_nombre, pa.par_nombre, z.zon_descripcion, i.ins_recinto 
                    , ( SELECT COUNT(jun_id) FROM juntas WHERE juntas.ins_id = i.ins_id AND jun_genero='M') as 'juntasMasculino'
                    , ( SELECT COUNT(jun_id) FROM juntas WHERE juntas.ins_id = i.ins_id AND jun_genero='F') as 'juntasFemenino'
                    FROM instituciones i 
                    INNER JOIN tipoinstitucion t on t.tin_id = i.tin_id 
                    LEFT OUTER JOIN personas p ON p.per_id = i.per_id 
                    INNER JOIN zonas z ON z.zon_id = i.zon_id 
                    INNER JOIN parroquias pa on pa.par_id = z.par_id 
                    INNER join cantones c on c.can_id = pa.can_id 
                    WHERE i.ins_recinto = 'S'
                    ORDER BY c.can_nombre, pa.par_nombre, z.zon_descripcion, i.ins_nombre");
    $rows = $database->resultset();
    $database->closeConnection();
} else {
    // limpia el parametro
    $idTipo = htmlentities($_GET['tipo']);
    $database = new Database();
    $database->query("SELECT i.ins_documento, i.ins_nombre, i.ins_direccion, i.ins_referencia, i.ins_telefono, i.ins_email, i.ins_empleados, t.tin_descripcion, p.per_documento, CONCAT(p.per_apellido, ' ',p.per_nombre) AS 'Representante', c.can_nombre, pa.par_nombre, z.zon_descripcion, i.ins_recinto 
                    , ( SELECT COUNT(jun_id) FROM juntas WHERE juntas.ins_id = i.ins_id AND jun_genero='M') as 'juntasMasculino'
                    , ( SELECT COUNT(jun_id) FROM juntas WHERE juntas.ins_id = i.ins_id AND jun_genero='F') as 'juntasFemenino'
                    FROM instituciones i 
                    INNER JOIN tipoinstitucion t on t.tin_id = i.tin_id 
                    LEFT OUTER JOIN personas p ON p.per_id = i.per_id 
                    INNER JOIN zonas z ON z.zon_id = i.zon_id 
                    INNER JOIN parroquias pa on pa.par_id = z.par_id 
                    INNER join cantones c on c.can_id = pa.can_id 
                    WHERE tin_id = :idTipo AND i.ins_recinto = 'S' 
                    ORDER BY c.can_nombre, pa.par_nombre, z.zon_descripcion, i.ins_nombre");
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
                    Listado de Recintos Electorales
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
                    <th class="service">Tipo</th>
                    <th class="service">RUC</th>
                    <th class="service">Nombre</th>
                    <th class="service">Dirección</th>
                    <th class="service">Referencia</th>
                    <th class="service">Teléfono</th>
                    <th class="service">Email</th>
                    <th class="service">Representante</th>
                    <th class="service">N. Empleados</th>
                    <th class="service">N. Juntas M.</th>
                    <th class="service">N. Juntas F.</th>
                </tr>
            </thead>
            <tbody>';

for ($i = 0; $i < count($rows); $i++) {
    $html .= '
                <tr>
                <td class="service">' . $rows[$i]["tin_descripcion"] . '</td>
                <td class="service">' . $rows[$i]["ins_documento"] . '</td>
                <td class="service">' . $rows[$i]["ins_nombre"] . '</td>
                <td class="service">' . $rows[$i]["ins_direccion"] . '</td>
                <td class="service">' . $rows[$i]["ins_referencia"] . '</td>
                <td class="service">' . $rows[$i]["ins_telefono"] . '</td>
                <td class="service">' . $rows[$i]["ins_email"] . '</td>
                <td class="service">' . $rows[$i]["Representante"] . '</td>
                <td class="service">' . $rows[$i]["ins_empleados"] . '</td>
                <td class="service">' . $rows[$i]["juntasMasculino"] . '</td>
                <td class="service">' . $rows[$i]["juntasFemenino"] . '</td>
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

$mpdf = new \Mpdf\Mpdf(['mode' => 'utf-8', 'format' => 'A4-L']);
$mpdf->WriteHTML($stylesheet, \Mpdf\HTMLParserMode::HEADER_CSS);

$mpdf->WriteHTML($html);
// $mpdf->addPage();
$mpdf->Output();
    // $mpdf->Output('filename.pdf','F');
