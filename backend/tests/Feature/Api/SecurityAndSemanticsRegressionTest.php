<?php

namespace Tests\Feature\Api;

use App\Models\User;
use App\Models\verifyOtp;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class SecurityAndSemanticsRegressionTest extends TestCase
{
    use RefreshDatabase;

    public function test_verify_otp_locks_after_too_many_failed_attempts(): void
    {
        $user = User::create([
            'first_name' => 'Otp',
            'last_name' => 'Tester',
            'email' => 'otp-lock@example.test',
            'password' => Hash::make('password123'),
            'email_verified' => 0,
            'role_id' => 3,
            'phone' => '1234567890',
            'address' => 'Test Street',
        ]);

        verifyOtp::create([
            'user_id' => $user->id,
            'otp' => 111111,
            'expires_at' => now()->addMinutes(10),
            'attempts' => 4,
        ]);

        $response = $this->postJson('/api/verifyOtp', [
            'id' => $user->id,
            'otp' => '999999',
        ]);

        $response->assertStatus(401);
        $this->assertDatabaseHas('verify_otps', [
            'user_id' => $user->id,
            'attempts' => 0,
        ]);
        $this->assertNotNull(verifyOtp::query()->where('user_id', $user->id)->first()?->locked_until);
    }

    public function test_verify_otp_rejects_when_locked(): void
    {
        $user = User::create([
            'first_name' => 'Otp',
            'last_name' => 'Locked',
            'email' => 'otp-locked@example.test',
            'password' => Hash::make('password123'),
            'email_verified' => 0,
            'role_id' => 3,
            'phone' => '1234567890',
            'address' => 'Test Street',
        ]);

        verifyOtp::create([
            'user_id' => $user->id,
            'otp' => 111111,
            'expires_at' => now()->addMinutes(10),
            'attempts' => 0,
            'locked_until' => now()->addMinutes(5),
        ]);

        $this->postJson('/api/verifyOtp', [
            'id' => $user->id,
            'otp' => '111111',
        ])->assertStatus(429);
    }

    public function test_state_changing_get_endpoints_are_rejected(): void
    {
        $this->getJson('/api/v1/food/status/1')->assertStatus(405);
        $this->getJson('/api/v1/togglenotifications')->assertStatus(404);
        $this->getJson('/api/v1/createCheckoutsession')->assertStatus(404);
        $this->getJson('/api/v1/becomefoodie')->assertStatus(404);
        $this->getJson('/api/v1/becomecook')->assertStatus(404);
        $this->getJson('/api/v2/payments/checkout-session')->assertStatus(405);
    }
}
