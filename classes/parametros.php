<?php
/*
 * Parámetros del sistema (admin.tb_params): validación del valor según el tipo, para Administración > Parámetros.
 * Los parámetros los crean las migraciones; desde la pantalla solo se cambia el valor.
 */
require_once __DIR__ . '/api.php';

const PARAM_TIPOS = [
    'NUMERO' => 'Número', 'TEXTO' => 'Texto simple', 'TEXTO_LARGO' => 'Texto', 'LISTA' => 'Lista',
    'SI_NO' => 'Sí / No', 'JSON' => 'JSON', 'HTML' => 'HTML', 'COLOR' => 'Color',
];
/** Módulo cuyos parámetros (quién es administrador) solo cambia un administrador */
const PARAM_MODULO_PROTEGIDO = 'ADMINISTRACION';
const PARAM_MAX_LARGO = 200000;

/** Tipo conocido (los antiguos o vacíos se tratan como texto) */
function paramTipo(?string $tipo): string
{
    $t = strtoupper(trim((string) $tipo));
    return isset(PARAM_TIPOS[$t]) ? $t : 'TEXTO';
}

/**
 * Valida y normaliza el valor según el tipo. $valor: texto, o arreglo para LISTA y objeto/arreglo para JSON.
 * Devuelve el texto que se guarda. Lanza ValidacionException.
 */
function paramValidar(string $tipo, $valor): string
{
    $tipo = paramTipo($tipo);
    if ($tipo === 'JSON' && (is_array($valor) || is_object($valor))) {
        $valor = json_encode($valor, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    }
    if ($tipo === 'LISTA' && is_array($valor)) {
        $valor = implode('|', array_map(fn($x) => is_scalar($x) ? (string) $x : '', $valor));
    }
    if (!is_scalar($valor) && $valor !== null) {
        throw new ValidacionException('Valor inválido');
    }
    $texto = (string) ($valor ?? '');
    if (strlen($texto) > PARAM_MAX_LARGO) {
        throw new ValidacionException('El valor es demasiado largo');
    }
    switch ($tipo) {
        case 'NUMERO':
            $texto = str_replace(',', '.', trim($texto));
            if ($texto !== '' && !is_numeric($texto)) {
                throw new ValidacionException('Ingrese un número (o déjelo vacío)');
            }
            return $texto;
        case 'TEXTO':
            if (preg_match('/[\r\n]/', $texto)) {
                throw new ValidacionException('El texto simple debe ir en una sola línea');
            }
            return trim($texto);
        case 'LISTA':
            $items = array_map('trim', explode('|', str_replace(["\r", "\n"], '|', $texto)));
            $items = array_values(array_filter($items, fn($x) => $x !== ''));
            $repetidos = array_diff_assoc(array_map('mb_strtoupper', $items), array_unique(array_map('mb_strtoupper', $items)));
            if ($repetidos) {
                throw new ValidacionException('Elemento repetido en la lista: "' . reset($repetidos) . '"');
            }
            return implode('|', $items);
        case 'SI_NO':
            $t = mb_strtoupper(trim($texto));
            $t = ['SÍ' => 'SI', 'S' => 'SI', 'TRUE' => 'SI', '1' => 'SI', 'N' => 'NO', 'FALSE' => 'NO', '0' => 'NO'][$t] ?? $t;
            if (!in_array($t, ['SI', 'NO'], true)) {
                throw new ValidacionException('El valor debe ser SI o NO');
            }
            return $t;
        case 'JSON':
            json_decode($texto);
            if (trim($texto) === '' || json_last_error() !== JSON_ERROR_NONE) {
                throw new ValidacionException('JSON inválido: ' . (trim($texto) === '' ? 'está vacío' : json_last_error_msg()));
            }
            return json_encode(json_decode($texto), JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_PRETTY_PRINT);
        case 'COLOR':
            $t = strtoupper(trim($texto));
            if (!preg_match('/^#[0-9A-F]{6}$/', $t)) {
                throw new ValidacionException('Color inválido: use el formato #RRGGBB');
            }
            return $t;
        default: // TEXTO_LARGO, HTML
            return str_replace("\r\n", "\n", $texto);
    }
}

/** Parámetros con su tipo normalizado y quién los cambió por última vez */
function paramListar(Database $db): array
{
    $db->query("SELECT p.param_id, p.param_key, p.param_name, p.param_value, p.param_type, COALESCE(p.param_modulo, 'GENERAL') AS param_modulo,
                       p.param_actualizado::text AS param_actualizado, u.usuario_login AS actualizado_por
                  FROM admin.tb_params p LEFT JOIN admin.tb_usuarios u ON u.usuario_id = p.fk_usuario_actualiza
                 ORDER BY COALESCE(p.param_modulo, 'GENERAL'), p.param_key");
    return array_map(fn($f) => ['param_id' => (int) $f['param_id'], 'param_type' => paramTipo($f['param_type'])] + $f, $db->resultset());
}
