<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\GameController;
use App\Http\Controllers\Api\LibraryController;
use App\Http\Controllers\Api\PriceController;
use App\Http\Controllers\Api\WishlistController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes - MainGa?
|--------------------------------------------------------------------------
|
| Tahap 1: Autentikasi Pengguna (Register, Login, Logout)
| Tahap 2: Integrasi RAWG, Pencarian & Filter Game, Detail Game
| Tahap 3: Library Pribadi (Daftar, Tambah, Ubah, Hapus)
| Tahap 4: Wishlist & Pelacak Harga (CheapShark API, Price History)
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

    // Tahap 4: Pelacak Harga & Wishlist
    Route::get('/games/{id}/prices', [PriceController::class, 'gamePrices']);
    Route::get('/wishlist', [WishlistController::class, 'index']);
    Route::post('/wishlist', [WishlistController::class, 'store']);
    Route::get('/wishlist/{id}', [WishlistController::class, 'show']);
    Route::put('/wishlist/{id}', [WishlistController::class, 'update']);
    Route::delete('/wishlist/{id}', [WishlistController::class, 'destroy']);
});
