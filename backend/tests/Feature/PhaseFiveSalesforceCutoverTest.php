<?php

namespace Tests\Feature;

use Illuminate\Support\Facades\Log;
use Tests\TestCase;

class PhaseFiveSalesforceCutoverTest extends TestCase
{
    public function test_salesforce_runtime_components_are_removed(): void
    {
        $apiRoutes = (string) file_get_contents(base_path('routes/api.php'));
        $kernel = (string) file_get_contents(app_path('Http/Kernel.php'));
        $events = (string) file_get_contents(app_path('Providers/EventServiceProvider.php'));
        $services = (string) file_get_contents(config_path('services.php'));
        $crmController = (string) file_get_contents(app_path('Http/Controllers/Api/WebApiToCurlController.php'));

        $this->assertStringContainsString("Route::post('mobcontact'", $apiRoutes);
        $this->assertStringNotContainsString('sales/mifoodi', $apiRoutes);
        $this->assertStringNotContainsString('/kitchen/{kitchen_id}/certificate', $apiRoutes);
        $this->assertStringNotContainsString("['salesforce']", $apiRoutes);

        $this->assertStringNotContainsString("'salesforce' =>", $kernel);
        $this->assertStringNotContainsString('KitchenVerifiedToSales::class', $events);
        $this->assertStringNotContainsString("'salesforce' => [", $services);
        $this->assertStringContainsString('Deprecation', $crmController);
        $this->assertStringContainsString('support.mobcontact.alias_used', $crmController);

        $this->assertFileDoesNotExist(app_path('Http/Middleware/SalesForce.php'));
        $this->assertFileDoesNotExist(app_path('Http/Controllers/Api/Sales/SalesForceController.php'));
        $this->assertFileDoesNotExist(app_path('Listeners/KitchenVerifiedToSales.php'));
        $this->assertFileDoesNotExist(app_path('Models/SalesKitchen.php'));
        $this->assertFileDoesNotExist(app_path('Events/KitchenVerified.php'));
    }

    public function test_salesforce_persistence_and_secret_templates_are_removed(): void
    {
        $envExample = (string) file_get_contents(base_path('.env.example'));
        $migration = (string) file_get_contents(database_path('migrations/2026_02_28_000016_drop_sales_kitchens_table.php'));
        $mikitchnModel = (string) file_get_contents(app_path('Models/Mikitchn.php'));

        $this->assertStringNotContainsString('SALESFORCE_', $envExample);
        $this->assertStringContainsString("Schema::dropIfExists('sales_kitchens')", $migration);
        $this->assertStringNotContainsString('saleskitchen(', $mikitchnModel);

        $deployFiles = [
            base_path('../deploy/environments/backend-api.env'),
            base_path('../deploy/environments/dev/backend-api.env'),
            base_path('../deploy/environments/staging/backend-api.env'),
            base_path('../deploy/environments/prod/backend-api.env'),
        ];

        foreach ($deployFiles as $file) {
            $this->assertStringNotContainsString('SALESFORCE_', (string) file_get_contents($file));
        }
    }

    public function test_phase_five_release_scaffolding_exists_for_ops_split(): void
    {
        $phase0Compose = (string) file_get_contents(base_path('../deploy/docker-compose.phase0.yml'));
        $nginxConfig = (string) file_get_contents(base_path('../deploy/nginx/mitabl.phase0.conf'));
        $consoleKernel = (string) file_get_contents(app_path('Console/Kernel.php'));
        $reconciliationCommand = (string) file_get_contents(app_path('Console/Commands/PhaseFiveCutoverReconciliationCommand.php'));
        $ciWorkflow = (string) file_get_contents(base_path('../.github/workflows/ci-cd.yml'));

        $this->assertStringContainsString('ops-admin:', $phase0Compose);
        $this->assertStringContainsString('queue-worker:', $phase0Compose);
        $this->assertStringContainsString('healthcheck:', $phase0Compose);
        $this->assertStringContainsString('location /admin/', $nginxConfig);
        $this->assertStringContainsString('location /api/', $nginxConfig);
        $this->assertStringContainsString('Strict-Transport-Security', $nginxConfig);
        $this->assertStringContainsString('PhaseFiveCutoverReconciliationCommand', $consoleKernel);
        $this->assertStringContainsString('phase5:cutover:reconcile', $reconciliationCommand);
        $this->assertStringContainsString('secret-scan:', $ciWorkflow);
    }

    public function test_contract_parity_replacements_exist_in_admin_resources(): void
    {
        $this->assertFileExists(app_path('Filament/Resources/CertificateResource.php'));
        $this->assertFileExists(app_path('Filament/Resources/UserResource.php'));
    }

    public function test_mobcontact_alias_includes_deprecation_headers_and_redacted_log_context(): void
    {
        Log::spy();

        $response = $this->postJson('/api/mobcontact', [
            'SuppliedEmail' => 'Legacy-Ticket@Example.com',
            'Subject' => 'Legacy compatibility path',
            'Description' => 'Honeypot flow should not persist but must emit alias headers.',
            'website' => 'https://bot.example.com',
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('isSuccess', true)
            ->assertHeader('Deprecation', 'true')
            ->assertHeader('Link', '<' . url('/api/support/ticket') . '>; rel="successor-version"');

        $this->assertNotNull($response->headers->get('Sunset'));

        Log::shouldHaveReceived('info')
            ->withArgs(function (string $message, array $context): bool {
                return $message === 'support.mobcontact.alias_used'
                    && ($context['email_hash'] ?? null) === hash('sha256', 'legacy-ticket@example.com')
                    && ($context['honeypot_accepted'] ?? null) === true
                    && ! array_key_exists('email', $context)
                    && ! array_key_exists('SuppliedEmail', $context);
            })
            ->atLeast()->once();
    }
}
