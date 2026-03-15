<?php

namespace Tests\Feature\Api;

use App\Models\DineInSlot;
use App\Models\Foods;
use App\Models\Mikitchn;
use App\Models\Order;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class DiscoveryMenuAccessTest extends TestCase
{
    use RefreshDatabase;

    public function test_restaurant_detail_includes_active_menu_items_for_foodies(): void
    {
        [$foodie, $kitchen] = $this->createFoodieAndKitchen();

        Foods::query()->create([
            'restaurant_id' => $kitchen->id,
            'food_name' => 'Chicken Biryani',
            'pictures' => '[]',
            'price' => 18.50,
            'cookingstyle' => 1,
            'specialDiet' => '[]',
            'description' => 'Slow cooked rice',
            'status' => 1,
            'dine_in' => 1,
            'take_away' => 0,
        ]);

        Foods::query()->create([
            'restaurant_id' => $kitchen->id,
            'food_name' => 'Hidden Special',
            'pictures' => '[]',
            'price' => 21.00,
            'cookingstyle' => 1,
            'specialDiet' => '[]',
            'description' => 'Inactive dish',
            'status' => 0,
            'dine_in' => 1,
            'take_away' => 1,
        ]);

        $this->actingAs($foodie, 'api');

        $this->getJson('/api/v2/discovery/restaurants/' . $kitchen->id)
            ->assertOk()
            ->assertJsonPath('data.id', $kitchen->id)
            ->assertJsonCount(1, 'data.foods')
            ->assertJsonPath('data.foods.0.food_name', 'Chicken Biryani')
            ->assertJsonPath('data.foods.0.dine_in', 1)
            ->assertJsonPath('data.foods.0.take_away', 0);
    }

    public function test_public_menu_endpoint_filters_by_service_type(): void
    {
        [$foodie, $kitchen] = $this->createFoodieAndKitchen();

        Foods::query()->insert([
            [
                'restaurant_id' => $kitchen->id,
                'food_name' => 'Dine In Pasta',
                'pictures' => '[]',
                'price' => 19.00,
                'cookingstyle' => 1,
                'specialDiet' => '[]',
                'description' => 'Fresh pasta',
                'status' => 1,
                'dine_in' => 1,
                'take_away' => 0,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'restaurant_id' => $kitchen->id,
                'food_name' => 'Take Away Pasta',
                'pictures' => '[]',
                'price' => 17.00,
                'cookingstyle' => 1,
                'specialDiet' => '[]',
                'description' => 'Boxed pasta',
                'status' => 1,
                'dine_in' => 0,
                'take_away' => 1,
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);

        $this->actingAs($foodie, 'api');

        $this->getJson('/api/v2/discovery/restaurants/' . $kitchen->id . '/menu?take_away=1')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.food_name', 'Take Away Pasta')
            ->assertJsonPath('data.0.take_away', 1);
    }

    public function test_menu_endpoint_filters_foods_by_schedule_for_requested_date(): void
    {
        [$foodie, $kitchen] = $this->createFoodieAndKitchen('schedule-filter-foodie@example.test', 'Schedule Kitchen');
        $deliveryDate = now()->addDays(2);

        Foods::query()->insert([
            [
                'restaurant_id' => $kitchen->id,
                'food_name' => 'Scheduled Dish',
                'pictures' => '[]',
                'price' => 19.00,
                'cookingstyle' => 1,
                'specialDiet' => '[]',
                'description' => 'Only on selected day',
                'status' => 1,
                'dine_in' => 1,
                'take_away' => 1,
                'available_days' => json_encode([$deliveryDate->dayOfWeek]),
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'restaurant_id' => $kitchen->id,
                'food_name' => 'Other Day Dish',
                'pictures' => '[]',
                'price' => 17.00,
                'cookingstyle' => 1,
                'specialDiet' => '[]',
                'description' => 'Not today',
                'status' => 1,
                'dine_in' => 1,
                'take_away' => 1,
                'available_days' => json_encode([$deliveryDate->copy()->addDay()->dayOfWeek]),
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);

        $this->actingAs($foodie, 'api');

        $this->getJson('/api/v2/discovery/restaurants/' . $kitchen->id . '/menu?delivery_date=' . $deliveryDate->format('Y-m-d'))
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.food_name', 'Scheduled Dish');
    }

    public function test_dine_in_slot_endpoint_returns_remaining_capacity_for_selected_date(): void
    {
        [$foodie, $kitchen] = $this->createFoodieAndKitchen('slot-foodie@example.test', 'Slot Kitchen');
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
            'user_id' => $foodie->id,
            'dine_in' => 1,
            'take_away' => 0,
            'persons' => 2,
            'dine_in_slot_id' => $slot->id,
            'delivery_date' => $deliveryDate->format('Y-m-d'),
            'delivery_time_from' => '18:00:00',
            'delivery_time_to' => '19:00:00',
            'message' => null,
            'item_total_price' => 20,
            'promo_code' => null,
            'taxes' => 0,
            'total_price' => 20,
            'status' => Order::STATUS_REQUESTED,
            'paid' => 0,
        ]);

        $this->actingAs($foodie, 'api');

        $this->getJson('/api/v2/discovery/restaurants/' . $kitchen->id . '/dine-in-slots?date=' . $deliveryDate->format('Y-m-d') . '&persons=2')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $slot->id)
            ->assertJsonPath('data.0.remaining_seats', 2)
            ->assertJsonPath('data.0.is_available', true);
    }

    public function test_search_returns_kitchens_with_matching_dishes(): void
    {
        [$foodie, $matchingKitchen] = $this->createFoodieAndKitchen('search-foodie@example.test', 'Kitchen Search');
        [, $otherKitchen] = $this->createFoodieAndKitchen('search-foodie-2@example.test', 'Other Kitchen');

        Foods::query()->create([
            'restaurant_id' => $matchingKitchen->id,
            'food_name' => 'Creamy Pasta',
            'pictures' => '[]',
            'price' => 16.00,
            'cookingstyle' => 1,
            'specialDiet' => '[]',
            'description' => 'Pasta with sauce',
            'status' => 1,
            'dine_in' => 1,
            'take_away' => 1,
        ]);

        Foods::query()->create([
            'restaurant_id' => $otherKitchen->id,
            'food_name' => 'Biryani',
            'pictures' => '[]',
            'price' => 22.00,
            'cookingstyle' => 1,
            'specialDiet' => '[]',
            'description' => 'Rice dish',
            'status' => 1,
            'dine_in' => 1,
            'take_away' => 1,
        ]);

        $this->actingAs($foodie, 'api');

        $this->getJson('/api/v2/discovery/search?q=pasta')
            ->assertOk()
            ->assertJsonPath('data.total_count', 1)
            ->assertJsonPath('data.kitchens.0.id', $matchingKitchen->id)
            ->assertJsonPath('data.kitchens.0.foods.0.food_name', 'Creamy Pasta');
    }

    public function test_search_respects_per_dish_service_type_filters(): void
    {
        [$foodie, $matchingKitchen] = $this->createFoodieAndKitchen('search-filter-foodie@example.test', 'Filter Kitchen');

        Foods::query()->insert([
            [
                'restaurant_id' => $matchingKitchen->id,
                'food_name' => 'Take Away Pasta',
                'pictures' => '[]',
                'price' => 16.00,
                'cookingstyle' => 1,
                'specialDiet' => '[]',
                'description' => 'Pasta for take away',
                'status' => 1,
                'dine_in' => 0,
                'take_away' => 1,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'restaurant_id' => $matchingKitchen->id,
                'food_name' => 'Dine In Pasta',
                'pictures' => '[]',
                'price' => 18.00,
                'cookingstyle' => 1,
                'specialDiet' => '[]',
                'description' => 'Pasta for dine in',
                'status' => 1,
                'dine_in' => 1,
                'take_away' => 0,
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);

        $this->actingAs($foodie, 'api');

        $this->getJson('/api/v2/discovery/search?q=pasta&take_away=1')
            ->assertOk()
            ->assertJsonPath('data.total_count', 1)
            ->assertJsonCount(1, 'data.kitchens.0.foods')
            ->assertJsonPath('data.kitchens.0.foods.0.food_name', 'Take Away Pasta')
            ->assertJsonPath('data.kitchens.0.foods.0.take_away', 1);
    }

    public function test_search_without_delivery_date_recalculates_total_count_after_food_filtering(): void
    {
        [$foodie, $firstKitchen] = $this->createFoodieAndKitchen('search-no-date-foodie@example.test', 'Alpha Kitchen');
        [, $secondKitchen] = $this->createFoodieAndKitchen('search-no-date-foodie-2@example.test', 'Beta Kitchen');

        Foods::query()->create([
            'restaurant_id' => $firstKitchen->id,
            'food_name' => 'Pasta Alpha',
            'pictures' => '[]',
            'price' => 16.00,
            'cookingstyle' => 1,
            'specialDiet' => '[]',
            'description' => 'Only dine in pasta',
            'status' => 1,
            'dine_in' => 1,
            'take_away' => 0,
        ]);

        Foods::query()->create([
            'restaurant_id' => $secondKitchen->id,
            'food_name' => 'Pasta Beta',
            'pictures' => '[]',
            'price' => 17.00,
            'cookingstyle' => 1,
            'specialDiet' => '[]',
            'description' => 'Available for take away',
            'status' => 1,
            'dine_in' => 0,
            'take_away' => 1,
        ]);

        $this->actingAs($foodie, 'api');

        $this->getJson('/api/v2/discovery/search?q=pasta&take_away=1&limit=1&page=1')
            ->assertOk()
            ->assertJsonPath('data.total_count', 1)
            ->assertJsonCount(1, 'data.kitchens')
            ->assertJsonPath('data.kitchens.0.id', $secondKitchen->id)
            ->assertJsonPath('data.kitchens.0.foods.0.food_name', 'Pasta Beta');
    }

    public function test_search_with_delivery_date_filters_before_pagination(): void
    {
        $deliveryDate = now()->addDays(2);
        [$foodie, $firstKitchen] = $this->createFoodieAndKitchen('search-schedule-foodie@example.test', 'Alpha Kitchen');
        [, $secondKitchen] = $this->createFoodieAndKitchen('search-schedule-foodie-2@example.test', 'Beta Kitchen');

        Foods::query()->create([
            'restaurant_id' => $firstKitchen->id,
            'food_name' => 'Pasta Alpha',
            'pictures' => '[]',
            'price' => 16.00,
            'cookingstyle' => 1,
            'specialDiet' => '[]',
            'description' => 'Unavailable on requested day',
            'status' => 1,
            'dine_in' => 1,
            'take_away' => 1,
            'available_days' => [$deliveryDate->copy()->addDay()->dayOfWeek],
        ]);

        Foods::query()->create([
            'restaurant_id' => $secondKitchen->id,
            'food_name' => 'Pasta Beta',
            'pictures' => '[]',
            'price' => 17.00,
            'cookingstyle' => 1,
            'specialDiet' => '[]',
            'description' => 'Available on requested day',
            'status' => 1,
            'dine_in' => 1,
            'take_away' => 1,
            'available_days' => [$deliveryDate->dayOfWeek],
        ]);

        $this->actingAs($foodie, 'api');

        $this->getJson('/api/v2/discovery/search?q=pasta&delivery_date=' . $deliveryDate->format('Y-m-d') . '&limit=1&page=1')
            ->assertOk()
            ->assertJsonPath('data.total_count', 1)
            ->assertJsonCount(1, 'data.kitchens')
            ->assertJsonPath('data.kitchens.0.id', $secondKitchen->id)
            ->assertJsonPath('data.kitchens.0.foods.0.food_name', 'Pasta Beta');
    }

    public function test_menu_rejects_invalid_service_type_filters(): void
    {
        [$foodie, $kitchen] = $this->createFoodieAndKitchen('invalid-filter-foodie@example.test', 'Invalid Filter Kitchen');

        $this->actingAs($foodie, 'api');

        $this->getJson('/api/v2/discovery/restaurants/' . $kitchen->id . '/menu?take_away=yes')
            ->assertStatus(422)
            ->assertJsonPath('isSuccess', false)
            ->assertJsonPath('isError', 'The take away must be an integer.');
    }

    private function createFoodieAndKitchen(
        string $foodieEmail = 'foodie-discovery@example.test',
        string $kitchenName = 'Discovery Kitchen'
    ): array {
        DB::table('roles')->updateOrInsert(['id' => 2], ['role' => 'Restaurant', 'created_at' => now(), 'updated_at' => now()]);
        DB::table('roles')->updateOrInsert(['id' => 3], ['role' => 'Foodie', 'created_at' => now(), 'updated_at' => now()]);

        $cook = User::query()->create([
            'first_name' => 'Cook',
            'last_name' => 'Owner',
            'email' => str_replace('@', '+cook@', $foodieEmail),
            'password' => Hash::make('password123'),
            'role_id' => 2,
            'phone' => '1111111111',
            'address' => 'Cook Street',
            'email_verified' => 1,
        ]);

        $foodie = User::query()->create([
            'first_name' => 'Foodie',
            'last_name' => 'User',
            'email' => $foodieEmail,
            'password' => Hash::make('password123'),
            'role_id' => 3,
            'phone' => '2222222222',
            'address' => 'Foodie Street',
            'email_verified' => 1,
        ]);

        $kitchen = Mikitchn::query()->create([
            'user_id' => $cook->id,
            'name' => $kitchenName,
            'address' => 'Kitchen Street',
            'phone' => '1234567890',
            'no_of_seats' => 10,
            'timings' => '{}',
            'status' => 1,
            'dine_in' => 1,
            'take_away' => 1,
        ]);

        return [$foodie, $kitchen];
    }
}
