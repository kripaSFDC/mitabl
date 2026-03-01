<?php

use App\Http\Controllers\Api\ForgotPasswordController;
use Illuminate\Support\Facades\Route;

Route::view('/', 'frontend.home');
Route::view('/about', 'frontend.about');
Route::view('/faq', 'mob.faqs');
Route::view('/privacy-policy', 'privacy');
Route::view('/terms', 'terms');
Route::view('/savecard', 'savecard');
Route::view('/savebank', 'savebank');
Route::view('/mifoodi', 'frontend.mifoodi');

Route::post('reset-password', [ForgotPasswordController::class, 'sendResetResponse'])->name('reset.password.post');
Route::get('reset-password/{token}', [ForgotPasswordController::class, 'resetPassword']);
