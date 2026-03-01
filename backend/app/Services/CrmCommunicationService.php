<?php

namespace App\Services;

use App\Mail\SupportTicketEscalated;
use App\Mail\SupportTicketReply;
use App\Models\AdminUser;
use App\Models\CrmCommunicationLog;
use App\Models\SupportTicket;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;

class CrmCommunicationService
{
    public function __construct(private PiiRedactionService $redaction)
    {
    }

    public function sendTicketAcknowledgement(SupportTicket $ticket): void
    {
        if (! $ticket->requester_email) {
            return;
        }

        $this->queueMail(
            recipient: $ticket->requester_email,
            template: 'support_ticket_acknowledged',
            subject: 'Support ticket received: ' . $ticket->ticket_number,
            mailable: new SupportTicketReply($ticket, null, true),
            ticket: $ticket
        );
    }

    public function sendTicketReply(SupportTicket $ticket, string $message): void
    {
        if (! $ticket->requester_email) {
            return;
        }

        $safeMessage = $this->redaction->redact($message);

        $this->queueMail(
            recipient: $ticket->requester_email,
            template: 'support_ticket_reply',
            subject: 'Update on ticket ' . $ticket->ticket_number,
            mailable: new SupportTicketReply($ticket, $safeMessage, false),
            ticket: $ticket
        );
    }

    public function sendTicketEscalation(SupportTicket $ticket, string $reason, ?AdminUser $assignee = null): void
    {
        $target = $assignee?->email;
        if (! $target) {
            $target = (string) config('mail.from.address');
        }
        if ($target === '') {
            return;
        }

        $this->queueMail(
            recipient: $target,
            template: 'support_ticket_escalated',
            subject: 'SLA escalation: ' . $ticket->ticket_number,
            mailable: new SupportTicketEscalated($ticket, $this->redaction->redact($reason)),
            ticket: $ticket
        );
    }

    private function queueMail(
        string $recipient,
        string $template,
        string $subject,
        $mailable,
        ?SupportTicket $ticket = null
    ): void {
        try {
            Mail::to($recipient)->queue(
                $mailable
                    ->onQueue('crm-communications')
                    ->afterCommit()
            );

            CrmCommunicationLog::create([
                'channel' => 'email',
                'template' => $template,
                'recipient' => $recipient,
                'subject' => $subject,
                'status' => 'queued',
                'metadata' => [
                    'ticket_number' => $ticket?->ticket_number,
                ],
                'support_ticket_id' => $ticket?->id,
                'queued_at' => now(),
            ]);
        } catch (\Throwable $throwable) {
            Log::error('crm.communication.queue_failed', [
                'recipient' => $recipient,
                'template' => $template,
                'error' => $throwable->getMessage(),
            ]);

            CrmCommunicationLog::create([
                'channel' => 'email',
                'template' => $template,
                'recipient' => $recipient,
                'subject' => $subject,
                'status' => 'failed',
                'metadata' => [
                    'error' => $throwable->getMessage(),
                    'ticket_number' => $ticket?->ticket_number,
                ],
                'support_ticket_id' => $ticket?->id,
            ]);
        }
    }
}
