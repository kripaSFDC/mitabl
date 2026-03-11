<?php

namespace Tests\Feature\Api;

use App\Models\User;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class TokenRefreshContractTest extends TestCase
{
    use RefreshDatabase;

    public function test_token_refresh_returns_a_replacement_access_token(): void
    {
        DB::table('roles')->insert([
            ['id' => 2, 'role' => 'Restaurant', 'created_at' => now(), 'updated_at' => now()],
            ['id' => 3, 'role' => 'Foodie', 'created_at' => now(), 'updated_at' => now()],
        ]);

        $user = User::query()->create([
            'first_name' => 'Refresh',
            'last_name' => 'User',
            'email' => 'refresh@example.test',
            'password' => Hash::make('password123'),
            'role_id' => 3,
            'phone' => '1234567890',
            'address' => 'Refresh Street',
            'email_verified' => 1,
        ]);

        $token = auth()->login($user);

        DB::table('user_auth_tokens')->insert([
            'user_id' => $user->id,
            'latest_token' => $token,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->postJson('/api/token/refresh');

        $response->assertStatus(200)
            ->assertJsonPath('data.token_type', 'bearer')
            ->assertJsonPath('data.user.id', $user->id);

        $newToken = (string) $response->json('data.access_token');
        $this->assertNotSame($token, $newToken);
        $this->assertDatabaseHas('user_auth_tokens', [
            'user_id' => $user->id,
            'latest_token' => $newToken,
        ]);
    }

    public function test_token_refresh_allows_recently_expired_access_token_within_refresh_ttl(): void
    {
        DB::table('roles')->insert([
            ['id' => 2, 'role' => 'Restaurant', 'created_at' => now(), 'updated_at' => now()],
            ['id' => 3, 'role' => 'Foodie', 'created_at' => now(), 'updated_at' => now()],
        ]);

        $user = User::query()->create([
            'first_name' => 'Expired',
            'last_name' => 'Token',
            'email' => 'expired-refresh@example.test',
            'password' => Hash::make('password123'),
            'role_id' => 3,
            'phone' => '0987654321',
            'address' => 'Refresh Street',
            'email_verified' => 1,
        ]);

        config(['jwt.ttl' => 1, 'jwt.refresh_ttl' => 60]);

        Carbon::setTestNow(now()->subMinutes(2));
        $token = auth()->login($user);

        DB::table('user_auth_tokens')->updateOrInsert(
            ['user_id' => $user->id],
            [
                'latest_token' => $token,
                'created_at' => now(),
                'updated_at' => now(),
            ]
        );

        Carbon::setTestNow(now()->addMinutes(3));

        try {
            $this->withHeader('Authorization', 'Bearer ' . $token)
                ->postJson('/api/token/refresh')
                ->assertStatus(200)
                ->assertJsonPath('data.user.id', $user->id);
        } finally {
            Carbon::setTestNow();
        }
    }

    public function test_token_refresh_for_restaurant_preserves_kitchen_flag_shape(): void
    {
        DB::table('roles')->insert([
            ['id' => 2, 'role' => 'Restaurant', 'created_at' => now(), 'updated_at' => now()],
            ['id' => 3, 'role' => 'Foodie', 'created_at' => now(), 'updated_at' => now()],
        ]);

        $user = User::query()->create([
            'first_name' => 'Cook',
            'last_name' => 'Refresh',
            'email' => 'cook-refresh@example.test',
            'password' => Hash::make('password123'),
            'role_id' => 2,
            'phone' => '1212121212',
            'address' => 'Kitchen Street',
            'email_verified' => 1,
        ]);

        $token = auth()->login($user);

        DB::table('user_auth_tokens')->updateOrInsert(
            ['user_id' => $user->id],
            [
                'latest_token' => $token,
                'created_at' => now(),
                'updated_at' => now(),
            ]
        );

        $this->withHeader('Authorization', 'Bearer ' . $token)
            ->postJson('/api/token/refresh')
            ->assertStatus(200)
            ->assertJsonPath('data.user.role_id', 2)
            ->assertJsonPath('data.user.is_kitchen_added', 0);
    }

    public function test_token_refresh_requires_a_bearer_token(): void
    {
        $this->postJson('/api/token/refresh')
            ->assertStatus(401)
            ->assertJsonPath('isError', 'Refresh token is missing or malformed.');
    }
}