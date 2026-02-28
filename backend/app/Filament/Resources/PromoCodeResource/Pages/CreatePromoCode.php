<?php

namespace App\Filament\Resources\PromoCodeResource\Pages;

use App\Filament\Resources\PromoCodeResource;
use App\Services\AdminAuditLogService;
use Filament\Resources\Pages\CreateRecord;

class CreatePromoCode extends CreateRecord
{
    protected static string $resource = PromoCodeResource::class;

    protected function mutateFormDataBeforeCreate(array $data): array
    {
        $data['code'] = strtoupper(trim((string) ($data['code'] ?? '')));
        PromoCodeResource::validatePromoCodeWindow($data, null);

        return $data;
    }

    protected function afterCreate(): void
    {
        app(AdminAuditLogService::class)->log('promo_codes.create', request(), [
            'promo_code_id' => $this->record->id,
            'code' => $this->record->code,
            'status' => (bool) $this->record->status,
        ]);
    }
}
