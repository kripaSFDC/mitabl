<?php

namespace App\Services;

use App\Mail\PreRegistrationAcknowledged;
use App\Mail\SupportTicketEscalated;
use App\Mail\SupportTicketReply;
use App\Models\AdminUser;
use App\Models\CrmCommunicationLog;
use App\Models\PreRegistration;
use App\Models\SupportTicket;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;

class CrmCommunicationService
{
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

        $this->queueMail(
            recipient: $ticket->requester_email,
            template: 'support_ticket_reply',
            subject: 'Update on ticket ' . $ticket->ticket_number,
            mailable: new SupportTicketReply($ticket, $message, false),
            ticket: $ticket
        );
    }

    public function sendTicketEscalation(SupportTicket $ticket, string $reason, ?AdminUser $assignee = null): void
    {
        $target = $assignee?->email;
        if (! $target) {
            return;
        }

        $this->queueMail(
            recipient: $target,
            template: 'support_ticket_escalated',
            subject: 'SLA escalation: ' . $ticket->ticket_number,
            mailable: new SupportTicketEscalated($ticket, $reason),
            ticket: $ticket
        );
    }

    public function sendPreRegistrationAcknowledgement(PreRegistration $registration): void
    {
        if (! $registration->email) {
            return;
        }

        $this->queueMail(
            recipient: $registration->email,
            template: 'pre_registration_acknowledged',
            subject: 'Thanks for your interest in mitabl',
            mailable: new PreRegistrationAcknowledged($registration),
            preRegistration: $registration
        );
    }

    private function queueMail(
        string $recipient,
        string $template,
        string $subject,
        $mailable,
        ?SupportTicket $ticket = null,
        ?PreRegistration $preRegistration = null
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
                    'pre_registration_id' => $preRegistration?->id,
                ],
                'support_ticket_id' => $ticket?->id,
                'pre_registration_id' => $preRegistration?->id,
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
                    'pre_registration_id' => $preRegistration?->id,
                ],
                'support_ticket_id' => $ticket?->id,
                'pre_registration_id' => $preRegistration?->id,
            ]);
        }
    }
}
