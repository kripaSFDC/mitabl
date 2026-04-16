<?php

namespace App\Services;

use App\Models\DineInSlot;
use App\Models\Mikitchn;
use App\Models\Order;
use Carbon\Carbon;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Schema;
use InvalidArgumentException;

class DineInSlotService
{
    private const ACTIVE_BOOKING_STATUSES = [
        Order::STATUS_REQUESTED,
        Order::STATUS_CONFIRMED,
        Order::STATUS_IN_PROGRESS,
        Order::STATUS_READY,
    ];

    public function syncKitchenSlots(Mikitchn $kitchen, array $slots): void
    {
        if (! Schema::hasTable('dine_in_slots')) {
            throw new InvalidArgumentException('Dine-in slots are not available until the dine_in_slots table has been migrated.');
        }

        $existingSlots = $kitchen->dineInSlots()->get()->keyBy(
            fn (DineInSlot $slot): string => $this->slotFingerprint(
                (int) $slot->day_of_week,
                (string) $slot->start_time,
                (string) $slot->end_time
            )
        );
        $retainedSlotIds = [];

        foreach ($slots as $slot) {
            $dayOfWeek = (int) $slot['day_of_week'];
            $startTime = Carbon::parse((string) $slot['start_time'])->format('H:i:s');
            $endTime = Carbon::parse((string) $slot['end_time'])->format('H:i:s');
            $fingerprint = $this->slotFingerprint($dayOfWeek, $startTime, $endTime);
            $slotModel = $existingSlots->get($fingerprint) ?? new DineInSlot([
                'mikitchn_id' => $kitchen->id,
                'day_of_week' => $dayOfWeek,
                'start_time' => $startTime,
                'end_time' => $endTime,
            ]);

            $slotModel->mikitchn_id = $kitchen->id;
            $slotModel->day_of_week = $dayOfWeek;
            $slotModel->start_time = $startTime;
            $slotModel->end_time = $endTime;
            $slotModel->seat_capacity = array_key_exists('seat_capacity', $slot) && $slot['seat_capacity'] !== null
                ? (int) $slot['seat_capacity']
                : null;
            $slotModel->status = (int) ($slot['status'] ?? 1);
            $slotModel->save();

            $retainedSlotIds[] = (int) $slotModel->id;
        }

        $this->retireOrDeleteSlots(
            $kitchen->dineInSlots()
                ->whereNotIn('id', $retainedSlotIds)
                ->get()
        );
    }

    public function clearKitchenSlots(Mikitchn $kitchen): void
    {
        if (! Schema::hasTable('dine_in_slots')) {
            return;
        }

        $this->retireOrDeleteSlots($kitchen->dineInSlots()->get());
    }

    private function slotFingerprint(int $dayOfWeek, string $startTime, string $endTime): string
    {
        return implode('|', [$dayOfWeek, $startTime, $endTime]);
    }

    private function retireOrDeleteSlots(Collection $slots): void
    {
        $slots->each(function (DineInSlot $slot): void {
            if ($slot->orders()->exists()) {
                $slot->status = 0;
                $slot->save();
                return;
            }

            $slot->delete();
        });
    }

    public function getAvailabilityForDate(Mikitchn $kitchen, Carbon $date, ?int $persons = null): Collection
    {
        if (! Schema::hasTable('dine_in_slots')) {
            return collect();
        }

        $slots = $kitchen->dineInSlots()
            ->where('day_of_week', $date->dayOfWeek)
            ->where('status', 1)
            ->orderBy('start_time')
            ->get();

        return $slots->map(function (DineInSlot $slot) use ($kitchen, $date, $persons): DineInSlot {
            $bookedSeats = $this->bookedSeatsForSlot($kitchen, $slot, $date);
            $capacity = $this->effectiveCapacity($kitchen, $slot);
            $remainingSeats = max($capacity - $bookedSeats, 0);

            $slot->setAttribute('delivery_date', $date->toDateString());
            $slot->setAttribute('booked_seats', $bookedSeats);
            $slot->setAttribute('remaining_seats', $remainingSeats);

            if ($persons !== null && $persons > 0 && $remainingSeats < $persons) {
                $slot->setAttribute('status', 0);
            }

            return $slot;
        })->values();
    }

    public function assertBookable(Mikitchn $kitchen, int $slotId, string $deliveryDate, int $persons, ?int $ignoreOrderId = null): DineInSlot
    {
        if (! Schema::hasTable('dine_in_slots')) {
            throw new InvalidArgumentException('Dine-in slots are not available until the dine_in_slots table has been migrated.');
        }

        $date = Carbon::parse($deliveryDate)->startOfDay();

        if ($persons <= 0) {
            throw new InvalidArgumentException('persons is required for dine-in orders.');
        }

        if ((int) $kitchen->no_of_seats > 0 && $persons > (int) $kitchen->no_of_seats) {
            throw new InvalidArgumentException('Requested party size exceeds the kitchen dine-in seat capacity.');
        }

        $slot = DineInSlot::query()
            ->where('mikitchn_id', $kitchen->id)
            ->whereKey($slotId)
            ->lockForUpdate()
            ->first();

        if (! $slot || ! $slot->isAvailableOnDate($date)) {
            throw new InvalidArgumentException('Selected dine-in slot is not available for the chosen date.');
        }

        $capacity = $this->effectiveCapacity($kitchen, $slot);
        $bookedSeats = $this->bookedSeatsForSlot($kitchen, $slot, $date, $ignoreOrderId);

        if (($bookedSeats + $persons) > $capacity) {
            throw new InvalidArgumentException('Selected dine-in slot does not have enough remaining seats.');
        }

        return $slot;
    }

    public function effectiveCapacity(Mikitchn $kitchen, DineInSlot $slot): int
    {
        $kitchenSeats = max((int) $kitchen->no_of_seats, 0);
        $slotCapacity = $slot->seat_capacity !== null ? max((int) $slot->seat_capacity, 0) : $kitchenSeats;

        return $kitchenSeats > 0 ? min($kitchenSeats, $slotCapacity) : $slotCapacity;
    }

    private function bookedSeatsForSlot(Mikitchn $kitchen, DineInSlot $slot, Carbon $date, ?int $ignoreOrderId = null): int
    {
        $query = Order::query()
            ->where('mikitchn_id', $kitchen->id)
            ->where('dine_in', 1)
            ->whereDate('delivery_date', $date->toDateString())
            ->whereIn('status', self::ACTIVE_BOOKING_STATUSES)
            ->where(function ($overlapQuery) use ($slot): void {
                $overlapQuery->where('dine_in_slot_id', $slot->id)
                    ->orWhere(function ($legacyQuery) use ($slot): void {
                        $legacyQuery->whereNull('dine_in_slot_id')
                            ->where('delivery_time_from', '<', $slot->end_time)
                            ->where('delivery_time_to', '>', $slot->start_time);
                    });
            });

        if ($ignoreOrderId !== null) {
            $query->where('id', '!=', $ignoreOrderId);
        }

        return (int) $query->sum('persons');
    }

    public function createSlot(Mikitchn $kitchen, array $data): DineInSlot
    {
        if (! Schema::hasTable('dine_in_slots')) {
            throw new InvalidArgumentException('Dine-in slots are not available until the dine_in_slots table has been migrated.');
        }

        $startTime = Carbon::parse((string) $data['start_time'])->format('H:i:s');
        $endTime = Carbon::parse((string) $data['end_time'])->format('H:i:s');
        $dayOfWeek = (int) $data['day_of_week'];

        $this->validateNoOverlap($kitchen->id, $dayOfWeek, $startTime, $endTime);

        return DineInSlot::create([
            'mikitchn_id' => $kitchen->id,
            'day_of_week' => $dayOfWeek,
            'start_time' => $startTime,
            'end_time' => $endTime,
            'seat_capacity' => isset($data['seat_capacity']) ? (int) $data['seat_capacity'] : null,
            'status' => (int) ($data['status'] ?? 1),
        ]);
    }

    public function updateSlot(DineInSlot $slot, array $data): DineInSlot
    {
        $startTime = isset($data['start_time'])
            ? Carbon::parse((string) $data['start_time'])->format('H:i:s')
            : (string) $slot->start_time;
        $endTime = isset($data['end_time'])
            ? Carbon::parse((string) $data['end_time'])->format('H:i:s')
            : (string) $slot->end_time;
        $dayOfWeek = isset($data['day_of_week']) ? (int) $data['day_of_week'] : (int) $slot->day_of_week;

        $timeWindowChanged = $startTime !== (string) $slot->start_time
            || $endTime !== (string) $slot->end_time
            || $dayOfWeek !== (int) $slot->day_of_week;

        if ($timeWindowChanged && $slot->hasActiveBookings()) {
            throw new InvalidArgumentException('Cannot change time window while active bookings exist. Disable this slot and create a new one.');
        }

        if ($timeWindowChanged) {
            $this->validateNoOverlap((int) $slot->mikitchn_id, $dayOfWeek, $startTime, $endTime, (int) $slot->id);
        }

        $slot->fill(array_filter([
            'day_of_week' => $dayOfWeek,
            'start_time' => $startTime,
            'end_time' => $endTime,
            'seat_capacity' => isset($data['seat_capacity']) ? (int) $data['seat_capacity'] : $slot->seat_capacity,
            'status' => isset($data['status']) ? (int) $data['status'] : $slot->status,
        ], fn ($v) => $v !== null));

        $slot->save();
        return $slot->fresh();
    }

    public function deleteSlot(DineInSlot $slot): bool
    {
        if ($slot->hasActiveBookings()) {
            $slot->status = 0;
            $slot->save();
            return false; // soft-disabled
        }

        $slot->delete();
        return true; // hard-deleted
    }

    private function validateNoOverlap(int $kitchenId, int $dayOfWeek, string $startTime, string $endTime, ?int $excludeSlotId = null): void
    {
        $query = DineInSlot::query()
            ->where('mikitchn_id', $kitchenId)
            ->where('day_of_week', $dayOfWeek)
            ->where('status', 1)
            ->where('start_time', '<', $endTime)
            ->where('end_time', '>', $startTime);

        if ($excludeSlotId !== null) {
            $query->where('id', '!=', $excludeSlotId);
        }

        if ($query->exists()) {
            throw new InvalidArgumentException('This slot overlaps with an existing slot on the same day.');
        }
    }
}
