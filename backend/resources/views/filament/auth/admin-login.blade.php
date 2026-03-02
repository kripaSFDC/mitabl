<x-filament-panels::page.simple>
    <style>
        .fi-simple-layout {
            background: linear-gradient(180deg, #f8fbff 0%, #eef5fb 100%);
            font-family: itc-avant-garde-gothic-pro, sans-serif;
        }

        .fi-simple-main {
            max-width: 1240px !important;
            background: transparent !important;
            box-shadow: none !important;
            padding: 1.5rem !important;
            ring: 0 !important;
        }

        .fi-simple-header {
            display: none !important;
        }

        .mitabl-admin-login {
            display: grid;
            grid-template-columns: minmax(320px, 1fr) minmax(420px, 560px);
            border-radius: 24px;
            overflow: hidden;
            box-shadow: 0 16px 40px rgba(0, 34, 56, 0.18);
            background: #ffffff;
        }

        .mitabl-admin-login__hero {
            position: relative;
            background:
                linear-gradient(145deg, rgba(0, 113, 188, 0.94), rgba(0, 90, 149, 0.94)),
                url('https://mitabl.com/frontend/background.jpg') center/cover no-repeat;
            color: #ffffff;
            padding: 3rem;
            display: flex;
            flex-direction: column;
            justify-content: space-between;
            min-height: 540px;
        }

        .mitabl-admin-login__brand img {
            width: 150px;
            max-width: 100%;
        }

        .mitabl-admin-login__title {
            margin: 1.25rem 0 0.75rem;
            font-size: 2.1rem;
            font-weight: 700;
            line-height: 1.2;
            color: #ffffff;
        }

        .mitabl-admin-login__copy {
            margin: 0;
            font-size: 1rem;
            line-height: 1.65;
            color: rgba(255, 255, 255, 0.92);
        }

        .mitabl-admin-login__hero-link {
            display: inline-flex;
            align-items: center;
            gap: 0.45rem;
            color: #ffffff;
            font-weight: 600;
            text-decoration: none;
            margin-top: 1.25rem;
            border-bottom: 2px solid rgba(255, 255, 255, 0.35);
            width: fit-content;
            transition: border-color 0.15s ease;
        }

        .mitabl-admin-login__hero-link:hover {
            border-color: #ffffff;
        }

        .mitabl-admin-login__form {
            padding: 2.5rem;
            background: #ffffff;
        }

        .mitabl-admin-login__form h1 {
            margin: 0;
            color: #1f2937;
            font-size: 1.75rem;
            line-height: 1.2;
        }

        .mitabl-admin-login__form p {
            margin: 0.75rem 0 1.5rem;
            color: #6b7280;
            font-size: 0.95rem;
            line-height: 1.5;
        }

        .mitabl-admin-login input[type='email'],
        .mitabl-admin-login input[type='password'],
        .mitabl-admin-login input[type='text'] {
            border-radius: 10px !important;
            border-color: #d1d5db !important;
        }

        .mitabl-admin-login .fi-input-wrp {
            min-height: 2.625rem !important;
        }

        .mitabl-admin-login .fi-input-wrp input {
            min-height: 2.625rem !important;
            font-size: 0.95rem !important;
            padding-top: 0.5rem !important;
            padding-bottom: 0.5rem !important;
        }

        .mitabl-admin-login .fi-input-wrp:has(input[type='password']),
        .mitabl-admin-login .fi-input-wrp:has(input[autocomplete='current-password']) {
            position: relative;
        }

        .mitabl-admin-login .fi-input-wrp:has(input[type='password']) .fi-input-wrp-suffix,
        .mitabl-admin-login .fi-input-wrp:has(input[type='password']) [class*='suffix'],
        .mitabl-admin-login .fi-input-wrp:has(input[autocomplete='current-password']) .fi-input-wrp-suffix,
        .mitabl-admin-login .fi-input-wrp:has(input[autocomplete='current-password']) [class*='suffix'] {
            position: absolute;
            inset-inline-end: 0.625rem;
            top: 50%;
            transform: translateY(-50%);
            z-index: 10;
        }

        .mitabl-admin-login .fi-input-wrp:has(input[type='password']) input,
        .mitabl-admin-login .fi-input-wrp:has(input[autocomplete='current-password']) input {
            padding-inline-end: 2.5rem !important;
        }

        .mitabl-admin-login .fi-btn[type='submit'] {
            background-color: #0071bc !important;
            border-color: #0071bc !important;
            color: #ffffff !important;
            border-radius: 999px !important;
            width: 100% !important;
            min-height: 2.75rem;
            font-size: 0.95rem !important;
            font-weight: 700;
        }

        .mitabl-admin-login .fi-btn[type='submit']:hover {
            background-color: #005a95 !important;
            border-color: #005a95 !important;
        }

        .mitabl-admin-login .fi-btn[type='submit'] svg,
        .mitabl-admin-login .fi-btn[type='submit'] .animate-spin {
            width: 1rem !important;
            height: 1rem !important;
        }

        @media (max-width: 960px) {
            .fi-simple-main {
                padding: 1rem !important;
            }

            .mitabl-admin-login {
                grid-template-columns: 1fr;
            }

            .mitabl-admin-login__hero {
                min-height: auto;
                padding: 2rem;
            }

            .mitabl-admin-login__form {
                padding: 2rem 1.5rem;
            }
        }
    </style>

    <div class="mitabl-admin-login">
        <section class="mitabl-admin-login__hero">
            <div>
                <div class="mitabl-admin-login__brand">
                    <img src="https://mitabl.com/frontend/images/logo.png" alt="mitabl">
                </div>
                <h2 class="mitabl-admin-login__title">mitabl platform operations</h2>
                <p class="mitabl-admin-login__copy">
                    Secure access for operations, customer support, and governance teams.
                    Continue with your admin account to manage platform workflows.
                </p>
            </div>
            <a class="mitabl-admin-login__hero-link" href="{{ url('/') }}">
                View public website
            </a>
        </section>

        <section class="mitabl-admin-login__form">
            <h1>mitabl Team Login</h1>
            <p>Use your assigned admin email and password.</p>

            {{ \Filament\Support\Facades\FilamentView::renderHook(\Filament\View\PanelsRenderHook::AUTH_LOGIN_FORM_BEFORE, scopes: $this->getRenderHookScopes()) }}

            <x-filament-panels::form id="form" wire:submit="authenticate">
                {{ $this->form }}

                <x-filament-panels::form.actions
                    :actions="$this->getCachedFormActions()"
                    :full-width="$this->hasFullWidthFormActions()"
                />
            </x-filament-panels::form>

            {{ \Filament\Support\Facades\FilamentView::renderHook(\Filament\View\PanelsRenderHook::AUTH_LOGIN_FORM_AFTER, scopes: $this->getRenderHookScopes()) }}
        </section>
    </div>
</x-filament-panels::page.simple>
