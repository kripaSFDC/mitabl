<?php

use Illuminate\Support\Facades\Route;

Route::view('/', 'frontend.home');
Route::view('/about', 'frontend.about');
Route::view('/privacy-policy', 'privacy');
Route::view('/terms', 'terms');

Route::get('/health', function () {
    return response('ok', 200)->header('Content-Type', 'text/plain');
});
