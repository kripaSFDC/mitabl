<?php

namespace App\Filament\Resources\PromoCodeResource\Pages;

use App\Filament\Resources\PromoCodeResource;
use App\Models\PromoCode;
use App\Services\AdminAuditLogService;
use Filament\Resources\Pages\CreateRecord;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use RuntimeException;

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
        $normalizedCode = strtoupper(trim((string) ($data['code'] ?? '')));

        $lock = Cache::lock('promo-code-window:' . strtolower($normalizedCode), 10);
        if (! $lock->get()) {
            throw new RuntimeException('Another promo code update is in progress. Please retry.');
        }

        try {
            return DB::transaction(function () use ($data, $normalizedCode): Model {
                PromoCode::query()
                    ->whereRaw('LOWER(code) = ?', [strtolower($normalizedCode)])
                    ->where('status', 1)
                    ->lockForUpdate()
                    ->get(['id']);

                PromoCodeResource::validatePromoCodeWindow($data, null);

                return PromoCode::query()->create($data);
            });
        } finally {
            $lock->release();
        }
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
