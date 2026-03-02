<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class OrderData extends Model
{
    use HasFactory;

    protected $casts = [
        'price' => 'decimal:2',
    ];

    public function food()
    {
        return $this->belongsTo(Foods::class);
    }
}
