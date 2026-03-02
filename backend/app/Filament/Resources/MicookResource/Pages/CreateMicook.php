<?php

namespace App\Filament\Resources\MicookResource\Pages;

use App\Filament\Resources\MicookResource;
use Filament\Resources\Pages\CreateRecord;
use Illuminate\Support\Facades\Hash;

class CreateMicook extends CreateRecord
{
    protected static string $resource = MicookResource::class;

    protected function mutateFormDataBeforeCreate(array $data): array
    {
        $data['role_id'] = 2;

        if (! empty($data['password'])) {
            $data['password'] = Hash::make((string) $data['password']);
        }

        $data['phone'] = preg_replace('/\D+/', '', (string) ($data['phone'] ?? ''));
        unset($data['password_confirmation']);

        return $data;
    }
}
