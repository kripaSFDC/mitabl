<?php

namespace App\Services;

use App\Models\PlatformSetting;

class PlatformSettingRegistry
{
    public const DEFAULT_SETTINGS = [
        [
            'key' => 'onboarding.enabled',
            'value_type' => 'boolean',
            'description' => 'Master onboarding flow toggle.',
            'value' => ['value' => true],
        ],
        [
            'key' => 'onboarding.require_identity_verification',
            'value_type' => 'boolean',
            'description' => 'Require identity verification during onboarding.',
            'value' => ['value' => false],
        ],
        [
            'key' => 'maintenance.read_only_mode',
            'value_type' => 'boolean',
            'description' => 'Enable maintenance read-only mode for operational safety.',
            'value' => ['value' => false],
        ],
        [
            'key' => 'operations.synthetic_checks_enabled',
            'value_type' => 'boolean',
            'description' => 'Enable synthetic health checks scheduling and monitoring.',
            'value' => ['value' => true],
        ],
        [
            'key' => 'incident.degraded_mode',
            'value_type' => 'json',
            'description' => 'Incident-mode degraded operation controls.',
            'value' => ['enabled' => false, 'annotation' => null, 'postmortem_url' => null],
        ],
        [
            'key' => 'support.duplicate_window_minutes',
            'value_type' => 'integer',
            'description' => 'Duplicate ticket detection window in minutes.',
            'value' => ['value' => 10],
        ],
        [
            'key' => 'support.reopen_window_hours',
            'value_type' => 'integer',
            'description' => 'How long a resolved ticket can be reopened (hours).',
            'value' => ['value' => 72],
        ],
        [
            'key' => 'support.honeypot_field',
            'value_type' => 'string',
            'description' => 'Hidden field name used for bot/spam detection in support forms.',
            'value' => ['value' => 'website'],
        ],
        [
            'key' => 'support.sla.default.first_response_minutes',
            'value_type' => 'integer',
            'description' => 'Default first response SLA for uncategorized priorities (minutes).',
            'value' => ['value' => 60],
        ],
        [
            'key' => 'support.sla.default.resolution_minutes',
            'value_type' => 'integer',
            'description' => 'Default resolution SLA for uncategorized priorities (minutes).',
            'value' => ['value' => 1440],
        ],
        [
            'key' => 'support.sla.low.first_response_minutes',
            'value_type' => 'integer',
            'description' => 'Low-priority first response SLA (minutes).',
            'value' => ['value' => 120],
        ],
        [
            'key' => 'support.sla.low.resolution_minutes',
            'value_type' => 'integer',
            'description' => 'Low-priority resolution SLA (minutes).',
            'value' => ['value' => 2880],
        ],
        [
            'key' => 'support.sla.normal.first_response_minutes',
            'value_type' => 'integer',
            'description' => 'Normal-priority first response SLA (minutes).',
            'value' => ['value' => 60],
        ],
        [
            'key' => 'support.sla.normal.resolution_minutes',
            'value_type' => 'integer',
            'description' => 'Normal-priority resolution SLA (minutes).',
            'value' => ['value' => 1440],
        ],
        [
            'key' => 'support.sla.high.first_response_minutes',
            'value_type' => 'integer',
            'description' => 'High-priority first response SLA (minutes).',
            'value' => ['value' => 30],
        ],
        [
            'key' => 'support.sla.high.resolution_minutes',
            'value_type' => 'integer',
            'description' => 'High-priority resolution SLA (minutes).',
            'value' => ['value' => 480],
        ],
        [
            'key' => 'support.sla.urgent.first_response_minutes',
            'value_type' => 'integer',
            'description' => 'Urgent-priority first response SLA (minutes).',
            'value' => ['value' => 15],
        ],
        [
            'key' => 'support.sla.urgent.resolution_minutes',
            'value_type' => 'integer',
            'description' => 'Urgent-priority resolution SLA (minutes).',
            'value' => ['value' => 240],
        ],
        [
            'key' => 'admin.security.reauth_minutes',
            'value_type' => 'integer',
            'description' => 'Step-up re-authentication timeout for sensitive admin operations (minutes).',
            'value' => ['value' => 15],
        ],
        [
            'key' => 'session.lifetime_minutes',
            'value_type' => 'integer',
            'description' => 'Session idle timeout in minutes before logout.',
            'value' => ['value' => 120],
        ],
        [
            'key' => 'session.expire_on_close',
            'value_type' => 'boolean',
            'description' => 'Expire the session when browser is closed.',
            'value' => ['value' => false],
        ],
        [
            'key' => 'otp.expire_minutes',
            'value_type' => 'integer',
            'description' => 'OTP expiration window in minutes.',
            'value' => ['value' => 10],
        ],
        [
            'key' => 'otp.max_attempts',
            'value_type' => 'integer',
            'description' => 'Maximum invalid OTP attempts before temporary lockout.',
            'value' => ['value' => 5],
        ],
        [
            'key' => 'otp.lock_minutes',
            'value_type' => 'integer',
            'description' => 'OTP lockout duration in minutes after max failed attempts.',
            'value' => ['value' => 15],
        ],
        [
            'key' => 'otp.mail_subject',
            'value_type' => 'string',
            'description' => 'Email subject line used for OTP delivery messages.',
            'value' => ['value' => 'Testing Application OTP'],
        ],
        [
            'key' => 'stripe.secret_key',
            'value_type' => 'string',
            'description' => 'Stripe API secret key used for backend payment operations. Keep restricted to platform/security admins.',
            'value' => ['value' => ''],
        ],
        [
            'key' => 'stripe.publishable_key',
            'value_type' => 'string',
            'description' => 'Stripe publishable key used for front-end tokenization and setup intents.',
            'value' => ['value' => ''],
        ],
        [
            'key' => 'stripe.client_id',
            'value_type' => 'string',
            'description' => 'Stripe Connect client identifier for OAuth-based account linking.',
            'value' => ['value' => ''],
        ],
        [
            'key' => 'stripe.redirect_uri',
            'value_type' => 'string',
            'description' => 'Stripe OAuth redirect callback URL. Default resolves to {APP_URL}/api/stripe/callback.',
            'value' => ['value' => '/api/stripe/callback'],
        ],
        [
            'key' => 'stripe.dashboard_base_url',
            'value_type' => 'string',
            'description' => 'Base URL used for admin deep-links into Stripe dashboard payment views.',
            'value' => ['value' => 'https://dashboard.stripe.com/payments'],
        ],
        [
            'key' => 'stripe.webhook_signing_secret',
            'value_type' => 'string',
            'description' => 'Stripe webhook signing secret used to verify webhook signatures.',
            'value' => ['value' => ''],
        ],
        [
            'key' => 'stripe.currency',
            'value_type' => 'string',
            'description' => 'Default Stripe currency (ISO 4217 lowercase, for example aud, usd).',
            'value' => ['value' => 'aud'],
        ],
        [
            'key' => 'stripe.connected_account_country',
            'value_type' => 'string',
            'description' => 'Country code used when creating Stripe Connect external accounts (ISO 3166-1 alpha-2).',
            'value' => ['value' => 'AU'],
        ],
        [
            'key' => 'integrations.google_maps.api_key',
            'value_type' => 'string',
            'description' => 'Google Maps API key used by geocoding/location workflows.',
            'value' => ['value' => ''],
        ],
        [
            'key' => 'integrations.fcm.server_key',
            'value_type' => 'string',
            'description' => 'Firebase Cloud Messaging server key used to deliver push notifications.',
            'value' => ['value' => ''],
        ],
        [
            'key' => 'email.mailer',
            'value_type' => 'string',
            'description' => 'Default Laravel mailer (for example smtp, log, ses, mailgun).',
            'value' => ['value' => 'smtp'],
        ],
        [
            'key' => 'email.smtp.host',
            'value_type' => 'string',
            'description' => 'SMTP host used when email.mailer is set to smtp.',
            'value' => ['value' => ''],
        ],
        [
            'key' => 'email.smtp.port',
            'value_type' => 'integer',
            'description' => 'SMTP port used when email.mailer is set to smtp.',
            'value' => ['value' => 587],
        ],
        [
            'key' => 'email.smtp.encryption',
            'value_type' => 'string',
            'description' => 'SMTP encryption mode (for example tls, ssl, or empty for none).',
            'value' => ['value' => 'tls'],
        ],
        [
            'key' => 'email.smtp.username',
            'value_type' => 'string',
            'description' => 'SMTP username credential.',
            'value' => ['value' => ''],
        ],
        [
            'key' => 'email.smtp.password',
            'value_type' => 'string',
            'description' => 'SMTP password credential. Treat as secret.',
            'value' => ['value' => ''],
        ],
        [
            'key' => 'email.from.address',
            'value_type' => 'string',
            'description' => 'Global sender email address for outgoing messages.',
            'value' => ['value' => 'noreply@mitabl.com'],
        ],
        [
            'key' => 'email.from.name',
            'value_type' => 'string',
            'description' => 'Global sender display name for outgoing messages.',
            'value' => ['value' => 'MItabl'],
        ],
    ];

    /**
     * @return array<int, array<string, mixed>>
     */
    public function forAdminForm(): array
    {
        $existing = PlatformSetting::query()
            ->orderBy('key')
            ->get()
            ->keyBy(fn (PlatformSetting $setting): string => strtolower((string) $setting->key));

        $rows = [];

        foreach (self::DEFAULT_SETTINGS as $default) {
            $key = strtolower((string) $default['key']);
            $record = $existing->get($key);

            if ($record) {
                $rows[] = $this->toFormRow($record);
                $existing->forget($key);
                continue;
            }

            $rows[] = $this->toFormRow(new PlatformSetting([
                'id' => null,
                'key' => $default['key'],
                'value_type' => $default['value_type'],
                'description' => $default['description'],
                'value' => $default['value'],
            ]));
        }

        foreach ($existing->sortBy(fn (PlatformSetting $setting): string => strtolower((string) $setting->key)) as $setting) {
            $rows[] = $this->toFormRow($setting);
        }

        return $rows;
    }

    /**
     * @return array<string, mixed>
     */
    private function toFormRow(PlatformSetting $setting): array
    {
        return [
            'id' => $setting->id,
            'key' => $setting->key,
            'value_type' => $setting->value_type,
            'description' => $setting->description,
            'value_string' => $setting->value_type === 'string' ? (string) data_get($setting->value, 'value', '') : null,
            'value_integer' => $setting->value_type === 'integer' ? (int) data_get($setting->value, 'value', 0) : null,
            'value_boolean' => $setting->value_type === 'boolean' ? (bool) data_get($setting->value, 'value', false) : false,
            'value_json' => $setting->value_type === 'json'
                ? (json_encode($setting->value ?? [], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) ?: '{}')
                : '{}',
        ];
    }
}
