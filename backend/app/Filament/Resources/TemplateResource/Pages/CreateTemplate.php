<?php

namespace App\Filament\Resources\TemplateResource\Pages;

use App\Filament\Resources\TemplateResource;
use App\Models\Template;
use App\Services\AdminAuditLogService;
use Filament\Facades\Filament;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\DB;
use Filament\Resources\Pages\CreateRecord;

class CreateTemplate extends CreateRecord
{
    protected static string $resource = TemplateResource::class;

    protected function mutateFormDataBeforeCreate(array $data): array
    {
        $data['body'] = TemplateResource::decodeBodyJson((string) ($data['body_json'] ?? '{}'));
        $data['name'] = trim((string) ($data['name'] ?? ''));
        $data['created_by'] = Filament::auth()->id();
        $data['updated_by'] = Filament::auth()->id();
        $data['active'] = false;

        unset($data['body_json']);

        return $data;
    }

    protected function handleRecordCreation(array $data): Model
    {
        return DB::transaction(function () use ($data): Model {
            Template::query()
                ->where('name', (string) $data['name'])
                ->lockForUpdate()
                ->get(['id', 'version']);

            $data['version'] = (int) Template::query()
                    ->where('name', (string) $data['name'])
                    ->max('version') + 1;

            return Template::query()->create($data);
        });
    }

    protected function afterCreate(): void
    {
        app(AdminAuditLogService::class)->log('templates.create', request(), [
            'template_name' => $this->record->name,
            'version' => $this->record->version,
            'channel' => $this->record->channel,
        ]);
    }
}
