<?php

namespace App\Services;

use App\Mail\sendOTP;
use App\Models\verifyOtp;

class AuthService
{
    public function sendOtp(int $userId, string $email): array
    {
        $otp = random_int(100000, 999999);
        $expiresAt = now()->addMinutes((int) config('auth.passwords.users.expire', 10));

        $existing = verifyOtp::where('user_id', $userId)->first();
        if ($existing) {
            $saved = verifyOtp::where('user_id', $userId)->update([
                'otp' => $otp,
                'expires_at' => $expiresAt,
                'attempts' => 0,
                'locked_until' => null,
            ]);
        } else {
            $saved = verifyOtp::create([
                'user_id' => $userId,
                'otp' => $otp,
                'expires_at' => $expiresAt,
                'attempts' => 0,
                'locked_until' => null,
            ]);
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
