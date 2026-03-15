<?php

namespace App\Http\Resources\Restaurant;

use Illuminate\Http\Resources\Json\JsonResource;

class DineInSlot extends JsonResource
{
    public function toArray($request)
    {
        $seatCapacity = $this->seat_capacity !== null ? (int) $this->seat_capacity : null;
        $remainingSeats = array_key_exists('remaining_seats', $this->resource->getAttributes())
            ? (int) $this->resource->getAttribute('remaining_seats')
            : null;
        $bookedSeats = array_key_exists('booked_seats', $this->resource->getAttributes())
            ? (int) $this->resource->getAttribute('booked_seats')
            : null;
        $isAvailable = $remainingSeats !== null
            ? $remainingSeats > 0 && (int) $this->status === 1
            : (int) $this->status === 1;

        return [
            'id' => $this->id,
            'day_of_week' => (int) $this->day_of_week,
            'day_name' => $this->day_name,
            'delivery_date' => $this->when(isset($this->delivery_date), $this->delivery_date),
            'start_time' => substr((string) $this->start_time, 0, 5),
            'end_time' => substr((string) $this->end_time, 0, 5),
            'seat_capacity' => $seatCapacity,
            'booked_seats' => $bookedSeats,
            'remaining_seats' => $remainingSeats,
            'status' => (int) $this->status,
            'is_available' => $isAvailable,
        ];
    }
}
