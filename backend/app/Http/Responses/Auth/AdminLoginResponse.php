<?php

namespace App\Http\Responses\Auth;

use App\Services\AdminRedirectUrlResolver;
use Filament\Http\Responses\Auth\Contracts\LoginResponse as LoginResponseContract;
use Illuminate\Http\RedirectResponse;
use Livewire\Features\SupportRedirects\Redirector;

class AdminLoginResponse implements LoginResponseContract
{
    public function __construct(
        private readonly AdminRedirectUrlResolver $redirectUrlResolver,
    ) {}

    public function toResponse($request): RedirectResponse | Redirector
    {
        return redirect()->to($this->redirectUrlResolver->resolveAfterLogin());
    }
}
