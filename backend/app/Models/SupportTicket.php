<?php

namespace App\Models;

use App\Models\WatchSubscription;
use App\Models\Tag;
use App\Models\InternalNote;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class SupportTicket extends Model
{
    use HasFactory;

    public const SOURCE_MOBILE_APP = 'mobile_app';
    public const SOURCE_WEBSITE = 'website';
    public const SOURCE_ADMIN = 'admin';

    public const CATEGORY_ORDER_DISPUTE = 'order_dispute';
    public const CATEGORY_PAYMENT = 'payment';
    public const CATEGORY_ACCOUNT = 'account';
    public const CATEGORY_GENERAL = 'general';
    public const CATEGORY_OTHER = 'other';

    public const STATUS_OPEN = 'open';
    public const STATUS_IN_PROGRESS = 'in_progress';
    public const STATUS_PENDING_USER = 'pending_user';
    public const STATUS_RESOLVED = 'resolved';
    public const STATUS_CLOSED = 'closed';
    public const STATUS_SPAM = 'spam';

    public const PRIORITY_LOW = 'low';
    public const PRIORITY_NORMAL = 'normal';
    public const PRIORITY_HIGH = 'high';
    public const PRIORITY_URGENT = 'urgent';

    protected $fillable = [
        'ticket_number',
        'user_id',
        'requester_name',
        'requester_email',
        'requester_phone',
        'subject',
        'description',
        'source',
        'category',
        'priority',
        'status',
        'assigned_to',
        'order_id',
        'mikitchn_id',
        'first_response_due_at',
        'resolution_due_at',
        'first_responded_at',
        'resolved_at',
        'resolution_summary',
        'closed_at',
        'merged_into_ticket_id',
        'split_from_ticket_id',
        'requester_token',
        'intake_fingerprint',
        'spam_score',
        'spam_detected_at',
        'first_response_breached_at',
        'resolution_breached_at',
        'reopened_count',
        'last_message_at',
    ];

    protected $casts = [
        'first_response_due_at' => 'datetime',
        'resolution_due_at' => 'datetime',
        'first_responded_at' => 'datetime',
        'resolved_at' => 'datetime',
        'closed_at' => 'datetime',
        'spam_detected_at' => 'datetime',
        'first_response_breached_at' => 'datetime',
        'resolution_breached_at' => 'datetime',
        'last_message_at' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function assignee()
    {
        return $this->belongsTo(AdminUser::class, 'assigned_to');
    }

    public function order()
    {
        return $this->belongsTo(Order::class);
    }

    public function mikitchn()
    {
        return $this->belongsTo(Mikitchn::class);
    }

    public function messages()
    {
        return $this->hasMany(SupportTicketMessage::class, 'ticket_id');
    }

    public function attachments()
    {
        return $this->hasMany(SupportTicketAttachment::class, 'ticket_id');
    }

    public function events()
    {
        return $this->hasMany(SupportTicketEvent::class, 'ticket_id');
    }

    public function mergedInto()
    {
        return $this->belongsTo(self::class, 'merged_into_ticket_id');
    }

    public function splitFrom()
    {
        return $this->belongsTo(self::class, 'split_from_ticket_id');
    }

    public function splitChildren()
    {
        return $this->hasMany(self::class, 'split_from_ticket_id');
    }

    public function mergedChildren()
    {
        return $this->hasMany(self::class, 'merged_into_ticket_id');
    }

    public function communicationLogs()
    {
        return $this->hasMany(CrmCommunicationLog::class, 'support_ticket_id');
    }

    public static function statuses(): array
    {
        return [
            self::STATUS_OPEN,
            self::STATUS_IN_PROGRESS,
            self::STATUS_PENDING_USER,
            self::STATUS_RESOLVED,
            self::STATUS_CLOSED,
            self::STATUS_SPAM,
        ];
    }

    public static function sources(): array
    {
        return [
            self::SOURCE_MOBILE_APP,
            self::SOURCE_WEBSITE,
            self::SOURCE_ADMIN,
        ];
    }

    public static function categories(): array
    {
        return [
            self::CATEGORY_ORDER_DISPUTE,
            self::CATEGORY_PAYMENT,
            self::CATEGORY_ACCOUNT,
            self::CATEGORY_GENERAL,
            self::CATEGORY_OTHER,
        ];
    }

    public static function priorities(): array
    {
        return [
            self::PRIORITY_LOW,
            self::PRIORITY_NORMAL,
            self::PRIORITY_HIGH,
            self::PRIORITY_URGENT,
        ];
    }

    public function isTerminal(): bool
    {
        return in_array($this->status, [self::STATUS_CLOSED, self::STATUS_SPAM], true);
    }

    public function firstResponseSlaState(): string
    {
        if ($this->first_response_breached_at !== null || ($this->first_responded_at === null && $this->first_response_due_at?->isPast())) {
            return 'breached';
        }

        if ($this->first_responded_at !== null) {
            return 'met';
        }

        if ($this->first_response_due_at !== null && now()->diffInMinutes($this->first_response_due_at, false) <= 30) {
            return 'at_risk';
        }

        return 'on_track';
    }

    public function resolutionSlaState(): string
    {
        if ($this->resolution_breached_at !== null || ($this->resolved_at === null && $this->resolution_due_at?->isPast())) {
            return 'breached';
        }

        if ($this->resolved_at !== null) {
            return 'met';
        }

        if ($this->resolution_due_at !== null && now()->diffInMinutes($this->resolution_due_at, false) <= 60) {
            return 'at_risk';
        }

        return 'on_track';
    }

    public function internalNotes()
    {
        return $this->morphMany(InternalNote::class, 'noteable')->latest();
    }

    public function tags()
    {
        return $this->morphToMany(Tag::class, 'taggable');
    }

    public function watchers()
    {
        return $this->morphMany(WatchSubscription::class, 'watchable');
    }


}
