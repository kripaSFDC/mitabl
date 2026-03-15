<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CompletedOrder extends Model
{
    use HasFactory;

    protected $fillable = [
        'order_id',
        'completed_date_time',
    ];

    public function Order()
    {
        return $this->belongsTo(Order::class);
    }
}
