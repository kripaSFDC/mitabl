<?php

namespace App\Mail;

use App\Models\SupportTicket;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;

class SupportTicketReply extends Mailable implements ShouldQueue
{
    use Queueable, SerializesModels;

    public function __construct(
        public SupportTicket $ticket,
        public ?string $messageBody,
        public bool $isAcknowledgement = false
    ) {
    }

    public function build(): self
    {
        $subject = $this->isAcknowledgement
            ? 'Support ticket received: ' . $this->ticket->ticket_number
            : 'Update on ticket ' . $this->ticket->ticket_number;

        return $this->view('Mail.supportTicketReply')
            ->subject($subject);
    }
}
