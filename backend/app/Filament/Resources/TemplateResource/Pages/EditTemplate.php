<?php

namespace App\Filament\Resources\TemplateResource\Pages;

use App\Filament\Resources\TemplateResource;
use App\Services\AdminAuditLogService;
use Filament\Actions;
use Filament\Facades\Filament;
use Filament\Resources\Pages\EditRecord;

class EditTemplate extends EditRecord
{
    protected static string $resource = TemplateResource::class;

    protected function mutateFormDataBeforeSave(array $data): array
    {
        if ((bool) $this->record->active) {
            throw \Illuminate\Validation\ValidationException::withMessages([
                'name' => 'Published templates are immutable. Create a new draft version instead.',
            ]);
        }

        $data['body'] = TemplateResource::decodeBodyJson((string) ($data['body_json'] ?? '{}'));
        $data['updated_by'] = Filament::auth()->id();
        unset($data['body_json']);

        return $data;
    }

    protected function getHeaderActions(): array
    {
        return [
            Actions\DeleteAction::make()->visible(false),
        ];
    }

    protected function afterSave(): void
    {
        app(AdminAuditLogService::class)->log('templates.edit', request(), [
            'template_name' => $this->record->name,
            'version' => $this->record->version,
            'channel' => $this->record->channel,
        ]);
    }
}
