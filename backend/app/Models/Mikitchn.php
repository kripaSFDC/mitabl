<?php

namespace App\Models;

use App\Models\WatchSubscription;
use App\Models\Tag;
use App\Models\InternalNote;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\DB;
use Overtrue\LaravelFavorite\Traits\Favoriteable;
use Auth;

class Mikitchn extends Model
{
    use HasFactory,Favoriteable;

    protected $fillable = [
        'user_id','name', 'address', 'no_of_seats', 'timings', 'phone','images','dine_in','take_away','description','latitude','longitude'
    ];
// ,'is_favourited'
    protected $casts = [
        'latitude' => 'float',
        'longitude' => 'float',
    ];

    /**
     * Get the reviews of the product.
     */
    public function reviews()
    {
        return $this->hasMany('App\Models\Review')->where('by_user','customer');
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

        return ! $this->orders()
            ->whereDate('delivery_date', '>=', today()->toDateString())
            ->where('status', 3)
            ->exists();
    }

    public function certificate(){
        return $this->hasOne('App\Models\Certificate');
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
        return $this->hasMany('App\Models\Image','ref_id')->where('model_name','mikitchns');
    }

    public function getImagesAttribute()
    {
        return $this->addedimage;
    }

    public function getRatingCountAttribute()
    {
        return $this->reviews->avg('rating');
    }

    public function foods()
    {
        return $this->hasMany('App\Models\Foods','restaurant_id');
    }

    /**
     * Get the user that added the product.
     */
    public function user()
    {
        return $this->belongsTo('App\Models\User');
    }

    // public function hasUserFavourited()
    // {
    //     return Auth::guard('api')->user()->hasFavorited($this);
    // }
    public function getIsFavouritedAttribute(){
        if (array_key_exists('is_favourited', $this->attributes)) {
            return (bool) $this->attributes['is_favourited'];
        }

        if (! Auth::guard('api')->check()) {
            return false;
        }

        return Auth::guard('api')->user()->hasFavorited($this);
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
        // return (new static)::selectraw($distance_select)
            // ->having( 'distance', '<', $max_distance );
            // ->take( $max_locations )
            // ->orderBy( 'distance', 'ASC' );
            // ->get();
    }

    public static function haversine($lat, $lng)
    {
        if (! is_numeric($lat) || ! is_numeric($lng)) {
            throw new \InvalidArgumentException('Latitude and longitude must be numeric.');
        }

        return sprintf(
            '(6371 * acos(cos(radians(%F)) * cos(radians(`latitude`)) * cos(radians(`longitude`) - radians(%F)) + sin(radians(%F)) * sin(radians(`latitude`)))) AS distance',
            (float) $lat,
            (float) $lng,
            (float) $lat
        );
    }

    public function orders(){
        return $this->hasMany('App\Models\Order');
    }

    public function weektimings(){
        return $this->hasMany('App\Models\Timing');
    }

    public function delete() {
        return DB::transaction(function () {
            $this->weektimings()->delete();
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
