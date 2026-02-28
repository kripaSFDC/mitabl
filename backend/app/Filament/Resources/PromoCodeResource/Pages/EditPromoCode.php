<?php

namespace App\Filament\Resources\PromoCodeResource\Pages;

use App\Filament\Resources\PromoCodeResource;
use App\Services\AdminAuditLogService;
use Filament\Actions;
use Filament\Resources\Pages\EditRecord;

class EditPromoCode extends EditRecord
{
    protected static string $resource = PromoCodeResource::class;

    protected function mutateFormDataBeforeSave(array $data): array
    {
        $data['code'] = strtoupper(trim((string) ($data['code'] ?? $this->record->code ?? '')));
        PromoCodeResource::validatePromoCodeWindow($data, $this->record);

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
        app(AdminAuditLogService::class)->log('promo_codes.edit', request(), [
            'promo_code_id' => $this->record->id,
            'code' => $this->record->code,
            'status' => (bool) $this->record->status,
        ]);
    }
}
