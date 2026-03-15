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
use App\Notifications\PushOrderNotification;
use Tests\TestCase;

class OrderPlacementRouteTest extends TestCase
{
    use RefreshDatabase;

    public function test_foodie_can_place_order_via_root_v2_orders_route(): void
    {
        Notification::fake();
        [$kitchen, $foodie, $food] = $this->seedOrderableKitchen();

        $response = $this
            ->actingAs($foodie, 'api')
            ->postJson('/api/v2/orders', [
                'kitchen_id' => $kitchen->id,
                'delivery_date' => now()->addDay()->format('Y-m-d'),
                'delivery_time_from' => '12:00',
                'delivery_time_to' => '13:00',
                'taxes' => '0.00',
                'dine_in' => 0,
                'take_away' => 1,
                'item_data' => json_encode([
                    ['id' => $food->id, 'quantity' => 2],
                ]),
            ]);

        $response
            ->assertOk()
            ->assertJsonPath('isSuccess', true)
            ->assertJsonPath('data.take_away', 1)
            ->assertJsonPath('data.item_total_price', '50.00');

        $this->assertDatabaseHas('orders', [
            'user_id' => $foodie->id,
            'mikitchn_id' => $kitchen->id,
            'take_away' => 1,
        ]);
        $this->assertDatabaseHas('order_data', [
            'food_id' => $food->id,
            'quantity' => 2,
            'price' => '50.00',
        ]);

        Notification::assertSentTo(
            $kitchen->user,
            PushOrderNotification::class
        );
    }

    public function test_foodie_can_place_order_via_root_orders_route(): void
    {
        Notification::fake();
        [$kitchen, $foodie, $food] = $this->seedOrderableKitchen();

        $response = $this
            ->actingAs($foodie, 'api')
            ->postJson('/api/orders', [
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
            ->assertOk()
            ->assertJsonPath('isSuccess', true)
            ->assertJsonPath('data.take_away', 1)
            ->assertJsonPath('data.item_total_price', '25.00');

        Notification::assertSentTo(
            $kitchen->user,
            PushOrderNotification::class,
            function (PushOrderNotification $notification): bool {
                return $notification->toDatabase()['message'] === 'New order request from Foodie User!';
            }
        );
    }

    public function test_foodie_can_place_order_via_account_orders_alias(): void
    {
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
            ->assertOk()
            ->assertJsonPath('isSuccess', true)
            ->assertJsonPath('data.take_away', 1)
            ->assertJsonPath('data.item_total_price', '25.00');
    }

    public function test_foodie_can_place_dine_in_order_with_selected_slot(): void
    {
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
                'persons' => 3,
                'dine_in_slot_id' => $slot->id,
                'item_data' => json_encode([
                    ['id' => $food->id, 'quantity' => 1],
                ]),
            ]);

        $response
            ->assertOk()
            ->assertJsonPath('isSuccess', true)
            ->assertJsonPath('data.dine_in', 1)
            ->assertJsonPath('data.dine_in_slot.id', $slot->id)
            ->assertJsonPath('data.time_from', '18:00 pm')
            ->assertJsonPath('data.time_to', '19:00 pm');

        $this->assertDatabaseHas('orders', [
            'user_id' => $foodie->id,
            'mikitchn_id' => $kitchen->id,
            'dine_in' => 1,
            'dine_in_slot_id' => $slot->id,
            'persons' => 3,
        ]);
    }

    public function test_restaurant_account_cannot_place_order_via_customer_route(): void
    {
        [$kitchen, $foodie, $food, $cook] = $this->seedOrderableKitchen(includeCook: true);

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

    /**
     * @return array{0:Mikitchn,1:User,2:Foods,3?:User}
     */
    private function seedOrderableKitchen(bool $includeCook = false): array
    {
        DB::table('roles')->insert([
            ['id' => 2, 'role' => 'Restaurant', 'created_at' => now(), 'updated_at' => now()],
            ['id' => 3, 'role' => 'Foodie', 'created_at' => now(), 'updated_at' => now()],
        ]);

        $cook = User::query()->create([
            'first_name' => 'Cook',
            'last_name' => 'User',
            'email' => 'cook-orders-route@example.test',
            'password' => Hash::make('password123'),
            'role_id' => 2,
            'phone' => '1111111111',
            'address' => 'Cook Street',
            'email_verified' => 1,
        ]);

        $foodie = User::query()->create([
            'first_name' => 'Foodie',
            'last_name' => 'User',
            'email' => 'foodie-orders-route@example.test',
            'password' => Hash::make('password123'),
            'role_id' => 3,
            'phone' => '2222222222',
            'address' => 'Foodie Street',
            'email_verified' => 1,
        ]);

        $kitchen = Mikitchn::query()->create([
            'user_id' => $cook->id,
            'name' => 'Kitchen One',
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
