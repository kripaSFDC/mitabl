<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class SupportTicketEvent extends Model
{
    use HasFactory;

    protected $fillable = [
        'ticket_id',
        'event_type',
        'actor_type',
        'actor_id',
        'metadata',
    ];

    protected $casts = [
        'metadata' => 'array',
    ];

    public function ticket()
    {
        return $this->belongsTo(SupportTicket::class, 'ticket_id');
    }

    protected static function booted(): void
    {
        static::updating(function (): bool {
            throw new \LogicException('Support ticket events are immutable.');
        });

        static::deleting(function (): bool {
            throw new \LogicException('Support ticket events are immutable.');
        });
    }
}
