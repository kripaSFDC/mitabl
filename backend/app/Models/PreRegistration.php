<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PreRegistration extends Model
{
    use HasFactory;

    protected $fillable = [
        'first_name',
        'last_name',
        'email',
        'phone',
        'city',
        'interested_as',
        'source',
        'status',
        'notes',
        'followed_up_by',
        'followed_up_at',
        'converted_user_id',
        'consent_to_contact',
    ];

    protected $casts = [
        'followed_up_at' => 'datetime',
        'consent_to_contact' => 'boolean',
    ];

    public function followedUpBy()
    {
        return $this->belongsTo(AdminUser::class, 'followed_up_by');
    }

    public function convertedUser()
    {
        return $this->belongsTo(User::class, 'converted_user_id');
    }
}
