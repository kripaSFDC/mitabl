<?php

namespace App\Filament\Resources\PreRegistrationResource\Pages;

use App\Filament\Resources\PreRegistrationResource;
use Filament\Actions;
use Filament\Resources\Pages\EditRecord;

class EditPreRegistration extends EditRecord
{
    protected static string $resource = PreRegistrationResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\DeleteAction::make(),
        ];
    }
}
