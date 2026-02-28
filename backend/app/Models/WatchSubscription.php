<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class WatchSubscription extends Model
{
    use HasFactory;

    protected $fillable = [
        'watchable_type',
        'watchable_id',
        'admin_user_id',
    ];

    public function watchable()
    {
        return $this->morphTo();
    }

    public function adminUser()
    {
        return $this->belongsTo(AdminUser::class, 'admin_user_id');
    }
}
