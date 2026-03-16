<?php

namespace Tests\Unit;

use App\Models\PlatformSetting;
use App\Services\PlatformRuntimeConfigService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Mail\MailManager;
use Mockery;
use Tests\TestCase;

class PlatformRuntimeConfigServiceTest extends TestCase
{
    use RefreshDatabase;

    public function test_apply_maps_platform_settings_into_runtime_config_for_integrations(): void
    {
        foreach ([
            ['key' => 'stripe.secret_key', 'value' => ['value' => 'sk_test_runtime'], 'value_type' => 'string'],
            ['key' => 'stripe.publishable_key', 'value' => ['value' => 'pk_test_runtime'], 'value_type' => 'string'],
            ['key' => 'stripe.client_id', 'value' => ['value' => 'ca_runtime'], 'value_type' => 'string'],
            ['key' => 'stripe.redirect_uri', 'value' => ['value' => '/api/stripe/runtime-callback'], 'value_type' => 'string'],
            ['key' => 'stripe.dashboard_base_url', 'value' => ['value' => 'https://dashboard.stripe.com/test/payments'], 'value_type' => 'string'],
            ['key' => 'stripe.webhook_signing_secret', 'value' => ['value' => 'whsec_runtime'], 'value_type' => 'string'],
            ['key' => 'stripe.currency', 'value' => ['value' => 'usd'], 'value_type' => 'string'],
            ['key' => 'stripe.connected_account_country', 'value' => ['value' => 'US'], 'value_type' => 'string'],
            ['key' => 'integrations.google_maps.api_key', 'value' => ['value' => 'gmaps-runtime'], 'value_type' => 'string'],
            ['key' => 'email.mailer', 'value' => ['value' => 'smtp'], 'value_type' => 'string'],
            ['key' => 'email.smtp.host', 'value' => ['value' => 'smtp.runtime.test'], 'value_type' => 'string'],
            ['key' => 'email.smtp.port', 'value' => ['value' => 2525], 'value_type' => 'integer'],
            ['key' => 'email.smtp.encryption', 'value' => ['value' => 'ssl'], 'value_type' => 'string'],
            ['key' => 'email.smtp.username', 'value' => ['value' => 'runtime-user'], 'value_type' => 'string'],
            ['key' => 'email.smtp.password', 'value' => ['value' => 'runtime-pass'], 'value_type' => 'string'],
            ['key' => 'email.from.address', 'value' => ['value' => 'platform@example.test'], 'value_type' => 'string'],
            ['key' => 'email.from.name', 'value' => ['value' => 'Platform Runtime'], 'value_type' => 'string'],
        ] as $setting) {
            PlatformSetting::query()->create($setting + ['version' => 1]);
        }

        config(['app.url' => 'https://admin.example.test']);

        app(PlatformRuntimeConfigService::class)->apply();

        $this->assertSame('sk_test_runtime', config('stripe.api_keys.secret_key'));
        $this->assertSame('pk_test_runtime', config('stripe.api_keys.publishable_key'));
        $this->assertSame('ca_runtime', config('stripe.client_id'));
        $this->assertSame('https://admin.example.test/api/stripe/runtime-callback', config('stripe.redirect_uri'));
        $this->assertSame('https://dashboard.stripe.com/test/payments', config('services.stripe.dashboard_base_url'));
        $this->assertSame('whsec_runtime', config('stripe.webhook_signing_secret'));
        $this->assertSame('usd', config('stripe.currency'));
        $this->assertSame('US', config('stripe.connected_account_country'));
        $this->assertSame('gmaps-runtime', config('services.google_maps.api_key'));
        $this->assertSame('smtp', config('mail.default'));
        $this->assertSame('smtp.runtime.test', config('mail.mailers.smtp.host'));
        $this->assertSame(2525, config('mail.mailers.smtp.port'));
        $this->assertSame('ssl', config('mail.mailers.smtp.encryption'));
        $this->assertSame('runtime-user', config('mail.mailers.smtp.username'));
        $this->assertSame('runtime-pass', config('mail.mailers.smtp.password'));
        $this->assertSame('platform@example.test', config('mail.from.address'));
        $this->assertSame('Platform Runtime', config('mail.from.name'));
    }

    public function test_apply_forgets_resolved_mailers_so_smtp_changes_take_effect_immediately(): void
    {
        PlatformSetting::query()->create([
            'key' => 'email.mailer',
            'value' => ['value' => 'smtp'],
            'value_type' => 'string',
            'version' => 1,
        ]);

        PlatformSetting::query()->create([
            'key' => 'email.smtp.host',
            'value' => ['value' => 'smtp.after-save.test'],
            'value_type' => 'string',
            'version' => 1,
        ]);

        $manager = Mockery::mock(MailManager::class);
        $manager->shouldReceive('forgetMailers')->once();

        app()->instance('mail.manager', $manager);
        app()->instance('mailer', (object) ['cached' => true]);
        app('mail.manager');

        app(PlatformRuntimeConfigService::class)->apply();

        $this->assertSame('smtp.after-save.test', config('mail.mailers.smtp.host'));
    }

    public function test_apply_switches_to_log_mailer_when_smtp_host_is_missing(): void
    {
        PlatformSetting::query()->create([
            'key' => 'email.mailer',
            'value' => ['value' => 'smtp'],
            'value_type' => 'string',
            'version' => 1,
        ]);

        PlatformSetting::query()->create([
            'key' => 'email.smtp.host',
            'value' => ['value' => '   '],
            'value_type' => 'string',
            'version' => 1,
        ]);

        app(PlatformRuntimeConfigService::class)->apply();

        $this->assertSame('log', config('mail.default'));
    }
}
