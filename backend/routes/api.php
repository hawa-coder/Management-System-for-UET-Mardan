<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ComplaintController;
use App\Http\Controllers\Api\NoticeController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\StudentApprovalController;
use App\Http\Controllers\Api\AdviserApprovalController;
use Illuminate\Support\Facades\Route;

Route::post('/login', [AuthController::class, 'login'])->middleware('throttle:5,1');
Route::post('/register', [AuthController::class, 'register'])->middleware('throttle:5,1');
Route::get('/advisers', [AuthController::class, 'advisers']);
Route::post('/forgot-password', [AuthController::class, 'forgotPassword'])->middleware('throttle:3,1');
Route::post('/reset-password', [AuthController::class, 'resetPassword'])->middleware('throttle:5,1');
Route::get('/complaints/{complaint}/attachment', [ComplaintController::class, 'attachment'])
    ->name('complaints.attachment');
Route::get('/notices/{notice}/attachment', [NoticeController::class, 'attachment'])->name('notices.attachment');

Route::middleware(['auth:sanctum', \App\Http\Middleware\EnsureAccountCanAccessApi::class])->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::post('/change-password', [AuthController::class, 'changePassword']);
    Route::get('/profile', [AuthController::class, 'profile']);
    Route::get('/complaints', [ComplaintController::class, 'index']);
    Route::post('/complaints', [ComplaintController::class, 'store']);
    Route::get('/complaints/{complaint}', [ComplaintController::class, 'show']);
    Route::get('/complaints/{complaint}/recipients', [ComplaintController::class, 'recipients']);
    Route::post('/complaints/{complaint}/transition', [ComplaintController::class, 'transition']);
    Route::post('/complaints/{complaint}/comments', [ComplaintController::class, 'comment']);
    Route::post('/complaints/{complaint}/publish-resolution', [ComplaintController::class, 'publishResolution']);
    Route::get('/notices', [NoticeController::class, 'index']);
    Route::get('/notices/options', [NoticeController::class, 'options']);
    Route::post('/notices', [NoticeController::class, 'store']);
    Route::get('/notices/{notice}', [NoticeController::class, 'show']);
    Route::post('/notices/{notice}/update', [NoticeController::class, 'update']);
    Route::delete('/notices/{notice}', [NoticeController::class, 'destroy']);
    Route::post('/notices/{notice}/republish', [NoticeController::class, 'republish']);
    Route::get('/notifications', [NotificationController::class, 'index']);
    Route::post('/notifications/read-all', [NotificationController::class, 'readAll']);
    Route::post('/notifications/{notification}/read', [NotificationController::class, 'read']);
    Route::get('/student-approvals', [StudentApprovalController::class, 'index']);
    Route::post('/student-approvals/{student}', [StudentApprovalController::class, 'update']);
    Route::get('/adviser-approvals', [AdviserApprovalController::class, 'index']);
    Route::post('/adviser-approvals', [AdviserApprovalController::class, 'store']);
    Route::post('/adviser-approvals/{adviser}', [AdviserApprovalController::class, 'update']);
});
