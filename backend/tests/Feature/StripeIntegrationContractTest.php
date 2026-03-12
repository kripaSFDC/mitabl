<?php

namespace Tests\Feature;

use Tests\TestCase;

class StripeIntegrationContractTest extends TestCase
{
    public function test_platform_registry_contains_admin_managed_stripe_runtime_keys(): void
    {
        $registry = file_get_contents(app_path('Services/PlatformSettingRegistry.php'));
        $this->assertIsString($registry);

        $this->assertStringContainsString("'stripe.secret_key'", $registry);
        $this->assertStringContainsString("'stripe.publishable_key'", $registry);
        $this->assertStringContainsString("'stripe.client_id'", $registry);
        $this->assertStringContainsString("'stripe.redirect_uri'", $registry);
        $this->assertStringContainsString("'stripe.dashboard_base_url'", $registry);
        $this->assertStringContainsString("'stripe.webhook_signing_secret'", $registry);
        $this->assertStringContainsString("'stripe.currency'", $registry);
        $this->assertStringContainsString("'stripe.connected_account_country'", $registry);
        $this->assertStringContainsString("'integrations.google_maps.api_key'", $registry);
        $this->assertStringContainsString("'email.mailer'", $registry);
        $this->assertStringContainsString("'email.smtp.host'", $registry);
        $this->assertStringContainsString("'email.smtp.port'", $registry);
        $this->assertStringContainsString("'email.smtp.encryption'", $registry);
        $this->assertStringContainsString("'email.smtp.username'", $registry);
        $this->assertStringContainsString("'email.smtp.password'", $registry);
        $this->assertStringContainsString("'email.from.address'", $registry);
        $this->assertStringContainsString("'email.from.name'", $registry);
    }

    public function test_runtime_config_service_maps_new_stripe_keys(): void
    {
        $runtime = file_get_contents(app_path('Services/PlatformRuntimeConfigService.php'));
        $this->assertIsString($runtime);

        $this->assertStringContainsString("'stripe.api_keys.secret_key'", $runtime);
        $this->assertStringContainsString("'stripe.api_keys.publishable_key'", $runtime);
        $this->assertStringContainsString("'stripe.client_id'", $runtime);
        $this->assertStringContainsString("'stripe.redirect_uri'", $runtime);
        $this->assertStringContainsString("'services.stripe.dashboard_base_url'", $runtime);
        $this->assertStringContainsString("'stripe.webhook_signing_secret'", $runtime);
        $this->assertStringContainsString("'stripe.currency'", $runtime);
        $this->assertStringContainsString("'stripe.connected_account_country'", $runtime);
        $this->assertStringContainsString("'services.google_maps.api_key'", $runtime);
        $this->assertStringContainsString("'mail.default'", $runtime);
        $this->assertStringContainsString("'mail.mailers.smtp.host'", $runtime);
        $this->assertStringContainsString("'mail.mailers.smtp.port'", $runtime);
        $this->assertStringContainsString("'mail.mailers.smtp.encryption'", $runtime);
        $this->assertStringContainsString("'mail.mailers.smtp.username'", $runtime);
        $this->assertStringContainsString("'mail.mailers.smtp.password'", $runtime);
        $this->assertStringContainsString("'mail.from.address'", $runtime);
        $this->assertStringContainsString("'mail.from.name'", $runtime);
    }

    public function test_api_routes_expose_stripe_webhook_endpoint(): void
    {
        $routes = file_get_contents(base_path('routes/api.php'));
        $this->assertIsString($routes);

        $this->assertStringContainsString("Route::post('stripe/webhook'", $routes);
    }
}
