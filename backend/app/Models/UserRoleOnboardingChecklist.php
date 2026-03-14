<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class UserRoleOnboardingChecklist extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'role_id',
        'vendor_account_completed',
        'kitchen_profile_completed',
        'certificate_completed',
        'payout_setup_completed',
    ];

    protected $casts = [
        'vendor_account_completed' => 'boolean',
        'kitchen_profile_completed' => 'boolean',
        'certificate_completed' => 'boolean',
        'payout_setup_completed' => 'boolean',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function role()
    {
        return $this->belongsTo(Role::class);
    }
}
