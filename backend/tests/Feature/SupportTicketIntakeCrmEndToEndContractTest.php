<?php

namespace Tests\Feature;

use App\Filament\Resources\SupportTicketResource;
use App\Models\AdminUser;
use App\Models\SupportTicket;
use App\Services\SupportTicketService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class SupportTicketIntakeCrmEndToEndContractTest extends TestCase
{
    use RefreshDatabase;

    public function test_support_ticket_public_intake_to_crm_operator_workflow_contract(): void
    {
        Mail::fake();

        $payload = [
            'requester_name' => 'CRM Contract Tester',
            'requester_email' => 'crm-contract@example.com',
            'requester_phone' => '+61 411 111 111',
            'subject' => 'Need help with account updates',
            'description' => 'I need help updating account details and checking ticket lifecycle.',
        ];

        $response = $this->withHeaders([
            'X-Authenticated-Channel' => SupportTicket::SOURCE_WEBSITE,
        ])->postJson('/api/support/ticket', $payload);

        $response->assertOk()
            ->assertJsonPath('status', 200)
            ->assertJsonPath('isSuccess', true)
            ->assertJsonPath('data.status', SupportTicket::STATUS_OPEN)
            ->assertJsonPath('data.duplicate', false);

        $ticketId = (int) $response->json('data.id');
        $ticket = SupportTicket::query()->findOrFail($ticketId);

        $this->assertSame(SupportTicket::SOURCE_WEBSITE, $ticket->source);
        $this->assertSame(SupportTicket::CATEGORY_GENERAL, $ticket->category);
        $this->assertSame(SupportTicket::PRIORITY_NORMAL, $ticket->priority);
        $this->assertSame(SupportTicket::STATUS_OPEN, $ticket->status);
        $this->assertNull($ticket->assigned_to);
        $this->assertNotNull($ticket->first_response_due_at);
        $this->assertNotNull($ticket->resolution_due_at);
        $this->assertNotNull($ticket->requester_token);
        $this->assertNotNull($ticket->intake_fingerprint);

        $this->assertDatabaseHas('support_ticket_messages', [
            'ticket_id' => $ticket->id,
            'sender_type' => 'user',
            'message' => $payload['description'],
        ]);

        $this->assertDatabaseHas('support_ticket_events', [
            'ticket_id' => $ticket->id,
            'event_type' => 'ticket_created',
            'actor_type' => 'user',
        ]);

        $this->assertDatabaseHas('crm_communication_logs', [
            'support_ticket_id' => $ticket->id,
            'template' => 'support_ticket_acknowledged',
            'status' => 'queued',
        ]);

        $crmInboxQuery = SupportTicket::query()
            ->with(['assignee', 'user', 'mikitchn', 'order', 'tags'])
            ->withCount('watchers')
            ->whereNull('merged_into_ticket_id');

        $this->assertTrue($crmInboxQuery->whereKey($ticket->id)->exists());
        $this->assertTrue(class_exists(SupportTicketResource::class));

        /** @var SupportTicketService $service */
        $service = app(SupportTicketService::class);
        $admin = $this->createAdmin();

        $assigned = $service->assignTicket($ticket, $admin->id, 'Taking ownership in CRM queue', $admin->id);
        $this->assertSame($admin->id, $assigned->assigned_to);
        $this->assertSame(SupportTicket::STATUS_IN_PROGRESS, $assigned->status);

        $adminReply = $service->addReply($assigned, [
            'message' => 'Thanks, I am reviewing this now and will update shortly.',
            'is_internal_note' => false,
        ], 'admin', $admin->id);

        $this->assertSame('admin', $adminReply->sender_type);

        $pendingUser = $service->transitionStatus(
            $assigned->fresh(),
            SupportTicket::STATUS_PENDING_USER,
            'Waiting for user confirmation before closing',
            $admin->id
        );
        $this->assertSame(SupportTicket::STATUS_PENDING_USER, $pendingUser->status);

        $resolved = $service->resolveTicket($pendingUser, 'Provided instructions and user confirmed resolution.', $admin->id);
        $this->assertSame(SupportTicket::STATUS_RESOLVED, $resolved->status);
        $this->assertNotNull($resolved->resolved_at);

        $closed = $service->transitionStatus(
            $resolved->fresh(),
            SupportTicket::STATUS_CLOSED,
            'Auto-close after confirmation and no further requester updates.',
            $admin->id
        );
        $this->assertSame(SupportTicket::STATUS_CLOSED, $closed->status);
        $this->assertNotNull($closed->closed_at);

        $this->assertDatabaseHas('support_ticket_events', [
            'ticket_id' => $ticket->id,
            'event_type' => 'assigned',
            'actor_type' => 'admin',
            'actor_id' => $admin->id,
        ]);

        $this->assertDatabaseHas('support_ticket_events', [
            'ticket_id' => $ticket->id,
            'event_type' => 'ticket_reply',
            'actor_type' => 'admin',
            'actor_id' => $admin->id,
        ]);

        $this->assertDatabaseHas('support_ticket_events', [
            'ticket_id' => $ticket->id,
            'event_type' => 'status_changed',
            'actor_type' => 'admin',
            'actor_id' => $admin->id,
        ]);

        $this->assertDatabaseHas('support_ticket_events', [
            'ticket_id' => $ticket->id,
            'event_type' => 'resolved',
            'actor_type' => 'admin',
            'actor_id' => $admin->id,
        ]);

        $this->assertDatabaseHas('support_ticket_events', [
            'ticket_id' => $ticket->id,
            'event_type' => 'status_changed',
            'actor_type' => 'admin',
            'actor_id' => $admin->id,
        ]);

        $this->assertDatabaseHas('crm_communication_logs', [
            'support_ticket_id' => $ticket->id,
            'template' => 'support_ticket_reply',
            'status' => 'queued',
        ]);

        $this->assertLegacyIntakePathDisabled('post', '/api/pre-registration', [
            'email' => 'legacy@example.com',
        ]);
        $this->assertLegacyIntakePathDisabled('post', '/api/preregistration', [
            'email' => 'legacy@example.com',
        ]);
        $this->assertLegacyIntakePathDisabled('post', '/api/v1/mob-contact', [
            'subject' => 'Legacy public support intake',
            'description' => 'This route should not be available as a public intake endpoint.',
        ]);
    }

    public function test_crm_support_ticket_resource_visibility_and_filter_contracts(): void
    {
        $admin = $this->createAdmin();
        $otherAdmin = $this->createAdmin();

        $mine = $this->serviceCreateTicketForCrmFilter('mine@example.com', 'Mine ticket', 'normal');
        $mine->update([
            'assigned_to' => $admin->id,
            'status' => SupportTicket::STATUS_IN_PROGRESS,
            'first_response_due_at' => now()->addHour(),
            'resolution_due_at' => now()->addHours(3),
        ]);

        $unassignedAtRisk = $this->serviceCreateTicketForCrmFilter('risk@example.com', 'At risk ticket', 'high');
        $unassignedAtRisk->update([
            'assigned_to' => null,
            'status' => SupportTicket::STATUS_OPEN,
            'first_response_due_at' => now()->addMinutes(10),
            'resolution_due_at' => now()->addMinutes(45),
        ]);

        $merged = $this->serviceCreateTicketForCrmFilter('merged@example.com', 'Merged source', 'normal');
        $merged->update([
            'assigned_to' => $otherAdmin->id,
            'status' => SupportTicket::STATUS_OPEN,
            'merged_into_ticket_id' => $mine->id,
        ]);

        $this->assertTrue(
            SupportTicket::query()->whereNull('merged_into_ticket_id')->whereKey($mine->id)->exists()
        );
        $this->assertTrue(
            SupportTicket::query()->whereNull('merged_into_ticket_id')->whereKey($unassignedAtRisk->id)->exists()
        );
        $this->assertFalse(
            SupportTicket::query()->whereNull('merged_into_ticket_id')->whereKey($merged->id)->exists()
        );

        $myQueue = SupportTicket::query()
            ->whereNull('merged_into_ticket_id')
            ->where('assigned_to', $admin->id)
            ->pluck('id')
            ->all();
        $this->assertSame([$mine->id], $myQueue);

        $unassignedOnly = SupportTicket::query()
            ->whereNull('merged_into_ticket_id')
            ->whereNull('assigned_to')
            ->pluck('id')
            ->all();
        $this->assertSame([$unassignedAtRisk->id], $unassignedOnly);

        $slaRisk = SupportTicket::query()
            ->whereNull('merged_into_ticket_id')
            ->where(function ($risk): void {
                $risk->where(function ($first): void {
                    $first->whereNull('first_responded_at')
                        ->whereNotNull('first_response_due_at')
                        ->where('first_response_due_at', '<=', now()->addMinutes(30));
                })->orWhere(function ($resolution): void {
                    $resolution->whereNull('resolved_at')
                        ->whereNotNull('resolution_due_at')
                        ->where('resolution_due_at', '<=', now()->addHour());
                });
            })
            ->pluck('id')
            ->all();
        $this->assertSame([$unassignedAtRisk->id], $slaRisk);

        $resourceSource = (string) file_get_contents(app_path('Filament/Resources/SupportTicketResource.php'));
        $this->assertStringContainsString("->whereNull('merged_into_ticket_id')", $resourceSource);
        $this->assertStringContainsString("TernaryFilter::make('my_queue')", $resourceSource);
        $this->assertStringContainsString("TernaryFilter::make('unassigned')", $resourceSource);
        $this->assertStringContainsString("TernaryFilter::make('sla_risk')", $resourceSource);
        $this->assertStringContainsString("SelectFilter::make('status')", $resourceSource);
        $this->assertStringContainsString("SelectFilter::make('priority')", $resourceSource);
        $this->assertStringContainsString("SupportTicket::STATUS_RESOLVED => 'Resolved'", $resourceSource);
        $this->assertStringContainsString("SupportTicket::STATUS_CLOSED => 'Closed'", $resourceSource);
        $this->assertStringContainsString("Forms\Components\Select::make('priority')", $resourceSource);
        $this->assertStringContainsString("Forms\Components\Select::make('status')", $resourceSource);
        $this->assertStringContainsString("Forms\Components\Select::make('assigned_to')", $resourceSource);
    }

    public function test_support_ticket_schema_contract_includes_required_tables_columns_and_relationships(): void
    {
        foreach ([
            'support_tickets',
            'support_ticket_messages',
            'support_ticket_attachments',
            'support_ticket_events',
            'crm_communication_logs',
        ] as $table) {
            $this->assertTrue(Schema::hasTable($table), sprintf('Expected table [%s] to exist.', $table));
        }

        $this->assertTrue(Schema::hasColumns('support_tickets', [
            'user_id',
            'assigned_to',
            'order_id',
            'mikitchn_id',
            'merged_into_ticket_id',
            'split_from_ticket_id',
            'requester_token',
            'intake_fingerprint',
            'closed_at',
        ]));

        $this->assertTrue(Schema::hasColumns('support_ticket_messages', ['ticket_id']));
        $this->assertTrue(Schema::hasColumns('support_ticket_attachments', ['ticket_id', 'message_id']));
        $this->assertTrue(Schema::hasColumns('support_ticket_events', ['ticket_id']));
        $this->assertTrue(Schema::hasColumns('crm_communication_logs', ['support_ticket_id']));

        if (DB::getDriverName() === 'sqlite') {
            $ticketForeignKeys = collect(DB::select("PRAGMA foreign_key_list('support_tickets')"))->pluck('table')->all();
            $this->assertContains('users', $ticketForeignKeys);
            $this->assertContains('admin_users', $ticketForeignKeys);
            $this->assertContains('orders', $ticketForeignKeys);
            $this->assertContains('mikitchns', $ticketForeignKeys);
            $this->assertContains('support_tickets', $ticketForeignKeys);

            $messageForeignKeys = collect(DB::select("PRAGMA foreign_key_list('support_ticket_messages')"))->pluck('table')->all();
            $this->assertContains('support_tickets', $messageForeignKeys);

            $attachmentForeignKeys = collect(DB::select("PRAGMA foreign_key_list('support_ticket_attachments')"))->pluck('table')->all();
            $this->assertContains('support_tickets', $attachmentForeignKeys);
            $this->assertContains('support_ticket_messages', $attachmentForeignKeys);

            $eventForeignKeys = collect(DB::select("PRAGMA foreign_key_list('support_ticket_events')"))->pluck('table')->all();
            $this->assertContains('support_tickets', $eventForeignKeys);

            $crmLogForeignKeys = collect(DB::select("PRAGMA foreign_key_list('crm_communication_logs')"))->pluck('table')->all();
            $this->assertContains('support_tickets', $crmLogForeignKeys);
        }
    }

    private function serviceCreateTicketForCrmFilter(string $email, string $subject, string $priority): SupportTicket
    {
        /** @var SupportTicketService $service */
        $service = app(SupportTicketService::class);

        return $service->createTicket([
            'requester_name' => 'CRM Filter',
            'requester_email' => $email,
            'subject' => $subject,
            'description' => 'Filter validation ticket',
            'category' => SupportTicket::CATEGORY_GENERAL,
            'priority' => $priority,
        ], SupportTicket::SOURCE_WEBSITE)['ticket'];
    }

    private function assertLegacyIntakePathDisabled(string $method, string $uri, array $payload = []): void
    {
        $response = $this->json($method, $uri, $payload);

        $this->assertTrue(
            in_array($response->getStatusCode(), [401, 403, 404, 405], true),
            sprintf('Expected legacy intake path [%s %s] to be disabled, got HTTP %d.', strtoupper($method), $uri, $response->getStatusCode())
        );
    }

    private function createAdmin(): AdminUser
    {
        return AdminUser::query()->create([
            'name' => 'Support Admin',
            'email' => 'support-admin+'.uniqid().'@example.com',
            'password' => Hash::make('Password123!'),
            'is_active' => true,
        ]);
    }
}
