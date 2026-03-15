<?php

namespace App\Models;

use Carbon\Carbon;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Foods extends Model
{
    use HasFactory;

    protected $fillable = [
        'restaurant_id',
        'food_name',
        'cookingstyle',
        'specialDiet',
        'price',
        'description',
        'pictures',
        'status',
        'dine_in',
        'take_away',
        'available_date',
        'available_days',
        'available_from_time',
        'available_to_time',
    ];

    protected $casts = [
        'price' => 'decimal:2',
        'status' => 'integer',
        'dine_in' => 'integer',
        'take_away' => 'integer',
        'available_date' => 'date:Y-m-d',
        'available_days' => 'array',
    ];

    public function addedimage()
    {
        return $this->hasMany(Image::class, 'ref_id')->where('model_name', 'food');
    }

    public function getAddedImagesAttribute()
    {
        return $this->addedimage;
    }

    public function scopeActive($query)
    {
        return $query->where('status', 1);
    }

    public function scopeForRestaurant($query, int $restaurantId)
    {
        return $query->where('restaurant_id', $restaurantId);
    }

    public function scopeSearchTerm($query, ?string $term)
    {
        $term = trim((string) $term);
        if ($term === '') {
            return $query;
        }

        return $query->where(function ($subQuery) use ($term): void {
            $subQuery->where('food_name', 'like', '%' . $term . '%')
                ->orWhere('description', 'like', '%' . $term . '%');
        });
    }

    public function scopeAvailableForOrderType($query, ?int $dineIn, ?int $takeAway)
    {
        if ($dineIn !== null) {
            $query->where('dine_in', $dineIn);
        }

        if ($takeAway !== null) {
            $query->where('take_away', $takeAway);
        }

        return $query;
    }

    public function isScheduledFor(Carbon $deliveryDate, ?string $deliveryTimeFrom = null, ?string $deliveryTimeTo = null): bool
    {
        $availableDate = $this->available_date;
        if ($availableDate && $availableDate->toDateString() !== $deliveryDate->toDateString()) {
            return false;
        }

        $availableDays = collect($this->available_days ?? [])
            ->map(fn ($value): int => (int) $value)
            ->all();

        if ($availableDays !== [] && ! in_array($deliveryDate->dayOfWeek, $availableDays, true)) {
            return false;
        }

        $availableFrom = $this->normalizeTime($this->available_from_time);
        $availableTo = $this->normalizeTime($this->available_to_time);

        if ($availableFrom === null || $availableTo === null) {
            return true;
        }

        $requestedFrom = $this->normalizeTime($deliveryTimeFrom);
        $requestedTo = $this->normalizeTime($deliveryTimeTo);

        if ($requestedFrom === null && $requestedTo === null) {
            return true;
        }

        if ($requestedFrom === null || $requestedTo === null) {
            return false;
        }

        return $requestedFrom >= $availableFrom && $requestedTo <= $availableTo;
    }

    private function normalizeTime(mixed $value): ?string
    {
        $normalized = trim((string) $value);
        if ($normalized === '') {
            return null;
        }

        return Carbon::parse($normalized)->format('H:i:s');
    }
}
