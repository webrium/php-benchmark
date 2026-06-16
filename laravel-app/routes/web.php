<?php

use App\Http\Controllers\BenchmarkController;
use Illuminate\Support\Facades\Route;

Route::get('/bench/render', [BenchmarkController::class, 'render']);
Route::get('/bench/db',     [BenchmarkController::class, 'db']);
Route::get('/bench/json',   [BenchmarkController::class, 'json']);
