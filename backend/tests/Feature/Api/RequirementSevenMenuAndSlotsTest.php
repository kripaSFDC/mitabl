<?php

namespace Tests\Feature\Api;

use App\Models\DineInSlot;
use App\Models\Foods;
use App\Models\Mikitchn;
use App\Models\User;
use App\Models\UserRole;
use App\Services\DineInSlotService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class RequirementSevenMenuAndSlotsTest extends TestCase
{
    use RefreshDatabase;

    public function test_take_away_order_rejects_food_outside_scheduled_time_window(): void
    {
        [$cook, $foodie, $kitchen] = $this->createKitchenFixture();

        $food = Foods::query()->create([
            'restaurant_id' => $kitchen->id,
            'food_name' => 'Friday Lamb',
            'pictures' => '[]',
            'price' => 22.00,
            'cookingstyle' => 1,
            'specialDiet' => '[]',
            'description' => 'Weekend special',
            'status' => 1,
            'dine_in' => 0,
            'take_away' => 1,
            'available_days' => [5],
            'available_from_time' => '18:00:00',
            'available_to_time' => '20:00:00',
        ]);

        $nextFriday = now()->next('Friday')->format('Y-m-d');

        $this->actingAs($foodie, 'api')
            ->postJson('/api/v2/orders', [
                'kitchen_id' => $kitchen->id,
                'delivery_date' => $nextFriday,
                'delivery_time_from' => '12:00',
                'delivery_time_to' => '13:00',
                'taxes' => '0.00',
                'dine_in' => 0,
                'take_away' => 1,
                'item_data' => json_encode([
                    ['id' => $food->id, 'quantity' => 1],
                ]),
            ])
            ->assertStatus(422)
            ->assertJsonPath('isError', 'One or more selected dishes are not available for the chosen date/time.');
    }

    public function test_food_schedule_is_preserved_when_editing_without_schedule_fields(): void
    {
        Storage::fake('my_files');
        [$cook, $foodie, $kitchen] = $this->createKitchenFixture();

        $food = Foods::query()->create([
            'restaurant_id' => $kitchen->id,
            'food_name' => 'Weekend Brunch',
            'pictures' => '[]',
            'price' => 18.50,
            'cookingstyle' => 1,
            'specialDiet' => '[1]',
            'description' => 'Brunch item',
            'status' => 1,
            'dine_in' => 1,
            'take_away' => 0,
            'available_date' => now()->addDays(7)->toDateString(),
            'available_days' => [0, 6],
            'available_from_time' => '09:00:00',
            'available_to_time' => '13:00:00',
        ]);

        $this->actingAs($cook, 'api')
            ->post('/api/v2/food/editfood', [
                'food_id' => $food->id,
                'food_name' => 'Weekend Brunch Updated',
                'cookingstyle' => 1,
                'specialDiet' => [1],
                'price' => '19.50',
                'description' => 'Updated brunch item',
                'dine_in' => 1,
                'take_away' => 0,
            ])
            ->assertOk();

        $food->refresh();

        $this->assertSame(now()->addDays(7)->toDateString(), $food->available_date?->toDateString());
        $this->assertSame([0, 6], array_map('intval', $food->available_days ?? []));
        $this->assertSame('09:00:00', $food->available_from_time);
        $this->assertSame('13:00:00', $food->available_to_time);
    }

    public function test_food_update_rejects_partial_schedule_window(): void
    {
        Storage::fake('my_files');
        [$cook, $foodie, $kitchen] = $this->createKitchenFixture();

        $food = Foods::query()->create([
            'restaurant_id' => $kitchen->id,
            'food_name' => 'Breakfast Dish',
            'pictures' => '[]',
            'price' => 12.00,
            'cookingstyle' => 1,
            'specialDiet' => '[1]',
            'description' => 'Breakfast item',
            'status' => 1,
            'dine_in' => 1,
            'take_away' => 1,
        ]);

        $this->actingAs($cook, 'api')
            ->post('/api/v2/food/editfood', [
                'food_id' => $food->id,
                'food_name' => 'Breakfast Dish',
                'cookingstyle' => 1,
                'specialDiet' => [1],
                'price' => '12.00',
                'description' => 'Breakfast item',
                'dine_in' => 1,
                'take_away' => 1,
                'available_from_time' => '09:00',
            ])
            ->assertStatus(422)
            ->assertJsonPath('isError', 'The available to time field is required when available from time is present.');
    }

    public function test_food_update_rejects_specific_date_and_recurring_days_combined(): void
    {
        Storage::fake('my_files');
        [$cook, $foodie, $kitchen] = $this->createKitchenFixture();

        $food = Foods::query()->create([
            'restaurant_id' => $kitchen->id,
            'food_name' => 'Weekend Dish',
            'pictures' => '[]',
            'price' => 14.00,
            'cookingstyle' => 1,
            'specialDiet' => '[1]',
            'description' => 'Weekend item',
            'status' => 1,
            'dine_in' => 1,
            'take_away' => 1,
        ]);

        $this->actingAs($cook, 'api')
            ->post('/api/v2/food/editfood', [
                'food_id' => $food->id,
                'food_name' => 'Weekend Dish',
                'cookingstyle' => 1,
                'specialDiet' => [1],
                'price' => '14.00',
                'description' => 'Weekend item',
                'dine_in' => 1,
                'take_away' => 1,
                'available_date' => now()->addDay()->format('Y-m-d'),
                'available_days' => [5, 6],
            ])
            ->assertStatus(422)
            ->assertJsonPath('isError', 'Choose either a specific available date or recurring available days for a food item, not both.');
    }

    public function test_discovery_dine_in_slots_reports_remaining_capacity_for_person_count(): void
    {
        [$cook, $foodie, $kitchen] = $this->createKitchenFixture(['no_of_seats' => 4, 'dine_in' => 1, 'take_away' => 0]);

        $slot = DineInSlot::query()->create([
            'mikitchn_id' => $kitchen->id,
            'day_of_week' => now()->addDay()->dayOfWeek,
            'start_time' => '18:00:00',
            'end_time' => '19:00:00',
            'seat_capacity' => 4,
            'status' => 1,
        ]);

        DB::table('orders')->insert([
            'mikitchn_id' => $kitchen->id,
            'user_id' => $foodie->id,
            'dine_in' => 1,
            'take_away' => 0,
            'persons' => 3,
            'dine_in_slot_id' => $slot->id,
            'delivery_date' => now()->addDay()->format('Y-m-d'),
            'delivery_time_from' => '18:00:00',
            'delivery_time_to' => '19:00:00',
            'item_total_price' => 10,
            'taxes' => 0,
            'total_price' => 10,
            'status' => 2,
            'paid' => 0,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $this->actingAs($foodie, 'api')
            ->getJson('/api/v2/discovery/restaurants/' . $kitchen->id . '/dine-in-slots?date=' . now()->addDay()->format('Y-m-d') . '&persons=2')
            ->assertOk()
            ->assertJsonPath('data.0.id', $slot->id)
            ->assertJsonPath('data.0.remaining_seats', 1)
            ->assertJsonPath('data.0.status', 0)
            ->assertJsonPath('data.0.is_available', false);
    }

    public function test_dine_in_order_rejects_when_requested_party_size_exceeds_slot_capacity(): void
    {
        [$cook, $foodie, $kitchen] = $this->createKitchenFixture(['no_of_seats' => 4, 'dine_in' => 1, 'take_away' => 0]);

        $food = Foods::query()->create([
            'restaurant_id' => $kitchen->id,
            'food_name' => 'Table Service Meal',
            'pictures' => '[]',
            'price' => 30.00,
            'cookingstyle' => 1,
            'specialDiet' => '[]',
            'description' => 'Dine in only',
            'status' => 1,
            'dine_in' => 1,
            'take_away' => 0,
        ]);

        $slot = DineInSlot::query()->create([
            'mikitchn_id' => $kitchen->id,
            'day_of_week' => now()->addDay()->dayOfWeek,
            'start_time' => '18:00:00',
            'end_time' => '19:30:00',
            'seat_capacity' => 4,
            'status' => 1,
        ]);

        $this->actingAs($foodie, 'api')
            ->postJson('/api/v2/orders', [
                'kitchen_id' => $kitchen->id,
                'delivery_date' => now()->addDay()->format('Y-m-d'),
                'taxes' => '0.00',
                'dine_in' => 1,
                'take_away' => 0,
                'persons' => 5,
                'dine_in_slot_id' => $slot->id,
                'item_data' => json_encode([
                    ['id' => $food->id, 'quantity' => 1],
                ]),
            ])
            ->assertStatus(422)
            ->assertJsonPath('isError', 'Requested party size exceeds the kitchen dine-in seat capacity.');
    }

    public function test_syncing_slots_preserves_booked_slot_records_for_existing_orders(): void
    {
        [$cook, $foodie, $kitchen] = $this->createKitchenFixture(['no_of_seats' => 4, 'dine_in' => 1, 'take_away' => 0]);

        $originalSlot = DineInSlot::query()->create([
            'mikitchn_id' => $kitchen->id,
            'day_of_week' => now()->addDay()->dayOfWeek,
            'start_time' => '18:00:00',
            'end_time' => '19:00:00',
            'seat_capacity' => 4,
            'status' => 1,
        ]);

        DB::table('orders')->insert([
            'mikitchn_id' => $kitchen->id,
            'user_id' => $foodie->id,
            'dine_in' => 1,
            'take_away' => 0,
            'persons' => 2,
            'dine_in_slot_id' => $originalSlot->id,
            'delivery_date' => now()->addDay()->format('Y-m-d'),
            'delivery_time_from' => '18:00:00',
            'delivery_time_to' => '19:00:00',
            'item_total_price' => 10,
            'taxes' => 0,
            'total_price' => 10,
            'status' => 2,
            'paid' => 0,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        app(DineInSlotService::class)->syncKitchenSlots($kitchen, [[
            'day_of_week' => now()->addDay()->dayOfWeek,
            'start_time' => '19:00',
            'end_time' => '20:00',
            'seat_capacity' => 4,
            'status' => 1,
        ]]);

        $this->assertDatabaseHas('dine_in_slots', [
            'id' => $originalSlot->id,
            'status' => 0,
        ]);
        $this->assertDatabaseHas('orders', [
            'dine_in_slot_id' => $originalSlot->id,
        ]);
    }

    public function test_kitchen_update_clears_existing_dine_in_slots_when_dine_in_is_disabled(): void
    {
        Storage::fake('my_files');
        [$cook, $foodie, $kitchen] = $this->createKitchenFixture(['dine_in' => 1, 'take_away' => 1]);

        DineInSlot::query()->create([
            'mikitchn_id' => $kitchen->id,
            'day_of_week' => 1,
            'start_time' => '18:00:00',
            'end_time' => '19:00:00',
            'seat_capacity' => 4,
            'status' => 1,
        ]);

        $this->actingAs($cook, 'api')
            ->post('/api/v2/mikitchn/editkitchen', [
                'name' => $kitchen->name,
                'address' => $kitchen->address,
                'no_of_seats' => $kitchen->no_of_seats,
                'timings' => $this->defaultKitchenTimingsJson(),
                'phone' => $kitchen->phone,
                'dine_in' => 0,
                'take_away' => 1,
            ])
            ->assertOk();

        $this->assertDatabaseMissing('dine_in_slots', [
            'mikitchn_id' => $kitchen->id,
        ]);
    }

    public function test_kitchen_update_rejects_overlapping_dine_in_slots(): void
    {
        Storage::fake('my_files');
        [$cook, $foodie, $kitchen] = $this->createKitchenFixture(['dine_in' => 1, 'take_away' => 1]);

        $this->actingAs($cook, 'api')
            ->post('/api/v2/mikitchn/editkitchen', [
                'name' => $kitchen->name,
                'address' => $kitchen->address,
                'no_of_seats' => $kitchen->no_of_seats,
                'timings' => $this->defaultKitchenTimingsJson(),
                'phone' => $kitchen->phone,
                'dine_in' => 1,
                'take_away' => 1,
                'dine_in_slots' => json_encode([
                    [
                        'day_of_week' => 1,
                        'start_time' => '18:00',
                        'end_time' => '19:00',
                        'seat_capacity' => 4,
                        'status' => 1,
                    ],
                    [
                        'day_of_week' => 1,
                        'start_time' => '18:30',
                        'end_time' => '19:30',
                        'seat_capacity' => 4,
                        'status' => 1,
                    ],
                ]),
            ])
            ->assertStatus(422)
            ->assertJsonPath('isError', 'Dine-in slots for the same day cannot overlap.');
    }

    /**
     * @param array<string, mixed> $kitchenOverrides
     * @return array{0: User, 1: User, 2: Mikitchn}
     */
    private function createKitchenFixture(array $kitchenOverrides = []): array
    {
        DB::table('roles')->updateOrInsert(['id' => 2], [
            'role' => 'Restaurant',
            'created_at' => now(),
            'updated_at' => now(),
        ]);
        DB::table('roles')->updateOrInsert(['id' => 3], [
            'role' => 'Foodie',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $cook = User::query()->create([
            'first_name' => 'Cook',
            'last_name' => 'ReqSeven',
            'email' => 'cook-req7-' . uniqid() . '@example.test',
            'password' => Hash::make('password123'),
            'role_id' => 2,
            'phone' => '1111111111',
            'address' => 'Cook Street',
            'email_verified' => 1,
        ]);

        $foodie = User::query()->create([
            'first_name' => 'Foodie',
            'last_name' => 'ReqSeven',
            'email' => 'foodie-req7-' . uniqid() . '@example.test',
            'password' => Hash::make('password123'),
            'role_id' => 3,
            'phone' => '2222222222',
            'address' => 'Foodie Street',
            'email_verified' => 1,
        ]);

        DB::table('user_roles')->insert([
            [
                'user_id' => $cook->id,
                'role_id' => 2,
                'status' => UserRole::STATUS_ACTIVE,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'user_id' => $foodie->id,
                'role_id' => 3,
                'status' => UserRole::STATUS_ACTIVE,
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);

        $kitchen = Mikitchn::query()->create(array_merge([
            'user_id' => $cook->id,
            'name' => 'Requirement Seven Kitchen',
            'address' => 'Kitchen Street',
            'phone' => '1234567890',
            'no_of_seats' => 10,
            'timings' => '{}',
            'status' => 1,
            'dine_in' => 1,
            'take_away' => 1,
        ], $kitchenOverrides));

        return [$cook, $foodie, $kitchen];
    }

    private function defaultKitchenTimingsJson(): string
    {
        return json_encode([
            'days' => [
                [
                    'day' => 'Mon',
                    'isOn' => 1,
                    'timing' => [
                        'start_time' => '09:00',
                        'end_time' => '22:00',
                    ],
                ],
                [
                    'day' => 'Tue',
                    'isOn' => 1,
                    'timing' => [
                        'start_time' => '09:00',
                        'end_time' => '22:00',
                    ],
                ],
            ],
        ]);
    }
}
