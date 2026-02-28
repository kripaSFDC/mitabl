<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Refund extends Model
{
    use HasFactory;

    protected $fillable = [
        'order_id',
        'user_id',
        'percentage',
        'amount',
        'balance_trans',
        'refund_date',
        'reciept_no',
        'status',
    ];

    protected $casts = [
        'refund_date' => 'datetime',
        'reciept_no' => 'datetime',
    ];
}
