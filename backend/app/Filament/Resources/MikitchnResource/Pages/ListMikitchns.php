<?php

namespace App\Filament\Resources\MikitchnResource\Pages;

use App\Filament\Resources\MikitchnResource;
use Filament\Resources\Pages\ListRecords;

class ListMikitchns extends ListRecords
{
    protected static string $resource = MikitchnResource::class;

    protected function getHeaderActions(): array
    {
        return [];
    }
}
