<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class verifyOtp extends Model
{
    use HasFactory;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'user_id',
        'otp',
        'expires_at',
        'attempts',
        'locked_until',
    ];

    protected $casts = [
        'expires_at' => 'datetime',
        'locked_until' => 'datetime',
        'attempts' => 'integer',
    ];
}
