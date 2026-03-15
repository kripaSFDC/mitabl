<?php

namespace Tests\Feature\Api;

use App\Mail\ResetPassword;
use App\Http\Controllers\Api\ReviewController;
use App\Models\DineInSlot;
use App\Models\Foods;
use App\Models\Mikitchn;
use App\Models\Order;
use App\Models\User;
use App\Services\OrderService;
use Illuminate\Http\Request;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Tests\TestCase;

class CriticalBehaviorRegressionTest extends TestCase
{
    use RefreshDatabase;

    public function test_order_creation_rejects_tampered_totals(): void
    {
        DB::table('roles')->insert([
            ['id' => 2, 'role' => 'Restaurant', 'created_at' => now(), 'updated_at' => now()],
            ['id' => 3, 'role' => 'Foodie', 'created_at' => now(), 'updated_at' => now()],
        ]);

        $cook = User::query()->create([
            'first_name' => 'Cook',
            'last_name' => 'User',
            'email' => 'cook@example.test',
            'password' => Hash::make('password123'),
            'role_id' => 2,
            'phone' => '1111111111',
            'address' => 'Cook Street',
            'email_verified' => 1,
        ]);

        $customer = User::query()->create([
            'first_name' => 'Foodie',
            'last_name' => 'User',
            'email' => 'foodie@example.test',
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
        ]);

        $payload = [
            'kitchen_id' => $kitchen->id,
            'delivery_date' => now()->addDay()->format('Y-m-d'),
            'delivery_time_from' => '12:00',
            'delivery_time_to' => '13:00',
            'item_total_price' => 1.00,
            'taxes' => 0,
            'total_price' => 1.00,
            'dine_in' => 0,
            'take_away' => 1,
            'item_data' => json_encode([
                ['id' => $food->id, 'quantity' => 2, 'price' => 1.00],
            ]),
        ];

        $this->expectException(\InvalidArgumentException::class);
        $this->expectExceptionMessage('item_total_price does not match server-calculated amount.');

        app(OrderService::class)->createOrder($customer, $payload);
    }

    public function test_order_creation_rejects_dishes_unavailable_for_selected_service_type(): void
    {
        DB::table('roles')->insert([
            ['id' => 2, 'role' => 'Restaurant', 'created_at' => now(), 'updated_at' => now()],
            ['id' => 3, 'role' => 'Foodie', 'created_at' => now(), 'updated_at' => now()],
        ]);

        $cook = User::query()->create([
            'first_name' => 'Cook',
            'last_name' => 'User',
            'email' => 'cook-service-type@example.test',
            'password' => Hash::make('password123'),
            'role_id' => 2,
            'phone' => '1111111111',
            'address' => 'Cook Street',
            'email_verified' => 1,
        ]);

        $customer = User::query()->create([
            'first_name' => 'Foodie',
            'last_name' => 'User',
            'email' => 'foodie-service-type@example.test',
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
            'food_name' => 'Take Away Only Pasta',
            'pictures' => '[]',
            'price' => 25.00,
            'cookingstyle' => 1,
            'specialDiet' => '[]',
            'description' => 'Good food',
            'status' => 1,
            'dine_in' => 0,
            'take_away' => 1,
        ]);

        $slot = DineInSlot::query()->create([
            'mikitchn_id' => $kitchen->id,
            'day_of_week' => now()->addDay()->dayOfWeek,
            'start_time' => '12:00:00',
            'end_time' => '13:00:00',
            'seat_capacity' => 10,
            'status' => 1,
        ]);

        $payload = [
            'kitchen_id' => $kitchen->id,
            'delivery_date' => now()->addDay()->format('Y-m-d'),
            'item_total_price' => 25.00,
            'taxes' => 0,
            'total_price' => 25.00,
            'dine_in' => 1,
            'take_away' => 0,
            'persons' => 2,
            'dine_in_slot_id' => $slot->id,
            'item_data' => json_encode([
                ['id' => $food->id, 'quantity' => 1, 'price' => 25.00],
            ]),
        ];

        $this->expectException(\InvalidArgumentException::class);
        $this->expectExceptionMessage('One or more selected dishes are not available for dine-in.');

        app(OrderService::class)->createOrder($customer, $payload);
    }

    public function test_order_creation_rejects_dishes_outside_configured_schedule(): void
    {
        DB::table('roles')->insert([
            ['id' => 2, 'role' => 'Restaurant', 'created_at' => now(), 'updated_at' => now()],
            ['id' => 3, 'role' => 'Foodie', 'created_at' => now(), 'updated_at' => now()],
        ]);

        $cook = User::query()->create([
            'first_name' => 'Cook',
            'last_name' => 'User',
            'email' => 'cook-schedule@example.test',
            'password' => Hash::make('password123'),
            'role_id' => 2,
            'phone' => '1111111111',
            'address' => 'Cook Street',
            'email_verified' => 1,
        ]);

        $customer = User::query()->create([
            'first_name' => 'Foodie',
            'last_name' => 'User',
            'email' => 'foodie-schedule@example.test',
            'password' => Hash::make('password123'),
            'role_id' => 3,
            'phone' => '2222222222',
            'address' => 'Foodie Street',
            'email_verified' => 1,
        ]);

        $deliveryDate = now()->addDays(2);
        $kitchen = Mikitchn::query()->create([
            'user_id' => $cook->id,
            'name' => 'Kitchen Schedule',
            'address' => 'Kitchen Street',
            'phone' => '1234567890',
            'no_of_seats' => 10,
            'timings' => '{}',
            'status' => 1,
            'dine_in' => 0,
            'take_away' => 1,
        ]);

        $food = Foods::query()->create([
            'restaurant_id' => $kitchen->id,
            'food_name' => 'Friday Special',
            'pictures' => '[]',
            'price' => 25.00,
            'cookingstyle' => 1,
            'specialDiet' => '[]',
            'description' => 'Weekly special',
            'status' => 1,
            'dine_in' => 0,
            'take_away' => 1,
            'available_days' => [($deliveryDate->copy()->addDay()->dayOfWeek)],
            'available_from_time' => '12:00:00',
            'available_to_time' => '13:00:00',
        ]);

        $this->expectException(\InvalidArgumentException::class);
        $this->expectExceptionMessage('One or more selected dishes are not available for the chosen date/time.');

        app(OrderService::class)->createOrder($customer, [
            'kitchen_id' => $kitchen->id,
            'delivery_date' => $deliveryDate->format('Y-m-d'),
            'delivery_time_from' => '12:00',
            'delivery_time_to' => '12:30',
            'item_total_price' => 25.00,
            'taxes' => 0,
            'total_price' => 25.00,
            'dine_in' => 0,
            'take_away' => 1,
            'item_data' => json_encode([
                ['id' => $food->id, 'quantity' => 1],
            ]),
        ]);
    }

    public function test_order_creation_rejects_dine_in_bookings_that_exceed_slot_capacity(): void
    {
        DB::table('roles')->insert([
            ['id' => 2, 'role' => 'Restaurant', 'created_at' => now(), 'updated_at' => now()],
            ['id' => 3, 'role' => 'Foodie', 'created_at' => now(), 'updated_at' => now()],
        ]);

        $cook = User::query()->create([
            'first_name' => 'Cook',
            'last_name' => 'User',
            'email' => 'cook-capacity@example.test',
            'password' => Hash::make('password123'),
            'role_id' => 2,
            'phone' => '1111111111',
            'address' => 'Cook Street',
            'email_verified' => 1,
        ]);

        $customer = User::query()->create([
            'first_name' => 'Foodie',
            'last_name' => 'User',
            'email' => 'foodie-capacity@example.test',
            'password' => Hash::make('password123'),
            'role_id' => 3,
            'phone' => '2222222222',
            'address' => 'Foodie Street',
            'email_verified' => 1,
        ]);

        $kitchen = Mikitchn::query()->create([
            'user_id' => $cook->id,
            'name' => 'Capacity Kitchen',
            'address' => 'Kitchen Street',
            'phone' => '1234567890',
            'no_of_seats' => 6,
            'timings' => '{}',
            'status' => 1,
            'dine_in' => 1,
            'take_away' => 1,
        ]);

        $food = Foods::query()->create([
            'restaurant_id' => $kitchen->id,
            'food_name' => 'Dining Pasta',
            'pictures' => '[]',
            'price' => 25.00,
            'cookingstyle' => 1,
            'specialDiet' => '[]',
            'description' => 'Good food',
            'status' => 1,
            'dine_in' => 1,
            'take_away' => 1,
        ]);

        $deliveryDate = now()->addDay();
        $slot = DineInSlot::query()->create([
            'mikitchn_id' => $kitchen->id,
            'day_of_week' => $deliveryDate->dayOfWeek,
            'start_time' => '18:00:00',
            'end_time' => '19:00:00',
            'seat_capacity' => 4,
            'status' => 1,
        ]);

        Order::query()->create([
            'mikitchn_id' => $kitchen->id,
            'user_id' => $customer->id,
            'dine_in' => 1,
            'take_away' => 0,
            'persons' => 3,
            'dine_in_slot_id' => $slot->id,
            'delivery_date' => $deliveryDate->format('Y-m-d'),
            'delivery_time_from' => '18:00:00',
            'delivery_time_to' => '19:00:00',
            'message' => null,
            'item_total_price' => 25,
            'promo_code' => null,
            'taxes' => 0,
            'total_price' => 25,
            'status' => Order::STATUS_REQUESTED,
            'paid' => 0,
        ]);

        $this->expectException(\InvalidArgumentException::class);
        $this->expectExceptionMessage('Selected dine-in slot does not have enough remaining seats.');

        app(OrderService::class)->createOrder($customer, [
            'kitchen_id' => $kitchen->id,
            'delivery_date' => $deliveryDate->format('Y-m-d'),
            'dine_in' => 1,
            'take_away' => 0,
            'persons' => 2,
            'dine_in_slot_id' => $slot->id,
            'item_total_price' => 25.00,
            'taxes' => 0,
            'total_price' => 25.00,
            'item_data' => json_encode([
                ['id' => $food->id, 'quantity' => 1],
            ]),
        ]);
    }

    public function test_order_creation_rejects_inactive_kitchens(): void
    {
        DB::table('roles')->insert([
            ['id' => 2, 'role' => 'Restaurant', 'created_at' => now(), 'updated_at' => now()],
            ['id' => 3, 'role' => 'Foodie', 'created_at' => now(), 'updated_at' => now()],
        ]);

        $cook = User::query()->create([
            'first_name' => 'Cook',
            'last_name' => 'User',
            'email' => 'cook-inactive-kitchen@example.test',
            'password' => Hash::make('password123'),
            'role_id' => 2,
            'phone' => '1111111111',
            'address' => 'Cook Street',
            'email_verified' => 1,
        ]);

        $customer = User::query()->create([
            'first_name' => 'Foodie',
            'last_name' => 'User',
            'email' => 'foodie-inactive-kitchen@example.test',
            'password' => Hash::make('password123'),
            'role_id' => 3,
            'phone' => '2222222222',
            'address' => 'Foodie Street',
            'email_verified' => 1,
        ]);

        $kitchen = Mikitchn::query()->create([
            'user_id' => $cook->id,
            'name' => 'Inactive Kitchen',
            'address' => 'Kitchen Street',
            'phone' => '1234567890',
            'no_of_seats' => 10,
            'timings' => '{}',
            'status' => 0,
            'dine_in' => 0,
            'take_away' => 1,
        ]);

        $food = Foods::query()->create([
            'restaurant_id' => $kitchen->id,
            'food_name' => 'Packed Pasta',
            'pictures' => '[]',
            'price' => 25.00,
            'cookingstyle' => 1,
            'specialDiet' => '[]',
            'description' => 'Good food',
            'status' => 1,
            'dine_in' => 0,
            'take_away' => 1,
        ]);

        $payload = [
            'kitchen_id' => $kitchen->id,
            'delivery_date' => now()->addDay()->format('Y-m-d'),
            'delivery_time_from' => '12:00',
            'delivery_time_to' => '13:00',
            'item_total_price' => 25.00,
            'taxes' => 0,
            'total_price' => 25.00,
            'dine_in' => 0,
            'take_away' => 1,
            'item_data' => json_encode([
                ['id' => $food->id, 'quantity' => 1, 'price' => 25.00],
            ]),
        ];

        $this->expectException(\InvalidArgumentException::class);
        $this->expectExceptionMessage('Selected kitchen is currently unavailable.');

        app(OrderService::class)->createOrder($customer, $payload);
    }

    public function test_order_creation_accepts_duplicate_food_lines_for_same_dish(): void
    {
        DB::table('roles')->insert([
            ['id' => 2, 'role' => 'Restaurant', 'created_at' => now(), 'updated_at' => now()],
            ['id' => 3, 'role' => 'Foodie', 'created_at' => now(), 'updated_at' => now()],
        ]);

        $cook = User::query()->create([
            'first_name' => 'Cook',
            'last_name' => 'User',
            'email' => 'cook-duplicate-lines@example.test',
            'password' => Hash::make('password123'),
            'role_id' => 2,
            'phone' => '1111111111',
            'address' => 'Cook Street',
            'email_verified' => 1,
        ]);

        $customer = User::query()->create([
            'first_name' => 'Foodie',
            'last_name' => 'User',
            'email' => 'foodie-duplicate-lines@example.test',
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
            'dine_in' => 0,
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
            'dine_in' => 0,
            'take_away' => 1,
        ]);

        $order = app(OrderService::class)->createOrder($customer, [
            'kitchen_id' => $kitchen->id,
            'delivery_date' => now()->addDay()->format('Y-m-d'),
            'delivery_time_from' => '12:00',
            'delivery_time_to' => '13:00',
            'item_total_price' => 75.00,
            'taxes' => 0,
            'total_price' => 25.00,
            'dine_in' => 0,
            'take_away' => 1,
            'item_data' => json_encode([
                ['id' => $food->id, 'quantity' => 1],
                ['id' => $food->id, 'quantity' => 2],
            ]),
        ]);

        $this->assertSame($kitchen->id, (int) $order->mikitchn_id);
        $this->assertDatabaseCount('order_data', 2);
        $this->assertDatabaseHas('orders', [
            'id' => $order->id,
            'item_total_price' => '75.00',
        ]);
    }

    public function test_customer_review_requires_linked_completed_order(): void
    {
        DB::table('roles')->insert([
            ['id' => 2, 'role' => 'Restaurant', 'created_at' => now(), 'updated_at' => now()],
            ['id' => 3, 'role' => 'Foodie', 'created_at' => now(), 'updated_at' => now()],
        ]);

        $cook = User::query()->create([
            'first_name' => 'Cook',
            'last_name' => 'User',
            'email' => 'cook-review@example.test',
            'password' => Hash::make('password123'),
            'role_id' => 2,
            'phone' => '3333333333',
            'address' => 'Cook Street',
            'email_verified' => 1,
        ]);

        $customer = User::query()->create([
            'first_name' => 'Foodie',
            'last_name' => 'User',
            'email' => 'foodie-review@example.test',
            'password' => Hash::make('password123'),
            'role_id' => 3,
            'phone' => '4444444444',
            'address' => 'Foodie Street',
            'email_verified' => 1,
        ]);

        $kitchen = Mikitchn::query()->create([
            'user_id' => $cook->id,
            'name' => 'Kitchen Two',
            'address' => 'Kitchen Street',
            'phone' => '1234567890',
            'no_of_seats' => 10,
            'timings' => '{}',
            'status' => 1,
        ]);

        $orderId = DB::table('orders')->insertGetId([
            'mikitchn_id' => $kitchen->id,
            'user_id' => $customer->id,
            'dine_in' => 0,
            'take_away' => 1,
            'persons' => 0,
            'delivery_date' => now()->addDay()->format('Y-m-d'),
            'delivery_time_from' => '12:00:00',
            'delivery_time_to' => '13:00:00',
            'item_total_price' => 20,
            'taxes' => 0,
            'total_price' => 20,
            'status' => Order::STATUS_REQUESTED,
            'paid' => 0,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $this->actingAs($customer, 'api');
        $request = Request::create('/api/v1/addReviewToRestaurant', 'POST', [
            'review' => 'Great',
            'restaurant_id' => $kitchen->id,
            'order_id' => $orderId,
            'review_tag' => 'taste',
            'rating' => 4,
        ]);

        $response = app(ReviewController::class)->addReviewToRestaurant($request);
        $this->assertSame(422, $response->getStatusCode());
    }

    public function test_password_reset_tokens_are_stored_hashed(): void
    {
        Mail::fake();

        $user = User::query()->create([
            'first_name' => 'Reset',
            'last_name' => 'User',
            'email' => 'reset@example.test',
            'password' => Hash::make('password123'),
            'role_id' => 3,
            'phone' => '5555555555',
            'address' => 'Reset Street',
            'email_verified' => 1,
        ]);

        $this->postJson('/api/password/reset', ['email' => $user->email])
            ->assertStatus(200);

        Mail::assertSent(ResetPassword::class, function (ResetPassword $mail) use ($user): bool {
            $row = DB::table(config('auth.passwords.users.table'))->where('email', $user->email)->first();
            if (! $row) {
                return false;
            }

            return (string) $row->token !== (string) $mail->token
                && Hash::check((string) $mail->token, (string) $row->token);
        });
    }
}
