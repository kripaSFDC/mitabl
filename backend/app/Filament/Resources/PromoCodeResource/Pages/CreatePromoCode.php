<?php

namespace App\Filament\Resources\PromoCodeResource\Pages;

use App\Filament\Resources\PromoCodeResource;
use App\Models\PromoCode;
use App\Services\AdminAuditLogService;
use Filament\Resources\Pages\CreateRecord;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\DB;

class CreatePromoCode extends CreateRecord
{
    protected static string $resource = PromoCodeResource::class;

    protected function mutateFormDataBeforeCreate(array $data): array
    {
        $data['code'] = strtoupper(trim((string) ($data['code'] ?? '')));
        PromoCodeResource::validatePromoCodeWindow($data, null);

        return $data;
    }

    protected function handleRecordCreation(array $data): Model
    {
        return DB::transaction(function () use ($data): Model {
            PromoCode::query()
                ->whereRaw('LOWER(code) = ?', [strtolower((string) ($data['code'] ?? ''))])
                ->where('status', 1)
                ->lockForUpdate()
                ->get(['id']);

            PromoCodeResource::validatePromoCodeWindow($data, null);

            return PromoCode::query()->create($data);
        });
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
