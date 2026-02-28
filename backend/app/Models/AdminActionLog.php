<?php

namespace App\Models;

use LogicException;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AdminActionLog extends Model
{
    use HasFactory;

    public $timestamps = false;

    protected $fillable = [
        'admin_user_id',
        'action',
        'method',
        'path',
        'route_name',
        'status_code',
        'ip_address',
        'user_agent',
        'correlation_id',
        'metadata',
        'request_payload',
        'created_at',
    ];

    protected $casts = [
        'metadata' => 'array',
        'request_payload' => 'array',
        'created_at' => 'datetime',
    ];

    protected static function booted(): void
    {
        static::updating(function (): void {
            throw new LogicException('Admin action logs are immutable and cannot be updated.');
        });

        static::deleting(function (): void {
            throw new LogicException('Admin action logs are immutable and cannot be deleted.');
        });
    }

    public function adminUser()
    {
        return $this->belongsTo(AdminUser::class, 'admin_user_id');
    }
}
