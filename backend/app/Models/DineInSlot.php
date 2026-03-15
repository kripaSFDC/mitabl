<?php

namespace App\Models;

use Carbon\CarbonInterface;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class DineInSlot extends Model
{
    use HasFactory;

    public const DAY_NAMES = [
        0 => 'Sunday',
        1 => 'Monday',
        2 => 'Tuesday',
        3 => 'Wednesday',
        4 => 'Thursday',
        5 => 'Friday',
        6 => 'Saturday',
    ];

    protected $fillable = [
        'mikitchn_id',
        'day_of_week',
        'start_time',
        'end_time',
        'seat_capacity',
        'status',
    ];

    protected $casts = [
        'day_of_week' => 'integer',
        'seat_capacity' => 'integer',
        'status' => 'integer',
    ];

    public function kitchen()
    {
        return $this->belongsTo(Mikitchn::class, 'mikitchn_id');
    }

    public function orders()
    {
        return $this->hasMany(Order::class, 'dine_in_slot_id');
    }

    public function getDayNameAttribute(): ?string
    {
        return self::DAY_NAMES[(int) $this->day_of_week] ?? null;
    }

    public function isAvailableOnDate(CarbonInterface $date): bool
    {
        return (int) $this->status === 1 && (int) $this->day_of_week === $date->dayOfWeek;
    }
}
