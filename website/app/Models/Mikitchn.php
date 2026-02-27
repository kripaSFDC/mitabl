<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Overtrue\LaravelFavorite\Traits\Favoriteable;

class Mikitchn extends Model
{
    use HasFactory,Favoriteable;

    protected $fillable = [
        'user_id','name', 'address', 'no_of_seats', 'timings', 'phone','images','dine_in','take_away'
    ];

    protected $appends = ['rating_count'];

    /**
     * Get the reviews of the product.
     */
    public function reviews()
    {
        return $this->hasMany('App\Models\Review');
    }

    public function getRatingCountAttribute()
    {
        return $this->reviews->avg('rating');
    }

    /**
     * Get the user that added the product.
     */
    public function user()
    {
        return $this->belongsTo('App\Models\User');
    }

    public static function closest($lat, $lng, $units = 'kilometers')
    {
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
            " ( %d * acos( cos( radians(%s) ) " .
            " * cos( radians( latitude ) ) " .
            " * cos( radians( longitude ) - radians(%s) ) " .
            " + sin( radians(%s) ) * sin( radians( latitude ) ) " .
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
        return '(6371 * acos(cos(radians(' . $lat . ')) 
        * cos(radians(`latitude`)) 
        * cos(radians(`longitude`) 
        - radians(' . $lng . ')) 
        + sin(radians(' . $lat . ')) 
        * sin(radians(`latitude`)))) AS distance';
    }

    public function orders(){
        return $this->hasMany('App\Models\Order');
    }

}
