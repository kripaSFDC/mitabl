<?php

namespace App\Listeners;

use App\Models\CrmCommunicationLog;
use Illuminate\Mail\Events\MessageSent;
use Illuminate\Support\Str;

class MarkCrmCommunicationDelivered
{
    public function handle(MessageSent $event): void
    {
        $message = $event->message;
        $subject = trim((string) $message->getSubject());
        $to = $message->getTo() ?: [];

        if ($subject === '' || empty($to)) {
            return;
        }

        foreach ($to as $address) {
            $email = Str::lower((string) $address->getAddress());
            if ($email === '') {
                continue;
            }

            $log = CrmCommunicationLog::query()
                ->where('channel', 'email')
                ->where('recipient', $email)
                ->where('subject', $subject)
                ->where('status', 'queued')
                ->orderByDesc('id')
                ->first();

            if ($log) {
                $log->status = 'sent';
                $log->sent_at = now();
                $log->save();
            }
        }
    }
}
