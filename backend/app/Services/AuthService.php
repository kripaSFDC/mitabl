<?php

namespace App\Services;

use App\Mail\sendOTP;
use App\Models\verifyOtp;

class AuthService
{
    public function sendOtp(int $userId, string $email): array
    {
        $otp = rand(1000, 9999);

        $existing = verifyOtp::where('user_id', $userId)->first();
        if ($existing) {
            $saved = verifyOtp::where('user_id', $userId)->update(['otp' => $otp]);
        } else {
            $saved = verifyOtp::create(['user_id' => $userId, 'otp' => $otp]);
        }

        if (!$saved) {
            return ['status' => 401, 'message' => 'Invalid'];
        }

        \Mail::to($email)->send(new sendOTP([
            'subject' => 'Testing Application OTP',
            'otp' => $otp,
        ]));

        return ['status' => 200, 'message' => 'OTP sent successfully'];
    }
}
