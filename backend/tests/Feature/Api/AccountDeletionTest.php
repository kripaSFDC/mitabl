<?php

namespace Tests\Feature\Api;

use App\Models\AccountDeletionRequest;
use App\Models\Mikitchn;
use App\Models\Order;
use App\Models\User;
use App\Models\UserAuthToken;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;
use Tymon\JWTAuth\Facades\JWTAuth;

/**
 * Feature J — DELETE /api/v2/account/delete
 *
 * Covers: 409 active foodie order, 409 active cook kitchen order,
 *         200 success (soft-delete + device_token null), 403 wrong password,
 *         401 post-deletion JWT, purge job force-deletes after 30 days,
 *         purge job skips restored user.
 */
class AccountDeletionTest extends TestCase
{
    use RefreshDatabase;

    public function test_foodie_with_active_order_gets_409(): void
    {
        [$foodie, $kitchen] = $this->seedUserWithKitchen();

        Order::query()->create([
            'user_id' => $foodie->id,
            'mikitchn_id' => $kitchen->id,
            'delivery_date' => now()->addDay()->format('Y-m-d'),
            'delivery_time_from' => '12:00',
            'delivery_time_to' => '13:00',
            'item_total_price' => 25.00,
            'taxes' => 0,
            'total_price' => 25.00,
            'dine_in' => 0,
            'take_away' => 1,
            'status' => Order::STATUS_REQUESTED,
        ]);

        $response = $this
            ->actingAs($foodie, 'api')
            ->deleteJson('/api/v2/account/delete', [
                'password' => 'password123',
            ]);

        $response->assertStatus(409);
        $this->assertNull($foodie->fresh()->deleted_at);
    }

    public function test_cook_with_active_kitchen_order_gets_409(): void
    {
        $this->seedRoles();

        $cook = User::query()->create([
            'first_name' => 'Cook',
            'last_name' => 'Tester',
            'email' => 'cook-del@example.test',
            'password' => Hash::make('password123'),
            'role_id' => 2,
            'phone' => '3333333333',
            'address' => 'Cook Lane',
            'email_verified' => 1,
        ]);

        $kitchen = Mikitchn::query()->create([
            'user_id' => $cook->id,
            'name' => 'Cook Kitchen',
            'address' => 'Kitchen Ave',
            'phone' => '4444444444',
            'no_of_seats' => 4,
            'timings' => '{}',
            'status' => 1,
            'dine_in' => 1,
            'take_away' => 1,
        ]);

        $foodie = User::query()->create([
            'first_name' => 'Foodie',
            'last_name' => 'Buyer',
            'email' => 'foodie-buyer@example.test',
            'password' => Hash::make('password123'),
            'role_id' => 3,
            'phone' => '5555555555',
            'address' => 'Foodie Ave',
            'email_verified' => 1,
        ]);

        Order::query()->create([
            'user_id' => $foodie->id,
            'mikitchn_id' => $kitchen->id,
            'delivery_date' => now()->addDay()->format('Y-m-d'),
            'delivery_time_from' => '12:00',
            'delivery_time_to' => '13:00',
            'item_total_price' => 30.00,
            'taxes' => 0,
            'total_price' => 30.00,
            'dine_in' => 0,
            'take_away' => 1,
            'status' => Order::STATUS_CONFIRMED,
        ]);

        $response = $this
            ->actingAs($cook, 'api')
            ->deleteJson('/api/v2/account/delete', [
                'password' => 'password123',
            ]);

        $response->assertStatus(409);
        $this->assertNull($cook->fresh()->deleted_at);
    }

    public function test_successful_deletion_soft_deletes_and_nulls_device_token(): void
    {
        [$foodie] = $this->seedUserWithKitchen();

        $foodie->update(['device_token' => 'some-fcm-token']);

        $token = JWTAuth::fromUser($foodie);

        $response = $this
            ->withHeader('Authorization', 'Bearer ' . $token)
            ->deleteJson('/api/v2/account/delete', [
                'password' => 'password123',
                'reason' => 'Just testing',
            ]);

        $response
            ->assertOk()
            ->assertJsonPath('isSuccess', true)
            ->assertJsonStructure(['data' => ['deleted_at', 'data_purge_by']]);

        $deletedUser = User::withTrashed()->find($foodie->id);
        $this->assertNotNull($deletedUser->deleted_at);
        $this->assertNull($deletedUser->device_token);

        $this->assertDatabaseHas('account_deletion_requests', [
            'user_id' => $foodie->id,
            'reason' => 'Just testing',
        ]);
    }

    public function test_wrong_password_returns_403(): void
    {
        [$foodie] = $this->seedUserWithKitchen();

        $response = $this
            ->actingAs($foodie, 'api')
            ->deleteJson('/api/v2/account/delete', [
                'password' => 'wrong-password',
            ]);

        $response->assertStatus(403);
        $this->assertNull($foodie->fresh()->deleted_at);
    }

    public function test_jwt_is_invalidated_after_deletion(): void
    {
        [$foodie] = $this->seedUserWithKitchen();

        UserAuthToken::query()->create([
            'user_id' => $foodie->id,
            'latest_token' => 'some-jwt-token',
        ]);

        $token = JWTAuth::fromUser($foodie);

        $this
            ->withHeader('Authorization', 'Bearer ' . $token)
            ->deleteJson('/api/v2/account/delete', [
                'password' => 'password123',
            ])
            ->assertOk();

        $this->assertDatabaseMissing('user_auth_tokens', [
            'user_id' => $foodie->id,
        ]);
    }

    public function test_purge_command_force_deletes_after_30_days(): void
    {
        [$foodie] = $this->seedUserWithKitchen();

        $softDeletedAt = now()->subDays(31);

        // Simulate a soft-deleted user with an old deletion request.
        $foodie->update(['device_token' => null]);
        $foodie->delete();

        AccountDeletionRequest::query()->create([
            'user_id' => $foodie->id,
            'reason' => 'purge test',
            'soft_deleted_at' => $softDeletedAt,
        ]);

        $this->artisan('app:purge-deleted-accounts')
            ->expectsOutput('Purged 1 account(s).')
            ->assertExitCode(0);

        $this->assertNull(User::withTrashed()->find($foodie->id));

        // The FK on account_deletion_requests.user_id is ON DELETE CASCADE,
        // so forceDelete on the user also removes the request row. Verify that.
        $this->assertDatabaseMissing('account_deletion_requests', [
            'user_id' => $foodie->id,
        ]);
    }

    public function test_purge_command_skips_restored_user(): void
    {
        [$foodie] = $this->seedUserWithKitchen();

        $softDeletedAt = now()->subDays(31);

        // Simulate soft-delete and then admin restore.
        $foodie->delete();
        $foodie->restore();

        AccountDeletionRequest::query()->create([
            'user_id' => $foodie->id,
            'reason' => 'restored user test',
            'soft_deleted_at' => $softDeletedAt,
        ]);

        $this->artisan('app:purge-deleted-accounts')
            ->expectsOutput('Purged 0 account(s).')
            ->assertExitCode(0);

        $this->assertNotNull(User::find($foodie->id));
        $this->assertNull(
            AccountDeletionRequest::where('user_id', $foodie->id)->value('data_purged_at')
        );
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

    /**
     * @return array{0:User,1:Mikitchn}
     */
    private function seedUserWithKitchen(): array
    {
        $this->seedRoles();

        $cook = User::query()->create([
            'first_name' => 'Cook',
            'last_name' => 'Owner',
            'email' => 'cook-accdel@example.test',
            'password' => Hash::make('password123'),
            'role_id' => 2,
            'phone' => '1111111111',
            'address' => 'Cook Street',
            'email_verified' => 1,
        ]);

        $foodie = User::query()->create([
            'first_name' => 'Foodie',
            'last_name' => 'Deleter',
            'email' => 'foodie-accdel@example.test',
            'password' => Hash::make('password123'),
            'role_id' => 3,
            'phone' => '2222222222',
            'address' => 'Foodie Street',
            'email_verified' => 1,
        ]);

        $kitchen = Mikitchn::query()->create([
            'user_id' => $cook->id,
            'name' => 'Delete Test Kitchen',
            'address' => 'Kitchen Street',
            'phone' => '3333333333',
            'no_of_seats' => 6,
            'timings' => '{}',
            'status' => 1,
            'dine_in' => 1,
            'take_away' => 1,
        ]);

        return [$foodie, $kitchen];
    }
}
