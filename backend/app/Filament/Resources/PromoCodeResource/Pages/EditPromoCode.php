<?php

namespace App\Filament\Resources\PromoCodeResource\Pages;

use App\Filament\Resources\PromoCodeResource;
use App\Models\PromoCode;
use App\Services\AdminAuditLogService;
use Filament\Actions;
use Filament\Resources\Pages\EditRecord;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use RuntimeException;

class EditPromoCode extends EditRecord
{
    protected static string $resource = PromoCodeResource::class;

    protected function mutateFormDataBeforeSave(array $data): array
    {
        $data['code'] = strtoupper(trim((string) ($data['code'] ?? $this->record->code ?? '')));
        PromoCodeResource::validatePromoCodeWindow($data, $this->record);

        return $data;
    }

    protected function handleRecordUpdate(Model $record, array $data): Model
    {
        $normalizedCode = strtoupper(trim((string) ($data['code'] ?? $record->code ?? '')));

        $lock = Cache::lock('promo-code-window:' . strtolower($normalizedCode), 10);
        if (! $lock->get()) {
            throw new RuntimeException('Another promo code update is in progress. Please retry.');
        }

        try {
            return DB::transaction(function () use ($record, $data, $normalizedCode): Model {
                PromoCode::query()
                    ->whereRaw('LOWER(code) = ?', [strtolower($normalizedCode)])
                    ->lockForUpdate()
                    ->get(['id']);

                $lockedRecord = PromoCode::query()->lockForUpdate()->findOrFail($record->getKey());

                PromoCodeResource::validatePromoCodeWindow($data, $lockedRecord);

                $lockedRecord->update($data);

                return $lockedRecord;
            });
        } finally {
            $lock->release();
        }
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
