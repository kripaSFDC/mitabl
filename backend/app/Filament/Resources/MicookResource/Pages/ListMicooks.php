<?php

namespace App\Filament\Resources\MicookResource\Pages;

use App\Filament\Resources\MicookResource;
use Filament\Actions;
use Filament\Resources\Pages\ListRecords;

class ListMicooks extends ListRecords
{
    protected static string $resource = MicookResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\CreateAction::make(),
        ];
    }
}
