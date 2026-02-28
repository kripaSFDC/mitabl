<?php

namespace App\Filament\Resources\MikitchnResource\Pages;

use App\Filament\Resources\MikitchnResource;
use Filament\Actions;
use Filament\Resources\Pages\EditRecord;

class EditMikitchn extends EditRecord
{
    protected static string $resource = MikitchnResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\DeleteAction::make()->visible(false),
        ];
    }
}
