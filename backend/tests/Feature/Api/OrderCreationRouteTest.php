<?php

namespace Tests\Feature\Api;

use App\Models\DineInSlot;
use App\Models\Foods;
use App\Models\Mikitchn;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Notification;
use Tests\TestCase;

/**
 * Feature A — POST /api/v2/account/orders and /api/v2/orders
 *
 * Covers: 201 take-away, 201 dine-in, 401 unauthenticated,
 *         403 wrong role, 422 bad kitchen.
 */
class OrderCreationRouteTest extends TestCase
{
    use RefreshDatabase;

    public function test_take_away_order_returns_201(): void
    {
        Notification::fake();
        [$kitchen, $foodie, $food] = $this->seedOrderableKitchen();

        $response = $this
            ->actingAs($foodie, 'api')
            ->postJson('/api/v2/account/orders', [
                'kitchen_id' => $kitchen->id,
                'delivery_date' => now()->addDay()->format('Y-m-d'),
                'delivery_time_from' => '12:00',
                'delivery_time_to' => '13:00',
                'taxes' => '0.00',
                'dine_in' => 0,
                'take_away' => 1,
                'item_data' => json_encode([
                    ['id' => $food->id, 'quantity' => 1],
                ]),
            ]);

        $response
            ->assertStatus(201)
            ->assertJsonPath('isSuccess', true)
            ->assertJsonPath('data.take_away', 1);

        $this->assertDatabaseHas('orders', [
            'user_id' => $foodie->id,
            'mikitchn_id' => $kitchen->id,
            'take_away' => 1,
            'dine_in' => 0,
        ]);
    }

    public function test_dine_in_order_returns_201(): void
    {
        Notification::fake();
        [$kitchen, $foodie, $food] = $this->seedOrderableKitchen();

        $deliveryDate = now()->addDay();
        $slot = DineInSlot::query()->create([
            'mikitchn_id' => $kitchen->id,
            'day_of_week' => $deliveryDate->dayOfWeek,
            'start_time' => '18:00:00',
            'end_time' => '19:00:00',
            'seat_capacity' => 6,
            'status' => 1,
        ]);

        $response = $this
            ->actingAs($foodie, 'api')
            ->postJson('/api/v2/orders', [
                'kitchen_id' => $kitchen->id,
                'delivery_date' => $deliveryDate->format('Y-m-d'),
                'taxes' => '0.00',
                'dine_in' => 1,
                'take_away' => 0,
                'persons' => 2,
                'dine_in_slot_id' => $slot->id,
                'item_data' => json_encode([
                    ['id' => $food->id, 'quantity' => 1],
                ]),
            ]);

        $response
            ->assertStatus(201)
            ->assertJsonPath('isSuccess', true)
            ->assertJsonPath('data.dine_in', 1)
            ->assertJsonPath('data.dine_in_slot.id', $slot->id);

        $this->assertDatabaseHas('orders', [
            'user_id' => $foodie->id,
            'mikitchn_id' => $kitchen->id,
            'dine_in' => 1,
            'dine_in_slot_id' => $slot->id,
        ]);
    }

    public function test_unauthenticated_request_returns_401(): void
    {
        $response = $this->postJson('/api/v2/account/orders', [
            'kitchen_id' => 1,
            'delivery_date' => now()->addDay()->format('Y-m-d'),
            'delivery_time_from' => '12:00',
            'delivery_time_to' => '13:00',
            'taxes' => '0.00',
            'dine_in' => 0,
            'take_away' => 1,
            'item_data' => json_encode([['id' => 1, 'quantity' => 1]]),
        ]);

        $response->assertStatus(401);
    }

    public function test_restaurant_role_returns_403(): void
    {
        [$kitchen, , $food, $cook] = $this->seedOrderableKitchen(includeCook: true);

        $response = $this
            ->actingAs($cook, 'api')
            ->postJson('/api/v2/account/orders', [
                'kitchen_id' => $kitchen->id,
                'delivery_date' => now()->addDay()->format('Y-m-d'),
                'delivery_time_from' => '12:00',
                'delivery_time_to' => '13:00',
                'taxes' => '0.00',
                'dine_in' => 0,
                'take_away' => 1,
                'item_data' => json_encode([
                    ['id' => $food->id, 'quantity' => 1],
                ]),
            ]);

        $response->assertStatus(403);
        $this->assertDatabaseCount('orders', 0);
    }

    public function test_nonexistent_kitchen_returns_422(): void
    {
        $this->seedRoles();
        $foodie = User::query()->create([
            'first_name' => 'Foodie',
            'last_name' => 'User',
            'email' => 'foodie-bad-kitchen@example.test',
            'password' => Hash::make('password123'),
            'role_id' => 3,
            'phone' => '9999999999',
            'address' => 'Foodie Street',
            'email_verified' => 1,
        ]);

        $response = $this
            ->actingAs($foodie, 'api')
            ->postJson('/api/v2/account/orders', [
                'kitchen_id' => 999999,
                'delivery_date' => now()->addDay()->format('Y-m-d'),
                'delivery_time_from' => '12:00',
                'delivery_time_to' => '13:00',
                'taxes' => '0.00',
                'dine_in' => 0,
                'take_away' => 1,
                'item_data' => json_encode([['id' => 1, 'quantity' => 1]]),
            ]);

        $response->assertStatus(422);
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
     * @return array{0:Mikitchn,1:User,2:Foods,3?:User}
     */
    private function seedOrderableKitchen(bool $includeCook = false): array
    {
        $this->seedRoles();

        $cook = User::query()->create([
            'first_name' => 'Cook',
            'last_name' => 'User',
            'email' => 'cook-order-create@example.test',
            'password' => Hash::make('password123'),
            'role_id' => 2,
            'phone' => '1111111111',
            'address' => 'Cook Street',
            'email_verified' => 1,
        ]);

        $foodie = User::query()->create([
            'first_name' => 'Foodie',
            'last_name' => 'User',
            'email' => 'foodie-order-create@example.test',
            'password' => Hash::make('password123'),
            'role_id' => 3,
            'phone' => '2222222222',
            'address' => 'Foodie Street',
            'email_verified' => 1,
        ]);

        $kitchen = Mikitchn::query()->create([
            'user_id' => $cook->id,
            'name' => 'Test Kitchen',
            'address' => 'Kitchen Street',
            'phone' => '1234567890',
            'no_of_seats' => 10,
            'timings' => '{}',
            'status' => 1,
            'dine_in' => 1,
            'take_away' => 1,
        ]);

        $food = Foods::query()->create([
            'restaurant_id' => $kitchen->id,
            'food_name' => 'Pasta',
            'pictures' => '[]',
            'price' => 25.00,
            'cookingstyle' => 1,
            'specialDiet' => '[]',
            'description' => 'Good food',
            'status' => 1,
            'dine_in' => 1,
            'take_away' => 1,
        ]);

        return $includeCook
            ? [$kitchen, $foodie, $food, $cook]
            : [$kitchen, $foodie, $food];
    }
}
