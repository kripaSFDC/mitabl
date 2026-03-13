<?php

namespace App\Filament\Resources\SupportTicketResource\Pages;

use App\Filament\Resources\SupportTicketResource;
use App\Services\SupportTicketService;
use Filament\Facades\Filament;
use Filament\Resources\Pages\EditRecord;
use Illuminate\Database\Eloquent\Model;

class EditSupportTicket extends EditRecord
{
    protected static string $resource = SupportTicketResource::class;

    protected function handleRecordUpdate(Model $record, array $data): Model
    {
        /** @var SupportTicketService $service */
        $service = app(SupportTicketService::class);

        return $service->updateFromAdminForm(
            $record,
            $data + [
                'change_reason' => 'Updated from admin ticket form.',
            ],
            Filament::auth()->id(),
            $this->record->updated_at?->toISOString()
        );
    }
}
