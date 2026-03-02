<?php

namespace Tests;

use Illuminate\Contracts\Console\Kernel;

trait CreatesApplication
{
    /**
     * Creates the application.
     *
     * @return \Illuminate\Foundation\Application
     */
    public function createApplication()
    {
        $this->ensureTestingSqliteDatabaseExists();

        $app = require __DIR__.'/../bootstrap/app.php';

        $app->make(Kernel::class)->bootstrap();

        return $app;
    }

    private function ensureTestingSqliteDatabaseExists(): void
    {
        $dbConnection = $_SERVER['DB_CONNECTION'] ?? $_ENV['DB_CONNECTION'] ?? getenv('DB_CONNECTION');

        if ($dbConnection !== 'sqlite') {
            return;
        }

        $databasePath = $_SERVER['DB_DATABASE'] ?? $_ENV['DB_DATABASE'] ?? getenv('DB_DATABASE');

        if (! is_string($databasePath) || trim($databasePath) === '' || $databasePath === ':memory:') {
            return;
        }

        $isAbsolutePath = str_starts_with($databasePath, DIRECTORY_SEPARATOR)
            || preg_match('/^[A-Za-z]:\\\\/', $databasePath) === 1;

        $resolvedPath = $isAbsolutePath
            ? $databasePath
            : dirname(__DIR__) . DIRECTORY_SEPARATOR . $databasePath;

        $directory = dirname($resolvedPath);
        if (! is_dir($directory)) {
            mkdir($directory, 0777, true);
        }

        if (! file_exists($resolvedPath)) {
            touch($resolvedPath);
        }
    }
}
