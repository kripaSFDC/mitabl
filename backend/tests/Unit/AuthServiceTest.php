<?php

namespace Tests\Unit;

use App\Mail\sendOTP;
use App\Models\verifyOtp;
use App\Services\AuthService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Mail;
use Tests\TestCase;

class AuthServiceTest extends TestCase
{
    use RefreshDatabase;

    public function test_send_otp_falls_back_to_synchronous_mail_when_queue_enqueue_fails(): void
    {
        $pendingMail = \Mockery::mock();
        $pendingMail->shouldReceive('queue')
            ->once()
            ->with(\Mockery::type(sendOTP::class))
            ->andThrow(new \RuntimeException('Redis unavailable'));
        $pendingMail->shouldReceive('send')
            ->once()
            ->with(\Mockery::type(sendOTP::class))
            ->andReturnNull();

        Mail::shouldReceive('to')
            ->twice()
            ->with('signup@example.test')
            ->andReturn($pendingMail);

        $response = app(AuthService::class)->sendOtp(42, 'signup@example.test');

        $this->assertSame(200, $response['status']);
        $this->assertDatabaseHas('verify_otps', [
            'user_id' => 42,
        ]);

        $record = verifyOtp::query()->where('user_id', 42)->first();
        $this->assertNotNull($record);
        $this->assertNotSame('', (string) $record->otp);
        $this->assertNotSame('0', (string) $record->otp);
    }

    public function test_send_otp_returns_503_when_queue_and_sync_delivery_fail(): void
    {
        $pendingMail = \Mockery::mock();
        $pendingMail->shouldReceive('queue')
            ->once()
            ->with(\Mockery::type(sendOTP::class))
            ->andThrow(new \RuntimeException('Redis unavailable'));
        $pendingMail->shouldReceive('send')
            ->once()
            ->with(\Mockery::type(sendOTP::class))
            ->andThrow(new \RuntimeException('SMTP unavailable'));

        Mail::shouldReceive('to')
            ->twice()
            ->with('signup@example.test')
            ->andReturn($pendingMail);

        $response = app(AuthService::class)->sendOtp(77, 'signup@example.test');

        $this->assertSame(503, $response['status']);
        $this->assertDatabaseHas('verify_otps', [
            'user_id' => 77,
        ]);
    }
}
