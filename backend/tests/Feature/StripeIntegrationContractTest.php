<?php

namespace Tests\Feature;

use Tests\TestCase;

class StripeIntegrationContractTest extends TestCase
{
    public function test_platform_registry_contains_admin_managed_stripe_runtime_keys(): void
    {
        $registry = file_get_contents(app_path('Services/PlatformSettingRegistry.php'));
        $this->assertIsString($registry);

        $this->assertStringContainsString("'stripe.webhook_signing_secret'", $registry);
        $this->assertStringContainsString("'stripe.currency'", $registry);
        $this->assertStringContainsString("'stripe.connected_account_country'", $registry);
    }

    public function test_runtime_config_service_maps_new_stripe_keys(): void
    {
        $runtime = file_get_contents(app_path('Services/PlatformRuntimeConfigService.php'));
        $this->assertIsString($runtime);

        $this->assertStringContainsString("'stripe.webhook_signing_secret'", $runtime);
        $this->assertStringContainsString("'stripe.currency'", $runtime);
        $this->assertStringContainsString("'stripe.connected_account_country'", $runtime);
    }

    public function test_api_routes_expose_stripe_webhook_endpoint(): void
    {
        $routes = file_get_contents(base_path('routes/api.php'));
        $this->assertIsString($routes);

        $this->assertStringContainsString("Route::post('stripe/webhook'", $routes);
    }
}
