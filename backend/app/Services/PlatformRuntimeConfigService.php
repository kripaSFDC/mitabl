<?php

namespace App\Services;

use App\Models\PlatformSetting;
use Illuminate\Mail\MailManager;
use Illuminate\Support\Facades\Config;

class PlatformRuntimeConfigService
{
    private const PLATFORM_KEY_MAP = [
        'support.duplicate_window_minutes' => ['key' => 'support.duplicate_window_minutes', 'type' => 'integer', 'default' => 10],
        'support.duplicate_lock_ttl_seconds' => ['key' => 'support.duplicate_lock_ttl_seconds', 'type' => 'integer', 'default' => 12],
        'support.duplicate_lock_wait_seconds' => ['key' => 'support.duplicate_lock_wait_seconds', 'type' => 'integer', 'default' => 3],
        'support.reopen_window_hours' => ['key' => 'support.reopen_window_hours', 'type' => 'integer', 'default' => 72],
        'support.honeypot_field' => ['key' => 'support.honeypot_field', 'type' => 'string', 'default' => 'website'],
        'support.sla.default.first_response_minutes' => ['key' => 'support.sla.default.first_response_minutes', 'type' => 'integer', 'default' => 60],
        'support.sla.default.resolution_minutes' => ['key' => 'support.sla.default.resolution_minutes', 'type' => 'integer', 'default' => 1440],
        'support.sla.priority_overrides.low.first_response_minutes' => ['key' => 'support.sla.low.first_response_minutes', 'type' => 'integer', 'default' => 120],
        'support.sla.priority_overrides.low.resolution_minutes' => ['key' => 'support.sla.low.resolution_minutes', 'type' => 'integer', 'default' => 2880],
        'support.sla.priority_overrides.normal.first_response_minutes' => ['key' => 'support.sla.normal.first_response_minutes', 'type' => 'integer', 'default' => 60],
        'support.sla.priority_overrides.normal.resolution_minutes' => ['key' => 'support.sla.normal.resolution_minutes', 'type' => 'integer', 'default' => 1440],
        'support.sla.priority_overrides.high.first_response_minutes' => ['key' => 'support.sla.high.first_response_minutes', 'type' => 'integer', 'default' => 30],
        'support.sla.priority_overrides.high.resolution_minutes' => ['key' => 'support.sla.high.resolution_minutes', 'type' => 'integer', 'default' => 480],
        'support.sla.priority_overrides.urgent.first_response_minutes' => ['key' => 'support.sla.urgent.first_response_minutes', 'type' => 'integer', 'default' => 15],
        'support.sla.priority_overrides.urgent.resolution_minutes' => ['key' => 'support.sla.urgent.resolution_minutes', 'type' => 'integer', 'default' => 240],
        'admin_security.reauth_minutes' => ['key' => 'admin.security.reauth_minutes', 'type' => 'integer', 'default' => 15],
        'session.lifetime' => ['key' => 'session.lifetime_minutes', 'type' => 'integer', 'default' => 120],
        'session.expire_on_close' => ['key' => 'session.expire_on_close', 'type' => 'boolean', 'default' => false],
        'auth.otp.expire_minutes' => ['key' => 'otp.expire_minutes', 'type' => 'integer', 'default' => 10],
        'auth.otp.max_attempts' => ['key' => 'otp.max_attempts', 'type' => 'integer', 'default' => 5],
        'auth.otp.lock_minutes' => ['key' => 'otp.lock_minutes', 'type' => 'integer', 'default' => 15],
        'auth.otp.subject' => ['key' => 'otp.mail_subject', 'type' => 'string', 'default' => 'Testing Application OTP'],
        'stripe.api_keys.secret_key' => ['key' => 'stripe.secret_key', 'type' => 'string', 'default' => ''],
        'stripe.api_keys.publishable_key' => ['key' => 'stripe.publishable_key', 'type' => 'string', 'default' => ''],
        'stripe.client_id' => ['key' => 'stripe.client_id', 'type' => 'string', 'default' => ''],
        'stripe.redirect_uri' => ['key' => 'stripe.redirect_uri', 'type' => 'string', 'default' => '/api/stripe/callback'],
        'stripe.webhook_signing_secret' => ['key' => 'stripe.webhook_signing_secret', 'type' => 'string', 'default' => ''],
        'stripe.currency' => ['key' => 'stripe.currency', 'type' => 'string', 'default' => 'aud'],
        'stripe.connected_account_country' => ['key' => 'stripe.connected_account_country', 'type' => 'string', 'default' => 'AU'],
        'services.stripe.dashboard_base_url' => ['key' => 'stripe.dashboard_base_url', 'type' => 'string', 'default' => 'https://dashboard.stripe.com/payments'],
        'services.google_maps.api_key' => ['key' => 'integrations.google_maps.api_key', 'type' => 'string', 'default' => ''],
        'services.fcm.server_key' => ['key' => 'integrations.fcm.server_key', 'type' => 'string', 'default' => ''],
        'mail.default' => ['key' => 'email.mailer', 'type' => 'string', 'default' => 'smtp'],
        'mail.mailers.smtp.host' => ['key' => 'email.smtp.host', 'type' => 'string', 'default' => ''],
        'mail.mailers.smtp.port' => ['key' => 'email.smtp.port', 'type' => 'integer', 'default' => 587],
        'mail.mailers.smtp.encryption' => ['key' => 'email.smtp.encryption', 'type' => 'string', 'default' => 'tls'],
        'mail.mailers.smtp.username' => ['key' => 'email.smtp.username', 'type' => 'string', 'default' => ''],
        'mail.mailers.smtp.password' => ['key' => 'email.smtp.password', 'type' => 'string', 'default' => ''],
        'mail.from.address' => ['key' => 'email.from.address', 'type' => 'string', 'default' => 'noreply@mitabl.com'],
        'mail.from.name' => ['key' => 'email.from.name', 'type' => 'string', 'default' => 'MItabl'],
    ];

    public function apply(): void
    {
        $settings = $this->loadSettings();

        foreach (self::PLATFORM_KEY_MAP as $configPath => $meta) {
            $value = $this->resolveValue($settings, $meta);

            if ($configPath === 'stripe.redirect_uri' && str_starts_with((string) $value, '/')) {
                $baseUrl = rtrim((string) config('app.url', ''), '/');
                $value = $baseUrl !== '' ? $baseUrl . $value : $value;
            }

            Config::set($configPath, $value);
        }

        $this->refreshResolvedMailers();
    }

    /**
     * @return array<string, array<string, mixed>>
     */
    private function loadSettings(): array
    {
        try {
            return PlatformSetting::query()
                ->whereIn('key', array_map(fn (array $meta): string => $meta['key'], self::PLATFORM_KEY_MAP))
                ->get(['key', 'value'])
                ->mapWithKeys(fn (PlatformSetting $setting): array => [
                    (string) $setting->key => (array) ($setting->value ?? []),
                ])
                ->all();
        } catch (\Throwable) {
            return [];
        }
    }

    /**
     * @param array<string, array<string, mixed>> $settings
     * @param array<string, mixed> $meta
     */
    private function resolveValue(array $settings, array $meta): mixed
    {
        $payload = $settings[$meta['key']] ?? ['value' => $meta['default']];
        $raw = $payload['value'] ?? $meta['default'];

        return match ($meta['type']) {
            'integer' => (int) $raw,
            'boolean' => (bool) $raw,
            'string' => (string) $raw,
            default => $raw,
        };
    }

    private function refreshResolvedMailers(): void
    {
        if (! app()->resolved('mail.manager')) {
            return;
        }

        $mailManager = app('mail.manager');
        if ($mailManager instanceof MailManager) {
            $mailManager->forgetMailers();
        }

        app()->forgetInstance('mailer');
    }
}
