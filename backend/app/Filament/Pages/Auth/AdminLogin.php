<?php

namespace App\Filament\Pages\Auth;

use Filament\Forms\Components\Component;
use Filament\Pages\Auth\Login;

class AdminLogin extends Login
{
    /**
     * @var view-string
     */
    protected static string $view = 'filament.auth.admin-login';

    protected function getPasswordFormComponent(): Component
    {
        return parent::getPasswordFormComponent()
            ->revealable(true)
            ->inlineSuffix();
    }
}
