<?php

namespace Tests\Feature\Api;

use Tests\TestCase;

class MobileLoginThrottleSafetyTest extends TestCase
{
    public function test_login_returns_config_error_instead_of_server_error_when_jwt_secret_is_missing(): void
    {
        config(['jwt.secret' => '']);

        $response = $this->postJson('/api/login', [
            'email' => 'mobile-user@example.test',
            'password' => 'password123',
        ]);

        $response
            ->assertStatus(503)
            ->assertJsonPath('isError', 'Authentication service is not configured. Please contact support.');
    }
}
