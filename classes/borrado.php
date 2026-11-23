<?php
/*
 * Borrado lógico: cambia el estado del registro en lugar de eliminarlo (se conserva el historial y no se rompen
 * referencias). Usado por los endpoints delete* del front que no existían.
 */
require_once __DIR__ . '/api.php';

/**
 * Marca como eliminado. $tabla, $colId, $colEstado y $valor son constantes del endpoint (nunca del cliente).
 * $donde: condición extra (p. ej. que sea del voluntario conectado). Responde 404 si no existe o ya estaba eliminado.
 */
function borrarLogico(Database $db, string $tabla, string $colId, int $id, string $colEstado, string $valor, string $donde = '',
                      array $params = [], array $extra = []): void
{
    $sets = ["$colEstado = :valor"];
    foreach ($extra as $col => $_) {
        $sets[] = "$col = :x_$col";
    }
    $db->query("UPDATE $tabla SET " . implode(', ', $sets) . " WHERE $colId = :id AND COALESCE($colEstado, '') <> :valor $donde RETURNING $colId");
    $db->bind(':valor', $valor);
    $db->bind(':id', $id);
    foreach ($extra as $col => $v) {
        $db->bind(":x_$col", $v);
    }
    foreach ($params as $k => $v) {
        $db->bind($k, $v);
    }
    if (!$db->single()) {
        jsonResponse(['error' => 'No encontrado', 'msg' => 'El registro no existe, ya fue eliminado o no le pertenece'], 404);
    }
    jsonResponse(['msg' => 'Registro eliminado', 'id' => $id]);
}
