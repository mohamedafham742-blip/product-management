<?php

use App\Http\Controllers\Auth\LoginController;
use App\Http\Controllers\Auth\RegisterController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\ProductController;
use App\Http\Controllers\RecycleBinController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
*/

// Root redirect
Route::get('/', function () {
    return auth()->check() ? redirect()->route('dashboard') : redirect()->route('login');
});

// Guest Authentication Routes
Route::middleware('guest')->group(function () {
    Route::get('/login', [LoginController::class, 'create'])->name('login');
    Route::post('/login', [LoginController::class, 'store']);
    Route::get('/register', [RegisterController::class, 'create'])->name('register');
    Route::post('/register', [RegisterController::class, 'store']);
});

// Authenticated Routes
Route::middleware('auth')->group(function () {
    Route::get('/dashboard', [DashboardController::class, 'index'])->name('dashboard');
    Route::resource('products', ProductController::class)->except(['create', 'edit']);
    
    // Recycle Bin (Trash Management) Routes
    Route::get('/recycle-bin', [RecycleBinController::class, 'index'])->name('recycle-bin.index');
    Route::post('/recycle-bin/{id}/restore', [RecycleBinController::class, 'restore'])->name('recycle-bin.restore');
    Route::delete('/recycle-bin/{id}/force-delete', [RecycleBinController::class, 'forceDelete'])->name('recycle-bin.force-delete');
    Route::post('/recycle-bin/restore-all', [RecycleBinController::class, 'restoreAll'])->name('recycle-bin.restore-all');
    Route::delete('/recycle-bin/empty', [RecycleBinController::class, 'emptyTrash'])->name('recycle-bin.empty');

    Route::post('/logout', [LoginController::class, 'destroy'])->name('logout');
});
