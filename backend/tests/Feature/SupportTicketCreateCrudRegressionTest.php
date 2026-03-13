<?php

namespace Tests\Feature;

use App\Models\AdminUser;
use App\Models\SupportTicket;
use App\Services\SupportTicketService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class SupportTicketCreateCrudRegressionTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_create_flow_can_persist_resolved_status_and_summary(): void
    {
        $admin = AdminUser::query()->create([
            'name' => 'Support Admin',
            'email' => 'create-admin@example.test',
            'password' => bcrypt('password123'),
            'is_active' => true,
        ]);

        $service = app(SupportTicketService::class);

        $result = $service->createTicket([
            'requester_email' => 'customer@example.test',
            'subject' => 'Need help now',
            'description' => 'Ticket body',
            'category' => SupportTicket::CATEGORY_GENERAL,
            'priority' => SupportTicket::PRIORITY_NORMAL,
            'assigned_to' => $admin->id,
            'actor_type' => 'admin',
            'actor_id' => $admin->id,
            'skip_duplicate_check' => true,
        ], 'admin_panel');

        $ticket = $service->updateFromAdminForm(
            $result['ticket'],
            [
                'requester_email' => 'customer@example.test',
                'subject' => 'Need help now',
                'description' => 'Ticket body',
                'category' => SupportTicket::CATEGORY_GENERAL,
                'priority' => SupportTicket::PRIORITY_NORMAL,
                'assigned_to' => $admin->id,
                'status' => SupportTicket::STATUS_RESOLVED,
                'resolution_summary' => 'Resolved during admin create flow.',
                'change_reason' => 'Initial state from admin create',
            ],
            $admin->id,
            $result['ticket']->updated_at?->toISOString()
        );

        $this->assertSame(SupportTicket::STATUS_RESOLVED, $ticket->status);
        $this->assertSame('Resolved during admin create flow.', $ticket->resolution_summary);
        $this->assertNotNull($ticket->resolved_at);
    }
}
