<?php

namespace App\Mail;

use App\Models\SupportTicket;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;

class SupportTicketEscalated extends Mailable implements ShouldQueue
{
    use Queueable, SerializesModels;

    public function __construct(public SupportTicket $ticket, public string $reason)
    {
    }

    public function build(): self
    {
        return $this->view('Mail.supportTicketEscalated')
            ->subject('SLA escalation: ' . $this->ticket->ticket_number);
    }
}
