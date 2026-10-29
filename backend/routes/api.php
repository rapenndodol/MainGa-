<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\GameController;
use App\Http\Controllers\Api\LibraryController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes - MainGa?
|--------------------------------------------------------------------------
|
| Tahap 1: Autentikasi Pengguna (Register, Login, Logout)
| Tahap 2: Integrasi RAWG, Pencarian & Filter Game, Detail Game
| Tahap 3: Library Pribadi (Daftar, Tambah, Ubah, Hapus)
|
*/

// Public Authentication Endpoints
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

// Protected Endpoints
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/me', [AuthController::class, 'me']);
    Route::get('/user', [AuthController::class, 'me']);

    // Tahap 2: Games, Genres, Platforms
    Route::get('/games', [GameController::class, 'index']);
    Route::get('/games/{id}', [GameController::class, 'show']);
    Route::get('/genres', [GameController::class, 'genres']);
    Route::get('/platforms', [GameController::class, 'platforms']);

    // Tahap 3: Library Pribadi
    Route::get('/library', [LibraryController::class, 'index']);
    Route::post('/library', [LibraryController::class, 'store']);
    Route::get('/library/{id}', [LibraryController::class, 'show']);
    Route::put('/library/{id}', [LibraryController::class, 'update']);
    Route::delete('/library/{id}', [LibraryController::class, 'destroy']);
});
