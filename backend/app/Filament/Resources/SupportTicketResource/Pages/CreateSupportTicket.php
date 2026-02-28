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

        if (! empty($data['assigned_to'])) {
            $ticket = $service->assignTicket(
                $ticket,
                (int) $data['assigned_to'],
                'Initial assignment from admin create',
                Filament::auth()->id()
            );
        }

        $targetStatus = (string) ($data['status'] ?? SupportTicket::STATUS_OPEN);
        if ($targetStatus !== $ticket->status) {
            try {
                $ticket = $service->transitionStatus(
                    $ticket,
                    $targetStatus,
                    'Initial status from admin create',
                    Filament::auth()->id()
                );
            } catch (\Throwable $throwable) {
                // Keep created ticket if requested transition is invalid.
            }
        }

        return $ticket;
    }
}
