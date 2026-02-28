<?php

namespace App\Services;

use Filament\Facades\Filament;
use Filament\Notifications\Notification;
use Illuminate\Support\Facades\Hash;

class AdminStepUpService
{
    private const SESSION_KEY_PREFIX = 'admin.step_up.confirmed_at.';

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
        if ($candidate === '' && $this->hasRecentStepUp((int) $admin->getAuthIdentifier())) {
            return true;
        }

        if ($candidate === '' || ! Hash::check($candidate, (string) $admin->password)) {
            Notification::make()
                ->title($failedTitle)
                ->danger()
                ->send();

            return false;
        }

        $this->markStepUpConfirmed((int) $admin->getAuthIdentifier());

        return true;
    }

    private function hasRecentStepUp(int $adminId): bool
    {
        $confirmedAt = session($this->stepUpSessionKey($adminId));
        if (! is_numeric($confirmedAt)) {
            return false;
        }

        $windowMinutes = max(1, (int) config('admin_security.reauth_minutes', 15));

        return now()->diffInMinutes(now()->setTimestamp((int) $confirmedAt)) <= $windowMinutes;
    }

    private function markStepUpConfirmed(int $adminId): void
    {
        session([$this->stepUpSessionKey($adminId) => now()->timestamp]);
    }

    private function stepUpSessionKey(int $adminId): string
    {
        return self::SESSION_KEY_PREFIX . $adminId;
    }
}
