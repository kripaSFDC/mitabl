<?php

namespace Tests\Feature\Api;

use App\Models\Mikitchn;
use App\Models\Order;
use App\Models\User;
use App\Models\UserRole;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class V2FoodieAccountRoutesTest extends TestCase
{
    use RefreshDatabase;

    public function test_foodie_account_routes_require_authentication(): void
    {
        $this->getJson('/api/v2/account/orders')->assertStatus(401);
        $this->getJson('/api/v2/account/favorites')->assertStatus(401);
        $this->postJson('/api/v2/account/favorites/toggle', ['restaurant_id' => 1])->assertStatus(401);
        $this->getJson('/api/v2/account/payments/history')->assertStatus(401);
    }

    public function test_foodie_account_routes_enforce_customer_role(): void
    {
        $restaurant = $this->createUser(2, 'restaurant-role@example.test');

        $this->actingAs($restaurant, 'api');

        $this->getJson('/api/v2/account/orders')->assertStatus(403);
        $this->getJson('/api/v2/account/favorites')->assertStatus(403);
        $this->postJson('/api/v2/account/favorites/toggle', ['restaurant_id' => 1])->assertStatus(403);
        $this->getJson('/api/v2/account/payments/history')->assertStatus(403);
    }

    public function test_foodie_account_routes_return_predictable_empty_payloads(): void
    {
        $foodie = $this->createUser(3, 'foodie-empty@example.test');
        $this->actingAs($foodie, 'api');

        $this->getJson('/api/v2/account/orders')
            ->assertOk()
            ->assertJsonPath('data.total_count', 0)
            ->assertJsonPath('data.items', [])
            ->assertJsonPath('data.pagination.page', 1)
            ->assertJsonPath('data.pagination.total_pages', 1);

        $this->getJson('/api/v2/account/favorites')
            ->assertOk()
            ->assertJsonPath('data.total_count', 0)
            ->assertJsonPath('data.items', [])
            ->assertJsonPath('data.pagination.page', 1)
            ->assertJsonPath('data.pagination.total_pages', 1);

        $this->getJson('/api/v2/account/payments/history')
            ->assertOk()
            ->assertJsonPath('data.total_count', 0)
            ->assertJsonPath('data.items', [])
            ->assertJsonPath('data.pagination.page', 1)
            ->assertJsonPath('data.pagination.total_pages', 1);
    }

    public function test_legacy_foodie_without_membership_can_access_foodie_endpoints_after_login(): void
    {
        $legacyFoodie = $this->createUser(3, 'legacy-foodie-login@example.test');

        $this->assertDatabaseMissing('user_roles', [
            'user_id' => $legacyFoodie->id,
            'role_id' => 3,
        ]);

        $this->actingAs($legacyFoodie, 'api');

        $this->getJson('/api/v2/account/orders')->assertOk();
        $this->getJson('/api/v2/account/favorites')->assertOk();
        $this->getJson('/api/v2/account/payments/history')->assertOk();

        $this->assertDatabaseHas('user_roles', [
            'user_id' => $legacyFoodie->id,
            'role_id' => 3,
            'status' => 'active',
        ]);
    }

    public function test_legacy_user_can_access_foodie_endpoints_after_role_switch_to_foodie(): void
    {
        $legacyRestaurant = $this->createUser(2, 'legacy-role-switch@example.test');

        $this->assertDatabaseMissing('user_roles', [
            'user_id' => $legacyRestaurant->id,
            'role_id' => 2,
        ]);

        $this->actingAs($legacyRestaurant, 'api');

        $this->postJson('/api/v2/account/switch-role', ['role_id' => 3])
            ->assertOk();

        $this->getJson('/api/v2/account/orders')->assertOk();
        $this->getJson('/api/v2/account/favorites')->assertOk();
        $this->getJson('/api/v2/account/payments/history')->assertOk();

        $this->assertDatabaseHas('user_roles', [
            'user_id' => $legacyRestaurant->id,
            'role_id' => 3,
            'status' => 'active',
        ]);
    }

    public function test_foodie_routes_reject_disabled_membership_even_if_active_role_matches(): void
    {
        $foodie = $this->createUser(3, 'foodie-disabled-membership@example.test');

        DB::table('user_roles')->insert([
            'user_id' => $foodie->id,
            'role_id' => 3,
            'status' => UserRole::STATUS_DISABLED,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $this->actingAs($foodie, 'api');

        $this->getJson('/api/v2/account/orders')->assertStatus(403);
        $this->getJson('/api/v2/account/favorites')->assertStatus(403);
        $this->getJson('/api/v2/account/payments/history')->assertStatus(403);
    }


    public function test_toggle_favorite_updates_state_for_customer(): void
    {
        $foodie = $this->createUser(3, 'foodie-favorite@example.test');
        $restaurantOwner = $this->createUser(2, 'kitchen-favorite@example.test');

        $kitchen = Mikitchn::query()->create([
            'user_id' => $restaurantOwner->id,
            'name' => 'Kitchen Favorite',
            'address' => 'Kitchen Street',
            'phone' => '1234567890',
            'no_of_seats' => 12,
            'timings' => '{}',
            'status' => 1,
        ]);

        $this->actingAs($foodie, 'api');

        $this->postJson('/api/v2/account/favorites/toggle', ['restaurant_id' => $kitchen->id])
            ->assertOk()
            ->assertJsonPath('data.favorite', 1);

        $this->postJson('/api/v2/account/favorites/toggle', ['restaurant_id' => $kitchen->id])
            ->assertOk()
            ->assertJsonPath('data.favorite', 0);
    }

    public function test_order_history_pagination_metadata_is_consistent(): void
    {
        $foodie = $this->createUser(3, 'foodie-pagination@example.test');
        $restaurantOwner = $this->createUser(2, 'kitchen-owner@example.test');

        $kitchen = Mikitchn::query()->create([
            'user_id' => $restaurantOwner->id,
            'name' => 'Kitchen Pagination',
            'address' => 'Kitchen Street',
            'phone' => '1234567890',
            'no_of_seats' => 8,
            'timings' => '{}',
            'status' => 1,
        ]);

        foreach ([Order::STATUS_COMPLETED, Order::STATUS_CONFIRMED, Order::STATUS_CANCELLED] as $index => $status) {
            Order::query()->create([
                'mikitchn_id' => $kitchen->id,
                'user_id' => $foodie->id,
                'dine_in' => 0,
                'take_away' => 1,
                'persons' => 0,
                'delivery_date' => now()->subDays($index + 1)->format('Y-m-d'),
                'delivery_time_from' => '12:00:00',
                'delivery_time_to' => '12:30:00',
                'item_total_price' => 20,
                'taxes' => 2,
                'total_price' => 22,
                'status' => $status,
                'paid' => 1,
            ]);
        }

        $this->actingAs($foodie, 'api');

        $response = $this->getJson('/api/v2/account/orders?limit=2&page=2');

        $response->assertOk()
            ->assertJsonPath('data.total_count', 3)
            ->assertJsonPath('data.pagination.page', 2)
            ->assertJsonPath('data.pagination.limit', 2)
            ->assertJsonPath('data.pagination.total_pages', 2)
            ->assertJsonPath('data.pagination.has_more', false);

        $this->assertCount(1, $response->json('data.items'));
    }


    public function test_orders_reject_unsupported_numeric_status_values(): void
    {
        $foodie = $this->createUser(3, 'foodie-unsupported-status@example.test');

        $this->actingAs($foodie, 'api');

        $this->getJson('/api/v2/account/orders?status=9')
            ->assertStatus(422)
            ->assertJsonPath('isSuccess', false)
            ->assertJsonPath('isError', 'status filter contains unsupported order status values.');
    }

    public function test_orders_and_payments_reject_invalid_status_filter_shape(): void
    {
        $foodie = $this->createUser(3, 'foodie-invalid-filters@example.test');

        $this->actingAs($foodie, 'api');

        $this->getJson('/api/v2/account/orders?status=abc,2')
            ->assertStatus(422)
            ->assertJsonPath('isSuccess', false);

        $this->getJson('/api/v2/account/payments/history?status=succeeded,*')
            ->assertStatus(422)
            ->assertJsonPath('isSuccess', false);
    }

    public function test_payment_history_supports_filters_and_pagination_metadata(): void
    {
        $foodie = $this->createUser(3, 'foodie-payments@example.test');
        $restaurantOwner = $this->createUser(2, 'kitchen-payments@example.test');

        $kitchen = Mikitchn::query()->create([
            'user_id' => $restaurantOwner->id,
            'name' => 'Kitchen Payments',
            'address' => 'Kitchen Street',
            'phone' => '1234567890',
            'no_of_seats' => 10,
            'timings' => '{}',
            'status' => 1,
        ]);

        $firstOrder = Order::query()->create([
            'mikitchn_id' => $kitchen->id,
            'user_id' => $foodie->id,
            'dine_in' => 0,
            'take_away' => 1,
            'persons' => 0,
            'delivery_date' => now()->subDays(2)->format('Y-m-d'),
            'delivery_time_from' => '12:00:00',
            'delivery_time_to' => '12:30:00',
            'item_total_price' => 30,
            'taxes' => 3,
            'total_price' => 33,
            'status' => Order::STATUS_COMPLETED,
            'paid' => 1,
        ]);

        $secondOrder = Order::query()->create([
            'mikitchn_id' => $kitchen->id,
            'user_id' => $foodie->id,
            'dine_in' => 0,
            'take_away' => 1,
            'persons' => 0,
            'delivery_date' => now()->subDay()->format('Y-m-d'),
            'delivery_time_from' => '13:00:00',
            'delivery_time_to' => '13:30:00',
            'item_total_price' => 40,
            'taxes' => 4,
            'total_price' => 44,
            'status' => Order::STATUS_COMPLETED,
            'paid' => 1,
        ]);

        DB::table('payments')->insert([
            [
                'order_id' => $firstOrder->id,
                'payment_id' => 'pi_hist_1',
                'card_id' => 'card_hist_1',
                'amount' => 33,
                'confirm' => 1,
                'status' => 'succeeded',
                'confirm_date_time' => now()->subDays(2),
                'created_at' => now()->subDays(2),
                'updated_at' => now()->subDays(2),
            ],
            [
                'order_id' => $secondOrder->id,
                'payment_id' => 'pi_hist_2',
                'card_id' => 'card_hist_2',
                'amount' => 44,
                'confirm' => 1,
                'status' => 'failed',
                'confirm_date_time' => now()->subDay(),
                'created_at' => now()->subDay(),
                'updated_at' => now()->subDay(),
            ],
        ]);

        $this->actingAs($foodie, 'api');

        $response = $this->getJson('/api/v2/account/payments/history?status=succeeded&limit=1&page=1');

        $response->assertOk()
            ->assertJsonPath('data.total_count', 1)
            ->assertJsonPath('data.pagination.page', 1)
            ->assertJsonPath('data.pagination.limit', 1)
            ->assertJsonPath('data.pagination.total_pages', 1)
            ->assertJsonPath('data.pagination.has_more', false)
            ->assertJsonPath('data.items.0.status', 'succeeded');
    }

    private function createUser(int $roleId, string $email): User
    {
        DB::table('roles')->updateOrInsert(['id' => 2], ['role' => 'Restaurant', 'created_at' => now(), 'updated_at' => now()]);
        DB::table('roles')->updateOrInsert(['id' => 3], ['role' => 'Foodie', 'created_at' => now(), 'updated_at' => now()]);

        return User::query()->create([
            'first_name' => 'Test',
            'last_name' => 'User',
            'email' => $email,
            'password' => Hash::make('password123'),
            'role_id' => $roleId,
            'phone' => '5555555555',
            'address' => 'Test Street',
            'email_verified' => 1,
        ]);
    }
}
