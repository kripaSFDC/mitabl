<?php

namespace Tests\Unit;

use App\Models\DineInSlot;
use App\Models\Mikitchn;
use App\Models\Order;
use App\Models\User;
use App\Services\DineInSlotService;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use InvalidArgumentException;
use Tests\TestCase;

class DineInSlotServiceTest extends TestCase
{
    use RefreshDatabase;

    public function test_sync_kitchen_slots_updates_existing_creates_new_and_handles_removed_slots(): void
    {
        $kitchen = $this->createKitchen(['no_of_seats' => 8]);
        $service = app(DineInSlotService::class);

        $keptWithOrder = DineInSlot::query()->create([
            'mikitchn_id' => $kitchen->id,
            'day_of_week' => 2,
            'start_time' => '18:00:00',
            'end_time' => '19:00:00',
            'seat_capacity' => 4,
            'status' => 1,
        ]);

        DineInSlot::query()->create([
            'mikitchn_id' => $kitchen->id,
            'day_of_week' => 3,
            'start_time' => '18:00:00',
            'end_time' => '19:00:00',
            'seat_capacity' => 4,
            'status' => 1,
        ]);

        Order::query()->create($this->orderPayload($kitchen->id, [
            'dine_in_slot_id' => $keptWithOrder->id,
            'delivery_date' => Carbon::now()->next('Tuesday')->toDateString(),
        ]));

        $service->syncKitchenSlots($kitchen, [
            [
                'day_of_week' => 2,
                'start_time' => '18:00',
                'end_time' => '19:00',
                'seat_capacity' => 6,
                'status' => 1,
            ],
            [
                'day_of_week' => 4,
                'start_time' => '17:00',
                'end_time' => '18:00',
                'seat_capacity' => 5,
                'status' => 1,
            ],
        ]);

        $this->assertDatabaseHas('dine_in_slots', [
            'id' => $keptWithOrder->id,
            'seat_capacity' => 6,
            'status' => 1,
        ]);
        $this->assertDatabaseHas('dine_in_slots', [
            'mikitchn_id' => $kitchen->id,
            'day_of_week' => 4,
            'start_time' => '17:00:00',
            'end_time' => '18:00:00',
        ]);
        $this->assertDatabaseMissing('dine_in_slots', [
            'mikitchn_id' => $kitchen->id,
            'day_of_week' => 3,
            'start_time' => '18:00:00',
            'end_time' => '19:00:00',
        ]);
    }

    public function test_clear_kitchen_slots_marks_booked_slots_inactive_and_deletes_unbooked_slots(): void
    {
        $kitchen = $this->createKitchen(['no_of_seats' => 8]);
        $service = app(DineInSlotService::class);

        $bookedSlot = DineInSlot::query()->create([
            'mikitchn_id' => $kitchen->id,
            'day_of_week' => 5,
            'start_time' => '19:00:00',
            'end_time' => '20:00:00',
            'seat_capacity' => 6,
            'status' => 1,
        ]);
        $unbookedSlot = DineInSlot::query()->create([
            'mikitchn_id' => $kitchen->id,
            'day_of_week' => 6,
            'start_time' => '12:00:00',
            'end_time' => '13:00:00',
            'seat_capacity' => 6,
            'status' => 1,
        ]);

        Order::query()->create($this->orderPayload($kitchen->id, [
            'dine_in_slot_id' => $bookedSlot->id,
            'delivery_date' => Carbon::now()->next('Friday')->toDateString(),
        ]));

        $service->clearKitchenSlots($kitchen);

        $this->assertDatabaseHas('dine_in_slots', ['id' => $bookedSlot->id, 'status' => 0]);
        $this->assertDatabaseMissing('dine_in_slots', ['id' => $unbookedSlot->id]);
    }

    public function test_get_availability_for_date_marks_slot_unavailable_when_person_count_exceeds_remaining(): void
    {
        $kitchen = $this->createKitchen(['no_of_seats' => 5]);
        $service = app(DineInSlotService::class);

        $date = Carbon::now()->next('Monday');
        $slot = DineInSlot::query()->create([
            'mikitchn_id' => $kitchen->id,
            'day_of_week' => $date->dayOfWeek,
            'start_time' => '18:00:00',
            'end_time' => '19:00:00',
            'seat_capacity' => 4,
            'status' => 1,
        ]);

        Order::query()->create($this->orderPayload($kitchen->id, [
            'dine_in_slot_id' => $slot->id,
            'persons' => 3,
            'delivery_date' => $date->toDateString(),
            'status' => Order::STATUS_CONFIRMED,
        ]));

        $availability = $service->getAvailabilityForDate($kitchen, $date, 2);

        $this->assertCount(1, $availability);
        $this->assertSame(3, $availability[0]->booked_seats);
        $this->assertSame(1, $availability[0]->remaining_seats);
        $this->assertSame(0, $availability[0]->status);
    }

    public function test_assert_bookable_validates_persons_capacity_and_slot_existence(): void
    {
        $kitchen = $this->createKitchen(['no_of_seats' => 4]);
        $service = app(DineInSlotService::class);
        $date = Carbon::now()->next('Thursday');

        $slot = DineInSlot::query()->create([
            'mikitchn_id' => $kitchen->id,
            'day_of_week' => $date->dayOfWeek,
            'start_time' => '18:00:00',
            'end_time' => '19:00:00',
            'seat_capacity' => 4,
            'status' => 1,
        ]);

        $this->expectException(InvalidArgumentException::class);
        $this->expectExceptionMessage('persons is required for dine-in orders.');
        $service->assertBookable($kitchen, $slot->id, $date->toDateString(), 0);
    }

    public function test_assert_bookable_rejects_when_slot_is_full(): void
    {
        $kitchen = $this->createKitchen(['no_of_seats' => 4]);
        $service = app(DineInSlotService::class);
        $date = Carbon::now()->next('Sunday');

        $slot = DineInSlot::query()->create([
            'mikitchn_id' => $kitchen->id,
            'day_of_week' => $date->dayOfWeek,
            'start_time' => '18:00:00',
            'end_time' => '19:00:00',
            'seat_capacity' => 4,
            'status' => 1,
        ]);

        Order::query()->create($this->orderPayload($kitchen->id, [
            'dine_in_slot_id' => $slot->id,
            'persons' => 4,
            'delivery_date' => $date->toDateString(),
        ]));

        $this->expectException(InvalidArgumentException::class);
        $this->expectExceptionMessage('Selected dine-in slot does not have enough remaining seats.');

        $service->assertBookable($kitchen, $slot->id, $date->toDateString(), 1);
    }

    public function test_effective_capacity_uses_minimum_of_kitchen_and_slot_capacity(): void
    {
        $kitchen = $this->createKitchen(['no_of_seats' => 4]);
        $slot = new DineInSlot(['seat_capacity' => 6]);

        $service = app(DineInSlotService::class);

        $this->assertSame(4, $service->effectiveCapacity($kitchen, $slot));
        $this->assertSame(6, $service->effectiveCapacity($kitchen->forceFill(['no_of_seats' => 0]), $slot));
    }

    private function createKitchen(array $overrides = []): Mikitchn
    {
        $user = User::factory()->create();

        return Mikitchn::query()->create(array_merge([
            'user_id' => $user->id,
            'name' => 'Kitchen ' . uniqid(),
            'address' => '123 Test Street',
            'phone' => '0400000000',
            'no_of_seats' => 0,
            'status' => 1,
            'timings' => json_encode(['mon' => '1']),
        ], $overrides));
    }

    private function orderPayload(int $kitchenId, array $overrides = []): array
    {
        return array_merge([
            'mikitchn_id' => $kitchenId,
            'user_id' => User::factory()->create()->id,
            'dine_in' => 1,
            'take_away' => 0,
            'persons' => 2,
            'dine_in_slot_id' => null,
            'delivery_date' => Carbon::now()->toDateString(),
            'delivery_time_from' => '18:00:00',
            'delivery_time_to' => '19:00:00',
            'item_total_price' => 25,
            'taxes' => 0,
            'total_price' => 25,
            'status' => Order::STATUS_REQUESTED,
            'paid' => 0,
        ], $overrides);
    }
}
