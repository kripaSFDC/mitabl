<?php

namespace App\Services;

use App\Models\DineInSlot;
use App\Models\Mikitchn;
use App\Models\Order;
use Carbon\Carbon;
use Illuminate\Support\Collection;
use InvalidArgumentException;

class DineInSlotService
{
    private const ACTIVE_BOOKING_STATUSES = [
        Order::STATUS_REQUESTED,
        Order::STATUS_CONFIRMED,
        Order::STATUS_IN_PROGRESS,
    ];

    public function syncKitchenSlots(Mikitchn $kitchen, array $slots): void
    {
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

        $kitchen->dineInSlots()
            ->whereNotIn('id', $retainedSlotIds)
            ->get()
            ->each(function (DineInSlot $slot): void {
                if ($slot->orders()->exists()) {
                    $slot->status = 0;
                    $slot->save();
                    return;
                }

                $slot->delete();
            });
    }

    private function slotFingerprint(int $dayOfWeek, string $startTime, string $endTime): string
    {
        return implode('|', [$dayOfWeek, $startTime, $endTime]);
    }

    public function getAvailabilityForDate(Mikitchn $kitchen, Carbon $date, ?int $persons = null): Collection
    {
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
}
