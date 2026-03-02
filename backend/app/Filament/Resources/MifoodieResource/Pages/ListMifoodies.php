<?php

namespace App\Filament\Resources\MifoodieResource\Pages;

use App\Filament\Resources\MifoodieResource;
use Filament\Actions;
use Filament\Resources\Pages\ListRecords;

class ListMifoodies extends ListRecords
{
    protected static string $resource = MifoodieResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\CreateAction::make(),
        ];
    }
}
