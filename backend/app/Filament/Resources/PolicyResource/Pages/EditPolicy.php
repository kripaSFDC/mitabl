<?php

namespace App\Filament\Resources\PolicyResource\Pages;

use App\Filament\Resources\PolicyResource;
use App\Models\PolicyChangeLog;
use App\Services\AdminAuditLogService;
use App\Services\PolicyDefinitionValidator;
use Filament\Facades\Filament;
use Filament\Resources\Pages\EditRecord;
use Illuminate\Validation\ValidationException;

class EditPolicy extends EditRecord
{
    protected static string $resource = PolicyResource::class;

    private array|null $beforeDefinition = null;

    protected function mutateFormDataBeforeSave(array $data): array
    {
        if ($this->record->active) {
            throw ValidationException::withMessages([
                'name' => 'Active policy versions are immutable. Create a new draft version instead.',
            ]);
        }

        try {
            $definition = json_decode((string) ($data['definition_json'] ?? ''), true, 512, JSON_THROW_ON_ERROR);
        } catch (\Throwable $throwable) {
            throw ValidationException::withMessages([
                'definition_json' => 'Policy definition must be valid JSON.',
            ]);
        }
        app(PolicyDefinitionValidator::class)->validateOrFail((string) $this->record->name, (array) $definition);

        $data['definition'] = $definition;
        $this->beforeDefinition = $this->record->definition;
        unset($data['definition_json']);

        return $data;
    }

    protected function afterSave(): void
    {
        PolicyChangeLog::create([
            'policy_id' => $this->record->id,
            'action' => 'draft_updated',
            'changed_by' => Filament::auth()->id(),
            'from_version' => $this->record->version,
            'to_version' => $this->record->version,
            'change_summary' => 'Draft updated from edit screen.',
            'before_payload' => $this->beforeDefinition,
            'after_payload' => $this->record->definition,
            'correlation_id' => null,
        ]);

        app(AdminAuditLogService::class)->log('policy.edit', request(), [
            'policy_name' => $this->record->name,
            'version' => $this->record->version,
        ]);
    }
}
