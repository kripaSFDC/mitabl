<?php

namespace App\Services;

use Filament\Facades\Filament;
use Filament\Notifications\Notification;
use Illuminate\Support\Facades\Hash;

class AdminStepUpService
{
    public function validateCurrentPassword(?string $password, string $failedTitle = 'Step-up authentication failed.'): bool
    {
        $admin = Filament::auth()->user();

        if (! $admin) {
            Notification::make()
                ->title('Admin authentication is required.')
                ->danger()
                ->send();

            return false;
        }

        $candidate = (string) $password;
        if ($candidate === '' || ! Hash::check($candidate, (string) $admin->password)) {
            Notification::make()
                ->title($failedTitle)
                ->danger()
                ->send();

            return false;
        }

        return true;
    }
}
