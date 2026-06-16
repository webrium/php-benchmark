<?php

use CodeIgniter\Router\RouteCollection;
use App\Controllers\BenchmarkController;

/** @var RouteCollection $routes */
$routes->get('/', 'Home::index');

$routes->get('/bench/render', [BenchmarkController::class, 'render']);
$routes->get('/bench/json',   [BenchmarkController::class, 'json']);