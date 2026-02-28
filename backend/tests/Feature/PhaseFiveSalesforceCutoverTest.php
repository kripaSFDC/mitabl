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
            $content = (string) file_get_contents($file);
            $this->assertStringNotContainsString('SALESFORCE_', $content);
            $this->assertStringContainsString('RUN_MIGRATIONS_ON_BOOT=false', $content);
            $this->assertStringContainsString('RUN_SEEDERS_ON_BOOT=false', $content);
        }
    }

    public function test_phase_five_release_scaffolding_exists_for_ops_split(): void
    {
        $phase0Compose = (string) file_get_contents(base_path('../deploy/docker-compose.phase0.yml'));
        $nginxConfig = (string) file_get_contents(base_path('../deploy/nginx/mitabl.phase0.conf'));
        $consoleKernel = (string) file_get_contents(app_path('Console/Kernel.php'));
        $reconciliationCommand = (string) file_get_contents(app_path('Console/Commands/PhaseFiveCutoverReconciliationCommand.php'));
        $ciWorkflow = (string) file_get_contents(base_path('../.github/workflows/ci-cd.yml'));
        $releaseRunbook = (string) file_get_contents(base_path('../docs/phase5_release_runbook.md'));
        $backendAppServiceProvider = (string) file_get_contents(app_path('Providers/AppServiceProvider.php'));
        $websiteAppServiceProvider = (string) file_get_contents(base_path('../website/app/Providers/AppServiceProvider.php'));
        $backendApiRoutes = (string) file_get_contents(base_path('routes/api.php'));
        $websiteWebRoutes = (string) file_get_contents(base_path('../website/routes/web.php'));
        $startServerScript = (string) file_get_contents(base_path('start-server.sh'));
        $horizonConfig = (string) file_get_contents(config_path('horizon.php'));

        $this->assertStringContainsString('ops-admin:', $phase0Compose);
        $this->assertStringContainsString('queue-worker:', $phase0Compose);
        $this->assertStringContainsString('healthcheck:', $phase0Compose);
        $this->assertStringContainsString('com.mitabl.service: marketing', $phase0Compose);
        $this->assertStringContainsString('com.mitabl.service: api', $phase0Compose);
        $this->assertStringContainsString('com.mitabl.service: admin', $phase0Compose);
        $this->assertStringContainsString('curl -fsS http://localhost:8080/health', $phase0Compose);
        $this->assertStringContainsString('/api/health/startup', $phase0Compose);
        $this->assertStringContainsString('/api/health/live', $phase0Compose);
        $this->assertStringContainsString('/api/health/ready', $phase0Compose);
        $this->assertStringContainsString('replicas:', $phase0Compose);
        $this->assertStringContainsString('context: ../backend', $phase0Compose);
        $this->assertStringContainsString('context: ../website', $phase0Compose);
        $this->assertStringContainsString('- ./environments/backend-api.env', $phase0Compose);
        $this->assertStringContainsString('- ./environments/marketing-web.env', $phase0Compose);
        $this->assertStringContainsString('- ./environments/ops-admin.env', $phase0Compose);
        $this->assertStringNotContainsString('./deploy/environments/', $phase0Compose);
        $this->assertStringContainsString('--queue=crm-escalations,crm-communications,default', $phase0Compose);
        $this->assertStringContainsString('location /admin/', $nginxConfig);
        $this->assertStringContainsString('location /api/', $nginxConfig);
        $this->assertStringContainsString('Strict-Transport-Security', $nginxConfig);
        $this->assertStringContainsString('X-Content-Type-Options', $nginxConfig);
        $this->assertStringContainsString('Cache-Control "no-store"', $nginxConfig);
        $this->assertStringContainsString('return 405;', $nginxConfig);
        $this->assertStringContainsString('PhaseFiveCutoverReconciliationCommand', $consoleKernel);
        $this->assertStringContainsString('phase5:cutover:reconcile', $reconciliationCommand);
        $this->assertStringContainsString('secret-scan:', $ciWorkflow);
        $this->assertStringContainsString('5.5.1', $releaseRunbook);
        $this->assertStringContainsString('5.5.10', $releaseRunbook);
        $this->assertStringContainsString('Zero-downtime DB migration steps', $releaseRunbook);
        $this->assertStringContainsString('Define rollback runbook', $releaseRunbook);
        $this->assertStringContainsString('Production cutover rehearsal', $releaseRunbook);
        $this->assertStringContainsString('Log::withContext', $backendAppServiceProvider);
        $this->assertStringContainsString("'service' =>", $backendAppServiceProvider);
        $this->assertStringContainsString('Log::withContext', $websiteAppServiceProvider);
        $this->assertStringContainsString("Route::get('/health/startup'", $backendApiRoutes);
        $this->assertStringContainsString("Route::get('/health'", $websiteWebRoutes);
        $this->assertStringContainsString('RUN_MIGRATIONS_ON_BOOT', $startServerScript);
        $this->assertStringContainsString('RUN_SEEDERS_ON_BOOT', $startServerScript);
        $this->assertStringNotContainsString('php artisan migrate &&', $startServerScript);
        $this->assertStringContainsString("'queue' => ['crm-escalations', 'crm-communications', 'default']", $horizonConfig);
        $this->assertStringContainsString("'redis:crm-escalations' => 30", $horizonConfig);
        $this->assertStringContainsString("'redis:crm-communications' => 30", $horizonConfig);
    }

    public function test_contract_parity_replacements_exist_in_admin_resources(): void
    {
        $this->assertFileExists(app_path('Filament/Resources/CertificateResource.php'));
        $this->assertFileExists(app_path('Filament/Resources/UserResource.php'));
    }

    public function test_crm_queue_separation_is_configured_for_escalations_and_communications(): void
    {
        $slaJob = (string) file_get_contents(app_path('Jobs/ProcessSupportTicketSlaEscalationJob.php'));
        $crmService = (string) file_get_contents(app_path('Services/CrmCommunicationService.php'));
        $supervisor = (string) file_get_contents(base_path('../deploy/supervisor/queue-worker.conf'));

        $this->assertStringContainsString("public string \$queue = 'crm-escalations';", $slaJob);
        $this->assertStringContainsString("->onQueue('crm-communications')", $crmService);
        $this->assertStringContainsString('--queue=crm-escalations,crm-communications,default', $supervisor);
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
