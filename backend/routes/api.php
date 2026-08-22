<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ComplaintController;
use App\Http\Controllers\Api\NoticeController;
use App\Http\Controllers\Api\NotificationController;
use Illuminate\Support\Facades\Route;

Route::post('/login', [AuthController::class, 'login'])->middleware('throttle:5,1');

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/profile', [AuthController::class, 'profile']);
    Route::get('/complaints', [ComplaintController::class, 'index']);
    Route::post('/complaints', [ComplaintController::class, 'store']);
    Route::get('/complaints/{complaint}', [ComplaintController::class, 'show']);
    Route::post('/complaints/{complaint}/transition', [ComplaintController::class, 'transition']);
    Route::get('/notices', [NoticeController::class, 'index']);
    Route::post('/notices', [NoticeController::class, 'store']);
    Route::get('/notifications', [NotificationController::class, 'index']);
    Route::post('/notifications/read-all', [NotificationController::class, 'readAll']);
    Route::post('/notifications/{notification}/read', [NotificationController::class, 'read']);
});
