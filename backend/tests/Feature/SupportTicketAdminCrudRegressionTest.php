<?php

namespace Tests\Feature;

use App\Models\AdminUser;
use App\Models\SupportTicket;
use App\Services\SupportTicketService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class SupportTicketAdminCrudRegressionTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_form_update_uses_ticket_workflow_rules_for_assignment_classification_and_resolution(): void
    {
        $admin = AdminUser::query()->create([
            'name' => 'Support Admin',
            'email' => 'support-admin@example.test',
            'password' => bcrypt('password123'),
            'is_active' => true,
        ]);

        $ticket = SupportTicket::query()->create([
            'ticket_number' => 'TKT-000001',
            'requester_email' => 'customer@example.test',
            'subject' => 'Need help',
            'description' => 'Original description',
            'source' => SupportTicket::SOURCE_ADMIN,
            'category' => SupportTicket::CATEGORY_GENERAL,
            'priority' => SupportTicket::PRIORITY_LOW,
            'status' => SupportTicket::STATUS_OPEN,
            'first_response_due_at' => now()->addHour(),
            'resolution_due_at' => now()->addDay(),
            'requester_token' => 'token',
            'last_message_at' => now(),
        ]);

        $updated = app(SupportTicketService::class)->updateFromAdminForm(
            $ticket,
            [
                'requester_email' => 'updated@example.test',
                'requester_phone' => '+1 (555) 123-4567',
                'subject' => 'Need urgent help',
                'description' => 'Updated description',
                'priority' => SupportTicket::PRIORITY_URGENT,
                'category' => SupportTicket::CATEGORY_PAYMENT,
                'assigned_to' => $admin->id,
                'status' => SupportTicket::STATUS_RESOLVED,
                'resolution_summary' => 'Resolved by admin.',
            ],
            $admin->id,
            $ticket->updated_at?->toISOString()
        );

        $this->assertSame('updated@example.test', $updated->requester_email);
        $this->assertSame('+15551234567', $updated->requester_phone);
        $this->assertSame(SupportTicket::PRIORITY_URGENT, $updated->priority);
        $this->assertSame(SupportTicket::CATEGORY_PAYMENT, $updated->category);
        $this->assertSame($admin->id, $updated->assigned_to);
        $this->assertSame(SupportTicket::STATUS_RESOLVED, $updated->status);
        $this->assertSame('Resolved by admin.', $updated->resolution_summary);
        $this->assertNotNull($updated->resolved_at);
        $this->assertDatabaseHas('support_ticket_events', [
            'ticket_id' => $ticket->id,
            'event_type' => 'classification_changed',
        ]);
        $this->assertDatabaseHas('support_ticket_events', [
            'ticket_id' => $ticket->id,
            'event_type' => 'assigned',
        ]);
        $this->assertDatabaseHas('support_ticket_events', [
            'ticket_id' => $ticket->id,
            'event_type' => 'resolved',
        ]);
    }

    public function test_crm_workspace_uses_plural_support_ticket_view_permission(): void
    {
        $page = (string) file_get_contents(app_path('Filament/Pages/CrmAgentWorkspacePage.php'));

        $this->assertStringContainsString("support_tickets.view", $page);
        $this->assertStringNotContainsString("support_ticket.view", $page);
    }
}
