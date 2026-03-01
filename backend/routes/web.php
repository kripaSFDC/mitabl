<?php

use App\Http\Controllers\Api\ForgotPasswordController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::view('/', 'frontend.home');
Route::view('/about', 'frontend.about');
Route::get('/faq', function (Request $request) {
    if ($request->getHost() !== 'mitabl.com' || !$request->isSecure()) {
        return redirect()->away('https://mitabl.com/faq', 301);
    }

    return response()->file(base_path('../website/public/faq.html'));
});
Route::view('/privacy-policy', 'privacy');
Route::view('/terms', 'terms');
Route::view('/savecard', 'savecard');
Route::view('/savebank', 'savebank');
Route::view('/mifoodi', 'frontend.mifoodi');

Route::post('reset-password', [ForgotPasswordController::class, 'sendResetResponse'])->name('reset.password.post');
Route::get('reset-password/{token}', [ForgotPasswordController::class, 'resetPassword']);
