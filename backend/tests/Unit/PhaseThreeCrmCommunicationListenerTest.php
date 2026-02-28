<?php

namespace Tests\Unit;

use App\Listeners\MarkCrmCommunicationDelivered;
use App\Models\CrmCommunicationLog;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Mail\Events\MessageSent;
use Illuminate\Mail\SentMessage as LaravelSentMessage;
use Symfony\Component\Mailer\Envelope;
use Symfony\Component\Mailer\SentMessage as SymfonySentMessage;
use Symfony\Component\Mime\Address;
use Symfony\Component\Mime\Email;
use Tests\TestCase;

class PhaseThreeCrmCommunicationListenerTest extends TestCase
{
    use RefreshDatabase;

    public function test_listener_marks_queued_log_as_sent_on_message_sent_event(): void
    {
        $log = CrmCommunicationLog::create([
            'channel' => 'email',
            'template' => 'support_ticket_reply',
            'recipient' => 'listener@example.com',
            'subject' => 'Listener Subject',
            'status' => 'queued',
            'metadata' => ['ticket_number' => 'TCK-TEST'],
            'queued_at' => now(),
        ]);

        $email = (new Email())
            ->from('noreply@example.com')
            ->to('listener@example.com')
            ->subject('Listener Subject')
            ->text('test body');

        $envelope = new Envelope(
            new Address('noreply@example.com'),
            [new Address('listener@example.com')]
        );

        $sent = new LaravelSentMessage(new SymfonySentMessage($email, $envelope));
        $event = new MessageSent($sent, []);

        $listener = new MarkCrmCommunicationDelivered();
        $listener->handle($event);

        $log->refresh();
        $this->assertSame('sent', $log->status);
        $this->assertNotNull($log->sent_at);
    }
}
