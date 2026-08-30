<?php
// DB configuration
include_once("../../classes/dbconfig.php");
include_once '../../classes/database.class.php';

// DEFINIR LA ZONA HORARIA
date_default_timezone_set('America/Guayaquil');

// Retorna un json
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

try {
    $requestMethod = $_SERVER["REQUEST_METHOD"];
    
    if (strtoupper($requestMethod) != 'GET') {
        // Cambiado a 'err' => true por coherencia de error
        $respuesta = json_encode(array('err' => true, 'mensaje' => 'Metodo no soportado'), JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
        echo $respuesta;
        exit;
    }

    $database = new Database();

    if (!isset($_GET['id'])) {
        // GET general: Listado de todos los partes. 
        // Seleccionamos solo las columnas más importantes para no saturar la red en el listado inicial.
        $sqlGetAll = "
            SELECT 
                p.*,
                e.estacion_nombre 
            FROM operaciones.tb_partes p
            LEFT JOIN operaciones.tb_estaciones e ON p.fk_estacion_id = e.estacion_id
            ORDER BY p.parte_id DESC
        ";
        
        $database->query($sqlGetAll);
        $rows = $database->resultset();
        
    } else {
        // GET por ID: Retorna todo el registro completo de la cabecera
        $id = htmlentities($_GET['id']);
        
        $sqlGetById = "
            SELECT 
                p.*, 
                e.estacion_nombre 
            FROM operaciones.tb_partes p
            LEFT JOIN operaciones.tb_estaciones e ON p.fk_estacion_id = e.estacion_id
            WHERE p.parte_id = :id
        ";
        
        $database->query($sqlGetById);
        $database->bind('id', $id);
        $rows = $database->single();
        
        /* 
         * OPCIONAL: Si necesitas que el JSON devuelva también las unidades, 
         * el personal y los detalles en una sola petición, puedes hacer las consultas
         * aquí y adjuntarlas al array principal antes de codificarlo a JSON.
         * 
         * Ejemplo:
         * $database->query("SELECT * FROM operaciones.tb_parte_unidades WHERE fk_parte_id = :id");
         * $database->bind('id', $id);
         * $rows['unidades'] = $database->resultset();
         */
    }
    
    $database->closeConnection();
    
    // Devolver la respuesta en JSON
    echo json_encode($rows, JSON_UNESCAPED_UNICODE);

} catch (Throwable $th) {
    // Es más seguro imprimir $th->getMessage() que el objeto completo $th
    $respuesta = json_encode(array('err' => true, 'mensaje' => $th->getMessage()), JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
    echo $respuesta;
}
?>