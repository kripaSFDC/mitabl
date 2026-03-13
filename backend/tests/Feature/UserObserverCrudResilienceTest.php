<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Mail;
use RuntimeException;
use Tests\TestCase;

class UserObserverCrudResilienceTest extends TestCase
{
    use RefreshDatabase;

    public function test_email_verified_update_does_not_fail_when_mail_delivery_breaks(): void
    {
        Mail::shouldReceive('to->queue')
            ->once()
            ->andThrow(new RuntimeException('SMTP unavailable'));

        $user = User::query()->create([
            'role_id' => 3,
            'first_name' => 'Mi',
            'last_name' => 'Foodie',
            'email' => 'mifoodie@example.test',
            'password' => bcrypt('password123'),
            'phone' => '1234567890',
            'address' => 'Test address',
            'email_verified' => false,
        ]);

        $user->update([
            'email_verified' => true,
        ]);

        $this->assertTrue((bool) $user->fresh()->email_verified);
    }
}
