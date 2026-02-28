<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class SupportTicketAttachment extends Model
{
    use HasFactory;

    protected $fillable = [
        'ticket_id',
        'message_id',
        'disk',
        'path',
        'original_name',
        'mime_type',
        'size',
        'uploaded_by_type',
        'uploaded_by_id',
        'sha256',
        'scan_status',
        'scanned_at',
        'malware_detected_at',
    ];

    protected $casts = [
        'scanned_at' => 'datetime',
        'malware_detected_at' => 'datetime',
    ];

    public function ticket()
    {
        return $this->belongsTo(SupportTicket::class, 'ticket_id');
    }

    public function message()
    {
        return $this->belongsTo(SupportTicketMessage::class, 'message_id');
    }
}
