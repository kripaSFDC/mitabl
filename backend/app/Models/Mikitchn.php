<?php

namespace App\Models;

use App\Models\WatchSubscription;
use App\Models\Tag;
use App\Models\DineInSlot;
use App\Models\InternalNote;
use App\Models\Order;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Overtrue\LaravelFavorite\Traits\Favoriteable;
use Auth;

class Mikitchn extends Model
{
    use HasFactory,Favoriteable;

    protected $fillable = [
        'user_id',
        'name',
        'address',
        'no_of_seats',
        'timings',
        'phone',
        'images',
        'dine_in',
        'take_away',
        'description',
        'latitude',
        'longitude',
        'status',
        'open',
        'cancellation_window_hours',
        'no_show_penalty_pct',
        'advance_order_days',
    ];
    protected $casts = [
        'latitude' => 'float',
        'longitude' => 'float',
        'cancellation_window_hours' => 'integer',
        'no_show_penalty_pct' => 'integer',
        'advance_order_days' => 'integer',
    ];

    /**
     * Get the reviews of the product.
     */
    public function reviews()
    {
        return $this->hasMany(Review::class)->where('by_user', 'customer');
    }

    public function getIsAvailableAttribute()
    {
        if (array_key_exists('is_available', $this->attributes)) {
            return (bool) $this->attributes['is_available'];
        }

        if (array_key_exists('active_orders_count', $this->attributes)) {
            return ((int) $this->attributes['active_orders_count']) === 0;
        }

        if ($this->relationLoaded('orders')) {
            return ! $this->orders->contains(function ($order): bool {
                return (int) $order->status === 3 && $order->delivery_date >= today()->toDateString();
            });
        }

        static $busyKitchenLookup = null;
        if ($busyKitchenLookup === null) {
            $busyKitchenLookup = array_flip(
                Order::query()
                    ->whereDate('delivery_date', '>=', today()->toDateString())
                    ->where('status', 3)
                    ->distinct()
                    ->pluck('mikitchn_id')
                    ->map(fn ($id): int => (int) $id)
                    ->all()
            );
        }

        return ! isset($busyKitchenLookup[(int) $this->id]);
    }

    public function certificate(){
        return $this->hasOne(Certificate::class);
    }

    public function getCertificateNoAttribute()
    {
        if ($this->certificate) {
            return $this->certificate->certificate_no;
        }
        return null;
    }

    public function getAbnAttribute()
    {
        if ($this->certificate) {
            return $this->certificate->abn;
        }
        return null;
    }

    public function addedimage()
    {
        return $this->hasMany(Image::class, 'ref_id')->where('model_name', 'mikitchns');
    }

    public function getImagesAttribute()
    {
        return $this->addedimage;
    }

    public function getRatingCountAttribute()
    {
        if (array_key_exists('reviews_avg_rating', $this->attributes)) {
            return $this->attributes['reviews_avg_rating'];
        }

        return $this->reviews()->avg('rating');
    }

    public function foods()
    {
        return $this->hasMany(Foods::class, 'restaurant_id');
    }

    /**
     * Get the user that added the product.
     */
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function getIsFavouritedAttribute(){
        if (array_key_exists('is_favourited', $this->attributes)) {
            return (bool) $this->attributes['is_favourited'];
        }

        $guard = Auth::guard('api');
        if (! $guard->check()) {
            return false;
        }

        $userId = (int) $guard->id();
        static $favoriteLookupByUser = [];
        if (! array_key_exists($userId, $favoriteLookupByUser)) {
            $favoriteLookupByUser[$userId] = array_flip(
                $guard->user()
                    ->getFavoriteItems(self::class)
                    ->pluck('id')
                    ->map(fn ($id): int => (int) $id)
                    ->all()
            );
        }

        return isset($favoriteLookupByUser[$userId][(int) $this->id]);
    }
    
    public static function closest($lat, $lng, $units = 'kilometers')
    {
        if (! is_numeric($lat) || ! is_numeric($lng)) {
            throw new \InvalidArgumentException('Latitude and longitude must be numeric.');
        }
        $lat = (float) $lat;
        $lng = (float) $lng;
        /*
         *  Allow for changing of units of measurement
         */
        switch ( $units ) {
            default:
            case 'miles':
                $gr_circle_radius = 3959;
                break;
            case 'kilometers':
                $gr_circle_radius = 6371;
                break;
        }
        $distance_select = sprintf(
            " ( %d * acos( cos( radians(%F) ) " .
            " * cos( radians( latitude ) ) " .
            " * cos( radians( longitude ) - radians(%F) ) " .
            " + sin( radians(%F) ) * sin( radians( latitude ) ) " .
            ") " .
            ") " .
            "AS distance",
            $gr_circle_radius,
            $lat,
            $lng,
            $lat
        );
        return $distance_select;
    }

    public function orders(){
        return $this->hasMany(Order::class);
    }

    public function weektimings(){
        return $this->hasMany(Timing::class);
    }

    public function dineInSlots()
    {
        return $this->hasMany(DineInSlot::class, 'mikitchn_id');
    }

    public function delete() {
        return DB::transaction(function () {
            $this->weektimings()->delete();
            if (Schema::hasTable('dine_in_slots')) {
                $this->dineInSlots()->delete();
            }
            $this->reviews()->delete();
            $this->certificate()->delete();
            $this->addedimage()->delete();
            $this->foods()->delete();
            $this->orders()->delete();
            return parent::delete();
        });
    }


    public function internalNotes()
    {
        return $this->morphMany(InternalNote::class, 'noteable')->latest();
    }

    public function tags()
    {
        return $this->morphToMany(Tag::class, 'taggable');
    }

    public function watchers()
    {
        return $this->morphMany(WatchSubscription::class, 'watchable');
    }


}
