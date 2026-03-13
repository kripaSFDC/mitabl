<?php

namespace App\Filament\Pages\Auth;

use App\Services\AdminRedirectUrlResolver;
use Filament\Facades\Filament;
use Filament\Forms\Components\Component;
use Filament\Pages\Auth\Login;

class AdminLogin extends Login
{
    /**
     * @var view-string
     */
    protected static string $view = 'filament.auth.admin-login';

    public function mount(): void
    {
        if (Filament::auth()->check()) {
            redirect()->to(app(AdminRedirectUrlResolver::class)->resolveFromSession());

            return;
        }

        $this->form->fill();
    }

    protected function getPasswordFormComponent(): Component
    {
        return parent::getPasswordFormComponent()
            ->revealable(true)
            ->inlineSuffix();
    }
}
