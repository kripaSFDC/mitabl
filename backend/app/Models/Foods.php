<?php

namespace App\Models;

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
    ];

    protected $casts = [
        'price' => 'decimal:2',
        'status' => 'integer',
        'dine_in' => 'integer',
        'take_away' => 'integer',
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
}
