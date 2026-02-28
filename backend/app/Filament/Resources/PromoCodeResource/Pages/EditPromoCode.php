<?php

namespace App\Filament\Resources\PromoCodeResource\Pages;

use App\Filament\Resources\PromoCodeResource;
use App\Models\PromoCode;
use App\Services\AdminAuditLogService;
use Filament\Actions;
use Filament\Resources\Pages\EditRecord;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\DB;

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
        return DB::transaction(function () use ($record, $data): Model {
            PromoCode::query()
                ->whereRaw('LOWER(code) = ?', [strtolower((string) ($data['code'] ?? $record->code ?? ''))])
                ->where('status', 1)
                ->lockForUpdate()
                ->get(['id']);

            PromoCodeResource::validatePromoCodeWindow($data, $record);

            $record->update($data);

            return $record;
        });
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
