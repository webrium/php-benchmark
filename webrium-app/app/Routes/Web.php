<?php

use App\Controllers\BenchmarkController;
use Webrium\Route;

Route::get('/bench/render', [BenchmarkController::class, 'render']);
Route::get('/bench/json',   [BenchmarkController::class, 'json']);
Route::get('/bench/db',     [BenchmarkController::class, 'db']);
