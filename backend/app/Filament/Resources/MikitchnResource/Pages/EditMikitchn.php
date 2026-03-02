<?php

namespace App\Filament\Resources\MikitchnResource\Pages;

use App\Filament\Resources\MikitchnResource;
use App\Models\Order;
use Carbon\Carbon;
use Filament\Actions;
use Filament\Notifications\Notification;
use Filament\Resources\Pages\EditRecord;

class EditMikitchn extends EditRecord
{
    protected static string $resource = MikitchnResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\DeleteAction::make()
                ->requiresConfirmation()
                ->visible(fn (): bool => MikitchnResource::canDelete($this->record)),
        ];
    }

    protected function mutateFormDataBeforeSave(array $data): array
    {
        $currentStatus = (int) $this->record->status;
        $nextStatus = (int) ($data['status'] ?? $currentStatus);

        if ($currentStatus === $nextStatus) {
            return $data;
        }

        if ($nextStatus === 1) {
            $certificateStatus = (int) optional($this->record->certificate)->status;
            if ($certificateStatus !== 1) {
                Notification::make()
                    ->title('Cannot activate kitchen without an approved certificate.')
                    ->danger()
                    ->send();

                $this->halt();
            }
        }

        if ($nextStatus === 0) {
            $hasOpenBookings = $this->record->orders()
                ->whereIn('status', [Order::STATUS_REQUESTED, Order::STATUS_CONFIRMED])
                ->whereDate('delivery_date', '>=', Carbon::today()->toDateString())
                ->exists();

            if ($hasOpenBookings) {
                Notification::make()
                    ->title('Cannot deactivate kitchen with open upcoming bookings.')
                    ->danger()
                    ->send();

                $this->halt();
            }
        }

        return $data;
    }
}
