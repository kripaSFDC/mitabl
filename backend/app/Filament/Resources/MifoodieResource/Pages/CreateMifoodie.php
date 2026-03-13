<?php

namespace App\Filament\Resources\MifoodieResource\Pages;

use App\Filament\Resources\MifoodieResource;
use Filament\Facades\Filament;
use Filament\Resources\Pages\CreateRecord;
use Illuminate\Support\Facades\Hash;

class CreateMifoodie extends CreateRecord
{
    protected static string $resource = MifoodieResource::class;

    protected function mutateFormDataBeforeCreate(array $data): array
    {
        $data['role_id'] = 3;

        if (! empty($data['password'])) {
            $data['password'] = Hash::make((string) $data['password']);
        }

        $data['phone'] = preg_replace('/\D+/', '', (string) ($data['phone'] ?? ''));

        if ((bool) ($data['suspended'] ?? false)) {
            $data['suspended_at'] = now();
            $data['suspended_by'] = Filament::auth()->id();
        } else {
            $data['suspended_at'] = null;
            $data['suspended_by'] = null;
            $data['suspension_reason'] = null;
        }

        unset($data['password_confirmation']);

        return $data;
    }
}
