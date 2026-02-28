<?php

namespace Tests\Unit;

use App\Jobs\ProcessSupportTicketSlaEscalationJob;
use App\Models\AdminUser;
use App\Models\SupportTicket;
use App\Models\User;
use App\Services\SupportTicketService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Bus;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use InvalidArgumentException;
use Tests\TestCase;

class PhaseThreeSupportTicketServiceTest extends TestCase
{
    use RefreshDatabase;

    private SupportTicketService $service;

    protected function setUp(): void
    {
        parent::setUp();
        Mail::fake();
        $this->service = app(SupportTicketService::class);
    }

    public function test_create_ticket_sets_lifecycle_sla_message_event_and_comm_log(): void
    {
        $user = $this->createUser();

        $result = $this->service->createTicket([
            'user_id' => $user->id,
            'requester_name' => 'Jamie Tester',
            'requester_email' => 'jamie@example.com',
            'requester_phone' => '0400111222',
            'subject' => 'Order timing issue',
            'description' => 'My order did not arrive on time.',
            'category' => 'order',
            'priority' => 'high',
            'actor_type' => 'user',
            'actor_id' => $user->id,
        ], 'public_api');

        $ticket = $result['ticket'];

        $this->assertFalse($result['duplicate']);
        $this->assertSame(SupportTicket::STATUS_OPEN, $ticket->status);
        $this->assertStringStartsWith('TCK-', $ticket->ticket_number);
        $this->assertNotNull($ticket->first_response_due_at);
        $this->assertNotNull($ticket->resolution_due_at);
        $this->assertNotNull($ticket->requester_token);
        $this->assertSame(1, $ticket->messages()->count());
        $this->assertDatabaseHas('support_ticket_events', [
            'ticket_id' => $ticket->id,
            'event_type' => 'ticket_created',
        ]);
        $this->assertDatabaseHas('crm_communication_logs', [
            'support_ticket_id' => $ticket->id,
            'status' => 'queued',
            'template' => 'support_ticket_acknowledged',
        ]);
    }

    public function test_ticket_duplicate_detection_and_skip_duplicate_override(): void
    {
        $payload = [
            'requester_name' => 'Duplicate Check',
            'requester_email' => 'duplicate@example.com',
            'subject' => 'Same issue',
            'description' => 'Repeated payload should dedupe.',
            'category' => 'general',
            'priority' => 'normal',
        ];

        $first = $this->service->createTicket($payload, 'public_api');
        $second = $this->service->createTicket($payload, 'public_api');
        $third = $this->service->createTicket(array_merge($payload, [
            'skip_duplicate_check' => true,
        ]), 'admin_panel');

        $this->assertFalse($first['duplicate']);
        $this->assertTrue($second['duplicate']);
        $this->assertSame($first['ticket']->id, $second['ticket']->id);
        $this->assertFalse($third['duplicate']);
        $this->assertNotSame($first['ticket']->id, $third['ticket']->id);
    }

    public function test_reply_and_transition_rules_including_reopen_window(): void
    {
        $admin = $this->createAdmin();
        $ticket = $this->service->createTicket([
            'requester_email' => 'workflow@example.com',
            'subject' => 'Workflow path',
            'description' => 'Need workflow validation',
            'category' => 'general',
            'priority' => 'normal',
        ])['ticket'];

        $this->service->assignTicket($ticket, $admin->id, 'Assign for handling', $admin->id);
        $ticket = $ticket->fresh();
        $this->assertSame(SupportTicket::STATUS_IN_PROGRESS, $ticket->status);

        $this->service->addReply($ticket, [
            'message' => 'Investigating now.',
            'is_internal_note' => false,
        ], 'admin', $admin->id);
        $ticket = $ticket->fresh();
        $this->assertNotNull($ticket->first_responded_at);

        $resolved = $this->service->resolveTicket($ticket, 'Issue resolved with customer guidance.', $admin->id);
        $this->assertSame(SupportTicket::STATUS_RESOLVED, $resolved->status);

        $reopened = $this->service->transitionStatus($resolved, SupportTicket::STATUS_OPEN, 'Customer replied again', $admin->id);
        $this->assertSame(SupportTicket::STATUS_OPEN, $reopened->status);
        $this->assertSame(1, (int) $reopened->reopened_count);
        $this->assertNull($reopened->resolved_at);
        $this->assertNull($reopened->resolution_summary);
    }

    public function test_reopen_after_window_is_rejected(): void
    {
        config(['support.reopen_window_hours' => 1]);
        $admin = $this->createAdmin();
        $ticket = $this->service->createTicket([
            'requester_email' => 'old-resolved@example.com',
            'subject' => 'Old ticket',
            'description' => 'Old resolved ticket',
        ])['ticket'];

        $ticket->status = SupportTicket::STATUS_RESOLVED;
        $ticket->resolved_at = now()->subHours(2);
        $ticket->save();

        $this->expectException(InvalidArgumentException::class);
        $this->service->transitionStatus($ticket, SupportTicket::STATUS_OPEN, 'Too old to reopen', $admin->id);
    }

    public function test_reply_on_resolved_ticket_requires_reopen_reason_and_reopens_within_window(): void
    {
        $ticket = $this->service->createTicket([
            'requester_email' => 'resolved-reply@example.com',
            'subject' => 'Resolved thread',
            'description' => 'Initial issue',
        ])['ticket'];

        $ticket->status = SupportTicket::STATUS_RESOLVED;
        $ticket->resolved_at = now()->subMinutes(10);
        $ticket->resolution_summary = 'Resolved once';
        $ticket->save();

        try {
            $this->service->addReply($ticket, [
                'message' => 'Need more help',
            ], 'user', 123);
            $this->fail('Expected missing reopen reason to be rejected.');
        } catch (InvalidArgumentException $exception) {
            $this->assertStringContainsString('Reopen reason is required', $exception->getMessage());
        }

        $this->service->addReply($ticket, [
            'message' => 'Need more help',
            'reopen_reason' => 'Issue returned after previous fix',
        ], 'user', 123);

        $ticket->refresh();
        $this->assertSame(SupportTicket::STATUS_OPEN, $ticket->status);
        $this->assertSame(1, (int) $ticket->reopened_count);
        $this->assertNull($ticket->resolved_at);
        $this->assertNull($ticket->resolution_summary);
        $this->assertDatabaseHas('support_ticket_events', [
            'ticket_id' => $ticket->id,
            'event_type' => 'reopened',
        ]);
    }

    public function test_reply_on_resolved_ticket_after_reopen_window_is_rejected(): void
    {
        config(['support.reopen_window_hours' => 1]);

        $ticket = $this->service->createTicket([
            'requester_email' => 'resolved-expired@example.com',
            'subject' => 'Expired reopen window',
            'description' => 'Initial issue',
        ])['ticket'];

        $ticket->status = SupportTicket::STATUS_RESOLVED;
        $ticket->resolved_at = now()->subHours(2);
        $ticket->save();

        try {
            $this->service->addReply($ticket, [
                'message' => 'Need more help',
                'reopen_reason' => 'Issue still persists',
            ], 'user', 456);
            $this->fail('Expected expired reopen window to be rejected.');
        } catch (InvalidArgumentException $exception) {
            $this->assertStringContainsString('Reopen window has expired', $exception->getMessage());
        }
    }

    public function test_terminal_state_guards_for_assign_resolve_merge_and_split(): void
    {
        $admin = $this->createAdmin();
        $closed = $this->service->createTicket([
            'requester_email' => 'closed@example.com',
            'subject' => 'Closed',
            'description' => 'Closed ticket',
        ])['ticket'];

        $closed->status = SupportTicket::STATUS_CLOSED;
        $closed->closed_at = now();
        $closed->save();

        try {
            $this->service->assignTicket($closed, $admin->id, 'Should fail', $admin->id);
            $this->fail('Expected terminal assignment guard.');
        } catch (InvalidArgumentException $exception) {
            $this->assertStringContainsString('Terminal tickets cannot be reassigned', $exception->getMessage());
        }

        try {
            $this->service->resolveTicket($closed, 'Should fail', $admin->id);
            $this->fail('Expected resolve state guard.');
        } catch (InvalidArgumentException $exception) {
            $this->assertStringContainsString('Only active tickets can be resolved', $exception->getMessage());
        }

        $open = $this->service->createTicket([
            'requester_email' => 'open-ticket@example.com',
            'subject' => 'Open ticket',
            'description' => 'Open ticket body',
        ])['ticket'];

        try {
            $this->service->mergeInto($closed, $open, 'Should fail merge', $admin->id);
            $this->fail('Expected terminal merge guard.');
        } catch (InvalidArgumentException $exception) {
            $this->assertStringContainsString('Terminal tickets cannot be merged', $exception->getMessage());
        }

        try {
            $this->service->splitTicket($closed, 'Split subject', 'Split body', $admin->id);
            $this->fail('Expected terminal split guard.');
        } catch (InvalidArgumentException $exception) {
            $this->assertStringContainsString('Terminal tickets cannot be split', $exception->getMessage());
        }
    }

    public function test_sla_scan_dispatches_only_valid_jobs_for_unresolved_tickets(): void
    {
        Bus::fake();

        $unresolved = $this->service->createTicket([
            'requester_email' => 'sla-open@example.com',
            'subject' => 'Open SLA',
            'description' => 'Open SLA should enqueue',
        ])['ticket'];
        $unresolved->first_response_due_at = now()->subMinute();
        $unresolved->resolution_due_at = now()->subMinute();
        $unresolved->save();

        $resolved = $this->service->createTicket([
            'requester_email' => 'sla-resolved@example.com',
            'subject' => 'Resolved SLA',
            'description' => 'Resolved should not enqueue first response',
        ])['ticket'];
        $resolved->status = SupportTicket::STATUS_RESOLVED;
        $resolved->resolved_at = now()->subMinute();
        $resolved->first_response_due_at = now()->subMinute();
        $resolved->resolution_due_at = now()->subMinute();
        $resolved->save();

        Artisan::call('support:sla:scan');

        Bus::assertDispatched(ProcessSupportTicketSlaEscalationJob::class, function ($job) use ($unresolved) {
            return $this->readJobProperty($job, 'ticketId') === $unresolved->id;
        });

        Bus::assertNotDispatched(ProcessSupportTicketSlaEscalationJob::class, function ($job) use ($resolved) {
            return $this->readJobProperty($job, 'ticketId') === $resolved->id
                && $this->readJobProperty($job, 'reason') === 'first_response';
        });
    }

    private function readJobProperty(object $job, string $property): mixed
    {
        $reflection = new \ReflectionClass($job);
        $prop = $reflection->getProperty($property);
        $prop->setAccessible(true);
        return $prop->getValue($job);
    }

    private function createUser(): User
    {
        return User::create([
            'role_id' => 3,
            'first_name' => 'Unit',
            'last_name' => 'User',
            'email' => 'unit-user-' . uniqid() . '@example.com',
            'password' => Hash::make('password'),
            'phone' => 400111222,
            'address' => 'Canberra',
        ]);
    }

    private function createAdmin(): AdminUser
    {
        return AdminUser::create([
            'name' => 'Ops Admin',
            'email' => 'ops-admin-' . uniqid() . '@example.com',
            'password' => Hash::make('password'),
            'is_active' => true,
        ]);
    }
}
