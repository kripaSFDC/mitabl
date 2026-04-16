<?php

namespace Tests\Feature\Api;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Mail;
use Tests\TestCase;

/**
 * Feature K — POST /api/register (registration security)
 *
 * Covers: 429 rate limit, 422 duplicate phone, 422 duplicate email,
 *         200 soft-deleted phone reuse, 200 valid registration.
 */
class RegistrationSecurityTest extends TestCase
{
    use RefreshDatabase;

    public function test_rate_limit_returns_429_on_sixth_request_from_same_ip(): void
    {
        Mail::fake();
        $this->seedRoles();

        for ($i = 0; $i < 5; $i++) {
            $this->postJson('/api/register', [
                'first_name' => 'Rate',
                'last_name' => 'Tester',
                'email' => "rate-{$i}@example.test",
                'password' => 'secret123',
                'phone' => '+614000000' . str_pad((string) $i, 2, '0', STR_PAD_LEFT),
            ]);
        }

        $response = $this->postJson('/api/register', [
            'first_name' => 'Rate',
            'last_name' => 'Blocked',
            'email' => 'rate-blocked@example.test',
            'password' => 'secret123',
            'phone' => '+61400000099',
        ]);

        $response->assertStatus(429);
    }

    public function test_duplicate_phone_returns_422(): void
    {
        Mail::fake();
        $this->seedRoles();

        User::query()->create([
            'first_name' => 'Existing',
            'last_name' => 'User',
            'email' => 'existing@example.test',
            'password' => bcrypt('password123'),
            'role_id' => 3,
            'phone' => '+61400111222',
            'address' => '',
            'email_verified' => 1,
        ]);

        $response = $this->postJson('/api/register', [
            'first_name' => 'New',
            'last_name' => 'User',
            'email' => 'new-dup-phone@example.test',
            'password' => 'secret123',
            'phone' => '+61400111222',
        ]);

        $response
            ->assertStatus(422)
            ->assertJsonFragment(['isError' => 'The phone has already been taken.']);
    }

    public function test_duplicate_email_returns_422(): void
    {
        Mail::fake();
        $this->seedRoles();

        User::query()->create([
            'first_name' => 'Existing',
            'last_name' => 'User',
            'email' => 'taken@example.test',
            'password' => bcrypt('password123'),
            'role_id' => 3,
            'phone' => '+61400333444',
            'address' => '',
            'email_verified' => 1,
        ]);

        $response = $this->postJson('/api/register', [
            'first_name' => 'New',
            'last_name' => 'User',
            'email' => 'taken@example.test',
            'password' => 'secret123',
            'phone' => '+61400555666',
        ]);

        $response->assertStatus(422);
    }

    public function test_soft_deleted_user_phone_can_be_reused(): void
    {
        Mail::fake();
        $this->seedRoles();

        $old = User::query()->create([
            'first_name' => 'Old',
            'last_name' => 'User',
            'email' => 'old-softdel@example.test',
            'password' => bcrypt('password123'),
            'role_id' => 3,
            'phone' => '+61400777888',
            'address' => '',
            'email_verified' => 1,
        ]);

        $old->delete(); // soft-delete

        $response = $this->postJson('/api/register', [
            'first_name' => 'New',
            'last_name' => 'User',
            'email' => 'new-reuse@example.test',
            'password' => 'secret123',
            'phone' => '+61400777888',
        ]);

        $response
            ->assertOk()
            ->assertJsonPath('isSuccess', true);

        $this->assertDatabaseHas('users', [
            'email' => 'new-reuse@example.test',
            'deleted_at' => null,
        ]);
    }

    public function test_valid_registration_succeeds(): void
    {
        Mail::fake();
        $this->seedRoles();

        $response = $this->postJson('/api/register', [
            'first_name' => 'Fresh',
            'last_name' => 'Foodie',
            'email' => 'fresh-foodie@example.test',
            'password' => 'secret123',
            'phone' => '+61400999000',
        ]);

        $response
            ->assertOk()
            ->assertJsonPath('isSuccess', true)
            ->assertJsonPath('data.email', 'fresh-foodie@example.test')
            ->assertJsonPath('data.role_id', 3);

        $this->assertDatabaseHas('users', [
            'email' => 'fresh-foodie@example.test',
            'role_id' => 3,
        ]);

        Mail::assertQueued(\App\Mail\sendOTP::class);
    }

    // ------------------------------------------------------------------
    // Helpers
    // ------------------------------------------------------------------

    private function seedRoles(): void
    {
        DB::table('roles')->insertOrIgnore([
            ['id' => 2, 'role' => 'Restaurant', 'created_at' => now(), 'updated_at' => now()],
            ['id' => 3, 'role' => 'Foodie', 'created_at' => now(), 'updated_at' => now()],
        ]);
    }
}
