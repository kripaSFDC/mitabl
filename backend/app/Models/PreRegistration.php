<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PreRegistration extends Model
{
    use HasFactory;

    public const STATUS_NEW = 'new';
    public const STATUS_CONTACTED = 'contacted';
    public const STATUS_CONVERTED = 'converted';
    public const STATUS_DISQUALIFIED = 'disqualified';
    public const STATUS_SPAM = 'spam';

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
        'consent_to_contact',
        'communication_preference',
        'consent_captured_at',
        'followed_up_by',
        'assigned_to',
        'followed_up_at',
        'converted_user_id',
        'duplicate_fingerprint',
        'spam_score',
        'spam_detected_at',
        'last_contacted_at',
        'metadata',
    ];

    protected $casts = [
        'consent_to_contact' => 'boolean',
        'consent_captured_at' => 'datetime',
        'followed_up_at' => 'datetime',
        'spam_detected_at' => 'datetime',
        'last_contacted_at' => 'datetime',
        'metadata' => 'array',
    ];

    public static function statuses(): array
    {
        return [
            self::STATUS_NEW,
            self::STATUS_CONTACTED,
            self::STATUS_CONVERTED,
            self::STATUS_DISQUALIFIED,
            self::STATUS_SPAM,
        ];
    }

    public function assignee()
    {
        return $this->belongsTo(AdminUser::class, 'assigned_to');
    }

    public function follower()
    {
        return $this->belongsTo(AdminUser::class, 'followed_up_by');
    }

    public function convertedUser()
    {
        return $this->belongsTo(User::class, 'converted_user_id');
    }
}
