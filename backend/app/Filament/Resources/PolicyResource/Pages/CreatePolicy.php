<?php

namespace App\Filament\Resources\PolicyResource\Pages;

use App\Filament\Resources\PolicyResource;
use App\Models\Policy;
use App\Models\PolicyChangeLog;
use App\Services\AdminAuditLogService;
use Filament\Facades\Filament;
use Filament\Resources\Pages\CreateRecord;
use Illuminate\Validation\ValidationException;

class CreatePolicy extends CreateRecord
{
    protected static string $resource = PolicyResource::class;

    protected function mutateFormDataBeforeCreate(array $data): array
    {
        try {
            $definition = json_decode((string) ($data['definition_json'] ?? ''), true, 512, JSON_THROW_ON_ERROR);
        } catch (\Throwable $throwable) {
            throw ValidationException::withMessages([
                'definition_json' => 'Policy definition must be valid JSON.',
            ]);
        }

        $name = trim((string) ($data['name'] ?? ''));
        $nextVersion = (int) Policy::query()->where('name', $name)->max('version') + 1;

        $data['version'] = $nextVersion;
        $data['definition'] = $definition;
        $data['created_by'] = Filament::auth()->id();
        $data['active'] = false;

        unset($data['definition_json']);

        return $data;
    }

    protected function afterCreate(): void
    {
        PolicyChangeLog::create([
            'policy_id' => $this->record->id,
            'action' => 'draft_created',
            'changed_by' => Filament::auth()->id(),
            'from_version' => null,
            'to_version' => $this->record->version,
            'change_summary' => 'Initial draft created.',
            'before_payload' => null,
            'after_payload' => $this->record->definition,
            'correlation_id' => null,
        ]);

        app(AdminAuditLogService::class)->log('policy.create', request(), [
            'policy_name' => $this->record->name,
            'version' => $this->record->version,
        ]);
    }
}
