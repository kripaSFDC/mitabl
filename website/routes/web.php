<?php

use Illuminate\Support\Facades\Route;
/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Here is where you can register web routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| contains the "web" middleware group. Now create something great!
|
*/

Route::get('/', function () {
    return view('frontend.home');
});

Route::get('/about', function () {
    return view('frontend.about');
});
Route::get('/register', function () {
    return view('frontend.registration');
});
Route::get('/contact', function () {
    return view('frontend.contact');
});

// mobile 
Route::get('/mob-contact', function () {
    return view('mob.contact');
});

// Route::get('mob-contact', [UserController::class, 'mobileContact']);

Route::get('/privacy-policy', function () {
    return view('privacy');
});

Route::get('/terms', function () {
    return view('terms');
});

// Route::get('/savecard', function () {
//     return view('savecard');
// });
// Route::get('/savebank', function () {
//     return view('savebank');
// });
