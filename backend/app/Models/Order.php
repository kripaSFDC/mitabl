<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Notifications\Notifiable;
use App\Models\Review;

class Order extends Model
{
    use HasFactory, Notifiable;

    protected $appends = ['items','orderId'];

    /**
     * The attributes that should be mutated to dates.
     *
     * @var array
     */
    protected $dates = ['delivery_time_from','delivery_time_to','delivery_date'];

    /**
     * Get the reviews of the product.
     */
    public function orderdata()
    {
        return $this->hasMany('App\Models\OrderData');
    }

    public function Mikitchn()
    {
        return $this->belongsTo('App\Models\Mikitchn');
    }

    public function getItemsAttribute()
    {
        return $this->orderdata;
    }

    public function getOrderIdAttribute()
    {
        $orderPrefix = 'T';
        if ($this->dine_in) {
            $orderPrefix = 'D';
        }
        return $orderPrefix.'-'.$this->id;
    }

    public function user()
    {
        return $this->belongsTo('App\Models\User');
    }

    public function promocode()
    {
        return $this->belongsTo('App\Models\PromoCode','promo_code');
    }


    public function review()
    {
        return $this->hasOne('App\Models\Review');
    }

    public function payment()
    {
        return $this->hasOne('App\Models\Payment');
    }

    public function cancelreason()
    {
        return $this->hasOne('App\Models\CancelReason');
    }

    public function completedorder()
    {
        return $this->hasOne('App\Models\CompletedOrder');
    }

}
