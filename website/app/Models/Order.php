<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Order extends Model
{
    use HasFactory;

    protected $appends = ['items'];

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

    public function user()
    {
        return $this->belongsTo('App\Models\User');
    }
}
