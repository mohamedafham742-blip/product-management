<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ProductApiController;
use App\Http\Controllers\Api\RecycleBinApiController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes (Laravel Sanctum Authentication)
|--------------------------------------------------------------------------
|
| These routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "api" middleware group.
|
*/

// Public Authentication Endpoint for Flutter App
Route::post('/login', [AuthController::class, 'login'])->name('api.login');

// Protected API Endpoints (Requires Bearer Token)
Route::middleware('auth:sanctum')->group(function () {
    // Current User Profile
    Route::get('/user', [AuthController::class, 'user'])->name('api.user');
    Route::post('/logout', [AuthController::class, 'logout'])->name('api.logout');

    // Products RESTful API
    Route::apiResource('products', ProductApiController::class)->names('api.products');

    // Recycle Bin RESTful API
    Route::get('/recycle-bin', [RecycleBinApiController::class, 'index'])->name('api.recycle-bin.index');
    Route::post('/recycle-bin/{id}/restore', [RecycleBinApiController::class, 'restore'])->name('api.recycle-bin.restore');
    Route::delete('/recycle-bin/{id}/force', [RecycleBinApiController::class, 'forceDelete'])->name('api.recycle-bin.force');
    Route::post('/recycle-bin/restore-all', [RecycleBinApiController::class, 'restoreAll'])->name('api.recycle-bin.restore-all');
    Route::delete('/recycle-bin/empty', [RecycleBinApiController::class, 'emptyTrash'])->name('api.recycle-bin.empty');
});
