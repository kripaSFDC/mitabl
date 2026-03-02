<?php

use App\Http\Controllers\Api\ForgotPasswordController;
use Illuminate\Support\Facades\Route;

Route::post('reset-password', [ForgotPasswordController::class, 'sendResetResponse'])->name('reset.password.post');
Route::get('reset-password/{token}', [ForgotPasswordController::class, 'resetPassword']);
