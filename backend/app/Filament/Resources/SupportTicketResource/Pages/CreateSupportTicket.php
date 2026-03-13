<?php

namespace App\Filament\Resources\SupportTicketResource\Pages;

use App\Filament\Resources\SupportTicketResource;
use App\Models\SupportTicket;
use App\Services\SupportTicketService;
use Filament\Facades\Filament;
use Filament\Resources\Pages\CreateRecord;
use Illuminate\Database\Eloquent\Model;

class CreateSupportTicket extends CreateRecord
{
    protected static string $resource = SupportTicketResource::class;

    protected function handleRecordCreation(array $data): Model
    {
        /** @var SupportTicketService $service */
        $service = app(SupportTicketService::class);

        $result = $service->createTicket([
            'user_id' => $data['user_id'] ?? null,
            'requester_name' => $data['requester_name'] ?? null,
            'requester_email' => $data['requester_email'] ?? '',
            'requester_phone' => $data['requester_phone'] ?? null,
            'subject' => $data['subject'] ?? 'General enquiry',
            'description' => $data['description'] ?? '',
            'category' => $data['category'] ?? 'general',
            'priority' => $data['priority'] ?? SupportTicket::PRIORITY_NORMAL,
            'order_id' => $data['order_id'] ?? null,
            'mikitchn_id' => $data['mikitchn_id'] ?? null,
            'attachments' => $data['attachments'] ?? [],
            'assigned_to' => $data['assigned_to'] ?? null,
            'actor_type' => 'admin',
            'actor_id' => Filament::auth()->id(),
            'skip_duplicate_check' => true,
        ], 'admin_panel');

        /** @var SupportTicket $ticket */
        $ticket = $result['ticket'];

        $ticket = $service->updateFromAdminForm(
            $ticket,
            [
                'user_id' => $data['user_id'] ?? null,
                'requester_name' => $data['requester_name'] ?? null,
                'requester_email' => $data['requester_email'] ?? '',
                'requester_phone' => $data['requester_phone'] ?? null,
                'subject' => $data['subject'] ?? 'General enquiry',
                'description' => $data['description'] ?? '',
                'category' => $data['category'] ?? SupportTicket::CATEGORY_GENERAL,
                'priority' => $data['priority'] ?? SupportTicket::PRIORITY_NORMAL,
                'status' => $data['status'] ?? SupportTicket::STATUS_OPEN,
                'assigned_to' => $data['assigned_to'] ?? null,
                'order_id' => $data['order_id'] ?? null,
                'mikitchn_id' => $data['mikitchn_id'] ?? null,
                'resolution_summary' => $data['resolution_summary'] ?? null,
                'change_reason' => 'Initial state from admin create',
            ],
            Filament::auth()->id(),
            $ticket->updated_at?->toISOString()
        );

        return $ticket;
    }
}
