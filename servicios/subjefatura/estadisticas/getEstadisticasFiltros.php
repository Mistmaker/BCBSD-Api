<?php
// use Spipu\Html2Pdf\Html2Pdf;
// DB configuration
include_once("../../../classes/dbconfig.php");
include_once '../../../classes/database.class.php';

// DEFINIR LA ZONA HORARIA
date_default_timezone_set('America/Guayaquil');

// Retorna un json
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header("Access-Control-Allow-Headers: Origin, Content-Type, Accept");
header("Access-Control-Allow-Methods: POST, PUT, OPTIONS");

try {

    $requestMethod = $_SERVER["REQUEST_METHOD"];
    $arrQueryStringParams = array();
    parse_str($_SERVER['QUERY_STRING'], $arrQueryStringParams);
    if (strtoupper($requestMethod) != 'POST') {
        $respuesta = json_encode(array('err' => false, 'mensaje' => 'Metodo no soportado'), JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
        echo $respuesta;
        exit;
    }

    $postdata = file_get_contents("php://input");
    $request = json_decode($postdata);
    if (!$request) {
        jsonResponse(['error' => 'Datos JSON inválidos'], 400);
    }
    // print_r($request);
    $sqlWhere = "WHERE CAST(i.intervencion_fecha AS DATE) BETWEEN '{$request->desde}' and '{$request->hasta}' ";
    if ($request->estacion != 0) {
        $sqlWhere .= " AND i.fk_estacion_id = {$request->estacion}";
    }

    $sqlEstaciones = "SELECT estacion_nombre as Estacion, count(intervencion_id) as cant 
    FROM subjefatura.tb_intervenciones i
    INNER JOIN operaciones.tb_estaciones e ON i.fk_estacion_id = e.estacion_id
    {$sqlWhere}
    group by estacion_nombre order by estacion_nombre";

    $sqlCausas = "SELECT causa_descripcion as Causa, count(intervencion_id) as cant 
    FROM subjefatura.tb_intervenciones i
    INNER JOIN subjefatura.tb_causas c ON i.fk_causa_id = c.causa_id
    {$sqlWhere}
    group by causa_descripcion";

    $sqlIncidencia = "SELECT incidencia_descripcion as Tipo, count(intervencion_id) as cant 
    FROM subjefatura.tb_intervenciones i
    INNER JOIN subjefatura.tb_tipoincidencia ti ON i.fk_incidencia_id = ti.incidencia_id
    {$sqlWhere}
    group by incidencia_descripcion";

    $sqlEmergencias = "SELECT emergencia_descripcion as emergencia, count(intervencion_id) as cant 
    FROM subjefatura.tb_intervenciones i
    INNER JOIN subjefatura.tb_tipoemergencia t ON i.fk_emergencia_id = t.emergencia_id
    {$sqlWhere}
    group by emergencia_descripcion";

    $sqlTotalIntervenciones = "SELECT COUNT(intervencion_id) as total FROM subjefatura.tb_intervenciones i {$sqlWhere}";
    $sqlTotalBeneficiarios = "SELECT SUM(incidencia_beneficiarios) as total_b FROM subjefatura.tb_intervenciones i {$sqlWhere}";
    $sqltotalFallecidos = "SELECT SUM(incidencia_fallecidos) as total_f FROM subjefatura.tb_intervenciones i {$sqlWhere}";

    $arr_stats = array();
    $database = new Database();

    $database->query($sqlEstaciones);
    $rows_estaciones = $database->resultset();

    $database->query($sqlCausas);
    $rows_causas = $database->resultset();

    $database->query($sqlIncidencia);
    $rows_tipo_incidencias = $database->resultset();

    $database->query($sqlEmergencias);
    $rows_emergencias = $database->resultset();

    $database->query($sqlTotalIntervenciones);
    $rows_total_i = $database->single();

    $database->query($sqlTotalBeneficiarios);
    $rows_total_b = $database->single();

    $database->query($sqltotalFallecidos);
    $rows_total_f = $database->single();

    // Día crítico
    $sqlDiaCritico = "SELECT 
            EXTRACT(DOW FROM intervencion_fecha) AS dia_semana,
            COUNT(*) AS total
        FROM subjefatura.tb_intervenciones i
        INNER JOIN operaciones.tb_estaciones e ON i.fk_estacion_id = e.estacion_id
        {$sqlWhere}
        GROUP BY dia_semana
        ORDER BY total DESC
        LIMIT 1;";
    $database->query($sqlDiaCritico);
    $diaCriticoRow = $database->single();
    // Convertir número a nombre
    $dias = ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];
    $diaCritico = $dias[intval($diaCriticoRow['dia_semana'])];

    // HORA CRITICA 
    $sqlHoraCritica = "SELECT 
        TO_CHAR(intervencion_fecha, 'HH24:00') AS hora,
        COUNT(*) AS total
    FROM subjefatura.tb_intervenciones i
    INNER JOIN operaciones.tb_estaciones e ON i.fk_estacion_id = e.estacion_id
    {$sqlWhere}
    GROUP BY hora
    ORDER BY total DESC
    LIMIT 1;";
    $database->query($sqlHoraCritica);
    $horaCriticaRow = $database->single();
    $horaCritica = trim($horaCriticaRow['hora']);

    // MES CRITICO
    $sqlMesCritico = "SELECT 
        EXTRACT(MONTH FROM intervencion_fecha) AS mes_num,
        COUNT(*) AS total
    FROM subjefatura.tb_intervenciones i
    INNER JOIN operaciones.tb_estaciones e ON i.fk_estacion_id = e.estacion_id
    {$sqlWhere}
    GROUP BY mes_num
    ORDER BY total DESC
    LIMIT 1;";
    $database->query($sqlMesCritico);
    $mesCriticoRow = $database->single();
    $meses = [
        1 => 'Enero',
        2 => 'Febrero',
        3 => 'Marzo',
        4 => 'Abril',
        5 => 'Mayo',
        6 => 'Junio',
        7 => 'Julio',
        8 => 'Agosto',
        9 => 'Septiembre',
        10 => 'Octubre',
        11 => 'Noviembre',
        12 => 'Diciembre'
    ];
    $mesCritico = $meses[intval($mesCriticoRow['mes_num'])];

    // $arr_stats["estaciones"] = $rows_estaciones;
    // $arr_stats["causas"] = $rows_causas;
    // $arr_stats["tipo_incidencias"] = $rows_tipo_incidencias;

    // Colores predefinidos
    $chartOptions = [
        "responsive" => true,
        "plugins" => [
            "title" => [
                "display" => true,
                "text" => "Resumen de intervenciones del BCBSD"
            ]
        ],
        "scales" => [
            "x" => [
                "display" => true,
                "title" => ["display" => true]
            ],
            "y" => [
                "display" => true,
                "title" => [
                    "display" => true,
                    "text" => "Cantidad"
                ],
                "suggestedMin" => 0,
                "suggestedMax" => 10
            ]
        ]
    ];
    $colors = ['#ff6384', '#36a2eb', '#ffcd56', '#4bc0c0', '#9966ff', '#ff9f40', '#8bc34a', '#e91e63'];

    $chartEstaciones = [
        "type" => "bar",
        "options" => ["maintainAspectRatio" => false, "responsive" => true],
        "data" => [
            "labels" => ["Estaciones"], // Un solo label de eje X
            "datasets" => array_map(function ($row, $i) use ($colors) {
                return [
                    "label" => $row['estacion'],
                    "data" => [(int)$row['cant']], // cada dataset solo tiene un valor
                    "backgroundColor" => $colors[$i % count($colors)]
                ];
            }, $rows_estaciones, array_keys($rows_estaciones))
        ]
    ];

    $chartCausas = [
        "type" => "bar",
        "options" => ["maintainAspectRatio" => false, "responsive" => true],
        "data" => [
            "labels" => ["Causas"],
            "datasets" => array_map(function ($row, $i) use ($colors) {
                return [
                    "label" => $row['causa'],
                    "data" => [(int)$row['cant']],
                    "backgroundColor" => $colors[$i % count($colors)]
                ];
            }, $rows_causas, array_keys($rows_causas))
        ]
    ];

    $chartTipoIncidencias = [
        "type" => "bar",
        "options" => ["maintainAspectRatio" => false, "responsive" => true],
        "data" => [
            "labels" => ["Incidencias"],
            "datasets" => array_map(function ($row, $i) use ($colors) {
                return [
                    "label" => $row['tipo'],
                    "data" => [(int)$row['cant']],
                    "backgroundColor" => $colors[$i % count($colors)]
                ];
            }, $rows_tipo_incidencias, array_keys($rows_tipo_incidencias))
        ]
    ];

    $chartEmergencias = [
        "type" => "bar",
        "options" => $chartOptions,
        "data" => [
            "labels" => ["Incidencias"],
            "datasets" => array_map(function ($row, $i) use ($colors) {
                return [
                    "label" => $row['emergencia'],
                    "data" => [(int)$row['cant']],
                    "backgroundColor" => $colors[$i % count($colors)]
                ];
            }, $rows_emergencias, array_keys($rows_emergencias))
        ]
    ];

    $database->closeConnection();

    echo json_encode([
        "chartEstaciones" => $chartEstaciones,
        "chartCausas" => $chartCausas,
        "chartTipoIncidencias" => $chartTipoIncidencias,
        "chartEmergencias" => $chartEmergencias,
        "total_i" => $rows_total_i["total"] ?: 0,
        "total_b" => $rows_total_b["total_b"] ?: 0,
        "total_f" => $rows_total_f["total_f"] ?: 0,
        "dia_critico" => $diaCritico,
        "hora_critica" => $horaCritica,
        "mes_critico" => $mesCritico
    ], JSON_UNESCAPED_UNICODE);




    // echo json_encode($arr_stats);
} catch (Throwable $th) {
    // throw $th;
    $respuesta = json_encode(array('err' => false, 'mensaje' => $th), JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
    echo $respuesta;
}
