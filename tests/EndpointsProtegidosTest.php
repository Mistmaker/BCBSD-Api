<?php

use PHPUnit\Framework\TestCase;

/**
 * Verifica que todo endpoint del API (excepto los de login) exija el JWT
 * como primera instrucción, para que ningún archivo nuevo quede desprotegido.
 */
final class EndpointsProtegidosTest extends TestCase
{
    private const PUBLICOS = [
        'servicios/auth/login.php',
        'servicios/auth/loginVoluntarios.php',
    ];

    public static function endpoints(): array
    {
        $raiz = dirname(__DIR__);
        $casos = [];
        foreach (['servicios', 'reportes', 'impresion'] as $carpeta) {
            $it = new RecursiveIteratorIterator(new RecursiveDirectoryIterator("$raiz/$carpeta", FilesystemIterator::SKIP_DOTS));
            foreach ($it as $archivo) {
                $rel = str_replace('\\', '/', substr($archivo->getPathname(), strlen($raiz) + 1));
                if ($archivo->getExtension() !== 'php' || str_starts_with($rel, 'servicios/no_usar/') || in_array($rel, self::PUBLICOS, true)) {
                    continue;
                }
                $casos[$rel] = [$rel];
            }
        }
        ksort($casos);
        return $casos;
    }

    /** @dataProvider endpoints */
    public function testEndpointExigeToken(string $rel): void
    {
        $contenido = file_get_contents(dirname(__DIR__) . '/' . $rel);
        $profundidad = substr_count($rel, '/');
        $esperado = "<?php\nrequire_once __DIR__ . '/" . implode('/', array_fill(0, $profundidad, '..')) . "/classes/auth.php';\n\$auth = requireAuth();\n";

        $this->assertStringStartsWith($esperado, str_replace("\r\n", "\n", $contenido), "$rel debe iniciar con requireAuth()");
    }
}
