<?php

namespace App\Services;

use App\Mail\sendOTP;
use App\Models\verifyOtp;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Throwable;

class AuthService
{
    public function sendOtp(int $userId, string $email): array
    {
        try {
            $otp = random_int(100000, 999999);
            $expiresAt = now()->addMinutes((int) config('auth.otp.expire_minutes', 10));
            $subject = (string) config('auth.otp.subject', 'Testing Application OTP');

            $saved = verifyOtp::query()->updateOrCreate(
                ['user_id' => $userId],
                [
                    'otp' => Hash::make((string) $otp),
                    'expires_at' => $expiresAt,
                    'attempts' => 0,
                    'locked_until' => null,
                ]
            );

            if (! $saved) {
                return ['status' => 401, 'message' => 'Invalid'];
            }

            Mail::to($email)->queue(new sendOTP([
                'subject' => $subject,
                'otp' => $otp,
            ]));

            return ['status' => 200, 'message' => 'OTP sent successfully'];
        } catch (Throwable $throwable) {
            report($throwable);
            return ['status' => 503, 'message' => 'Unable to send OTP at this time.'];
        }
    }
}
