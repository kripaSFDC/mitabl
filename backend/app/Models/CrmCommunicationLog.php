<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CrmCommunicationLog extends Model
{
    use HasFactory;

    protected $fillable = [
        'channel',
        'template',
        'recipient',
        'subject',
        'status',
        'metadata',
        'support_ticket_id',
        'queued_at',
        'sent_at',
    ];

    protected $casts = [
        'metadata' => 'array',
        'queued_at' => 'datetime',
        'sent_at' => 'datetime',
    ];

    public function supportTicket()
    {
        return $this->belongsTo(SupportTicket::class, 'support_ticket_id');
    }


}
