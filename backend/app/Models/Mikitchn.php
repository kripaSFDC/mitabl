<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Overtrue\LaravelFavorite\Traits\Favoriteable;
use Auth;

class Mikitchn extends Model
{
    use HasFactory,Favoriteable;

    protected $fillable = [
        'user_id','name', 'address', 'no_of_seats', 'timings', 'phone','images','dine_in','take_away','description','latitude','longitude'
    ];
// ,'is_favourited'
    protected $appends = ['is_available','certificate_no','abn','rating_count','images'];

    /**
     * Get the reviews of the product.
     */
    public function reviews()
    {
        return $this->hasMany('App\Models\Review')->where('by_user','customer');
    }

    public function getIsAvailableAttribute()
    {
        $oCount = $this->orders()->where('delivery_date', '>=', date('Y-m-d'))->where('status',3)->count();
        if ($oCount > 0) {
            return false;
        }
        return true;
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
        return Auth::guard('api')->user()->hasFavorited($this);
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

    public function weektimings(){
        return $this->hasMany('App\Models\Timing');
    }

    public function delete() {
        $this->weektimings()->delete();
        $this->reviews()->delete();
        $this->certificate()->delete();
        $this->addedimage()->delete();
        $this->foods()->delete();
        $this->orders()->delete();
        parent::delete();
    }

}
