<?php

namespace App\Filament\Resources\MicookResource\Pages;

use App\Filament\Resources\MicookResource;
use Filament\Facades\Filament;
use Filament\Resources\Pages\EditRecord;
use Illuminate\Support\Facades\Hash;

class EditMicook extends EditRecord
{
    protected static string $resource = MicookResource::class;

    protected function mutateFormDataBeforeSave(array $data): array
    {
        $data['role_id'] = 2;

        if (! empty($data['password'])) {
            $data['password'] = Hash::make((string) $data['password']);
        } else {
            unset($data['password']);
        }

        if (array_key_exists('phone', $data)) {
            $data['phone'] = preg_replace('/\D+/', '', (string) $data['phone']);
        }

        if ((bool) ($data['suspended'] ?? false)) {
            $data['suspended_at'] ??= now();
            $data['suspended_by'] ??= Filament::auth()->id();
        } else {
            $data['suspended_at'] = null;
            $data['suspended_by'] = null;
            $data['suspension_reason'] = null;
        }

        unset($data['password_confirmation']);

        return $data;
    }
}
