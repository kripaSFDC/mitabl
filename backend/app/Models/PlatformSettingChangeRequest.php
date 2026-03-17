<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PlatformSettingChangeRequest extends Model
{
    use HasFactory;

    public const STATUS_VALIDATED = 'validated';
    public const STATUS_APPROVED = 'approved';
    public const STATUS_ACTIVATED = 'activated';
    public const STATUS_REJECTED = 'rejected';

    protected $fillable = [
        'setting_key',
        'proposed_value',
        'value_type',
        'description',
        'change_reason',
        'risk_level',
        'status',
        'requested_by',
        'approved_by',
        'activated_by',
        'validated_at',
        'approved_at',
        'activated_at',
    ];

    protected $casts = [
        'proposed_value' => 'array',
        'validated_at' => 'datetime',
        'approved_at' => 'datetime',
        'activated_at' => 'datetime',
    ];
}
