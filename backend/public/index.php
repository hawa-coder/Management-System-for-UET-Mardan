<?php

use Illuminate\Foundation\Application;
use Illuminate\Http\Request;

define('LARAVEL_START', microtime(true));

// Determine if the application is in maintenance mode...
if (file_exists($maintenance = __DIR__.'/../storage/framework/maintenance.php')) {
    require $maintenance;
}

// Serve the compiled homepage independently of Laravel's cached routes.
$website = __DIR__.'/site/index.html';
$requestPath = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH);
$basePath = rtrim(str_replace('\\', '/', dirname($_SERVER['SCRIPT_NAME'] ?? '/index.php')), '/');
if (in_array($_SERVER['REQUEST_METHOD'] ?? 'GET', ['GET', 'HEAD'], true)
    && in_array($requestPath, [$basePath, $basePath.'/', $basePath.'/index.php'], true)
    && is_file($website)) {
    header('Content-Type: text/html; charset=UTF-8');
    header('Cache-Control: no-cache');
    if (($_SERVER['REQUEST_METHOD'] ?? 'GET') !== 'HEAD') {
        readfile($website);
    }
    exit;
}

// API requests continue through the normal Laravel entry point.
// Register the Composer autoloader...
require __DIR__.'/../vendor/autoload.php';

// Bootstrap Laravel and handle the request...
/** @var Application $app */
$app = require_once __DIR__.'/../bootstrap/app.php';

$kernel = $app->make(Illuminate\Contracts\Http\Kernel::class);
$response = $kernel->handle($request = Request::capture());
$response->send();
$kernel->terminate($request, $response);
