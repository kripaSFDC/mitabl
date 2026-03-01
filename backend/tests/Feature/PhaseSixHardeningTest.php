<?php

namespace Tests\Feature;

use App\Filament\Resources\PolicyResource;
use App\Jobs\ProcessSupportTicketSlaEscalationJob;
use App\Models\SupportTicket;
use App\Providers\HorizonServiceProvider;
use App\Services\SupportTicketService;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class PhaseSixHardeningTest extends TestCase
{
    public function test_phase_six_queue_runtime_uses_redis_and_horizon(): void
    {
        $compose = (string) file_get_contents(base_path('../deploy/docker-compose.phase0.yml'));
        $supervisor = (string) file_get_contents(base_path('../deploy/supervisor/queue-worker.conf'));
        $envExample = (string) file_get_contents(base_path('.env.example'));
        $deployBackendEnv = (string) file_get_contents(base_path('../deploy/environments/backend-api.env'));
        $deployDevBackendEnv = (string) file_get_contents(base_path('../deploy/environments/dev/backend-api.env'));
        $deployStagingBackendEnv = (string) file_get_contents(base_path('../deploy/environments/staging/backend-api.env'));
        $deployProdBackendEnv = (string) file_get_contents(base_path('../deploy/environments/prod/backend-api.env'));

        $this->assertContains(HorizonServiceProvider::class, config('app.providers'));
        $this->assertSame('redis', config('horizon.defaults.supervisor-1.connection'));
        $this->assertSame(['crm-escalations', 'crm-communications', 'default'], config('horizon.defaults.supervisor-1.queue'));
        $this->assertSame(30, config('horizon.waits.redis:crm-escalations'));
        $this->assertSame(30, config('horizon.waits.redis:crm-communications'));

        $this->assertStringContainsString('"php", "artisan", "horizon"', $compose);
        $this->assertStringContainsString('grep -q "artisan horizon"', $compose);
        $this->assertStringContainsString('command=php /app/artisan horizon', $supervisor);
        $this->assertStringContainsString('QUEUE_CONNECTION=redis', $envExample);
        $this->assertStringContainsString('HORIZON_PREFIX=mitabl_horizon:', $envExample);
        $this->assertStringContainsString('QUEUE_CONNECTION=redis', $deployBackendEnv);
        $this->assertStringContainsString('HORIZON_PREFIX=mitabl_horizon:', $deployBackendEnv);
        $this->assertStringContainsString('RECAPTCHA_SECRET=', $deployBackendEnv);
        $this->assertStringContainsString('QUEUE_CONNECTION=redis', $deployDevBackendEnv);
        $this->assertStringContainsString('HORIZON_PREFIX=mitabl_horizon:', $deployDevBackendEnv);
        $this->assertStringContainsString('RECAPTCHA_SECRET=', $deployDevBackendEnv);
        $this->assertStringContainsString('QUEUE_CONNECTION=redis', $deployStagingBackendEnv);
        $this->assertStringContainsString('HORIZON_PREFIX=mitabl_horizon:', $deployStagingBackendEnv);
        $this->assertStringContainsString('RECAPTCHA_SECRET=', $deployStagingBackendEnv);
        $this->assertStringContainsString('QUEUE_CONNECTION=redis', $deployProdBackendEnv);
        $this->assertStringContainsString('HORIZON_PREFIX=mitabl_horizon:', $deployProdBackendEnv);
        $this->assertStringContainsString('RECAPTCHA_SECRET=', $deployProdBackendEnv);
    }

    public function test_phase_six_deployment_runs_migrations_before_services_start(): void
    {
        $compose = (string) file_get_contents(base_path('../deploy/docker-compose.phase0.yml'));

        $this->assertStringContainsString('db-migrate:', $compose);
        $this->assertStringContainsString('php artisan migrate --force', $compose);
        $this->assertStringContainsString('php artisan db:seed --force', $compose);
        $this->assertGreaterThanOrEqual(3, substr_count($compose, 'condition: service_completed_successfully'));
    }

    public function test_phase_six_intake_throttles_and_abuse_controls_are_enforced(): void
    {
        $routes = collect(app('router')->getRoutes()->getRoutes());
        $preregisterRoute = $routes->first(fn ($route): bool => in_array('POST', $route->methods(), true) && $route->uri() === 'api/preregister');
        $supportStoreRoute = $routes->first(fn ($route): bool => in_array('POST', $route->methods(), true) && $route->uri() === 'api/support/ticket');
        $mobcontactRoute = $routes->first(fn ($route): bool => in_array('POST', $route->methods(), true) && $route->uri() === 'api/mobcontact');
        $supportShowRoute = $routes->first(fn ($route): bool => in_array('GET', $route->methods(), true) && $route->uri() === 'api/support/ticket/{id}');
        $supportReplyRoute = $routes->first(fn ($route): bool => in_array('POST', $route->methods(), true) && $route->uri() === 'api/support/ticket/{id}/reply');

        $this->assertNotNull($preregisterRoute);
        $this->assertNotNull($supportStoreRoute);
        $this->assertNotNull($mobcontactRoute);
        $this->assertNotNull($supportShowRoute);
        $this->assertNotNull($supportReplyRoute);

        $this->assertContains('throttle:support-intake', $preregisterRoute->middleware());
        $this->assertContains('throttle:support-intake', $supportStoreRoute->middleware());
        $this->assertContains('throttle:support-intake', $mobcontactRoute->middleware());
        $this->assertContains('mobcontact.deprecation', $mobcontactRoute->middleware());
        $this->assertContains('throttle:support-read', $supportShowRoute->middleware());
        $this->assertContains('throttle:support-reply', $supportReplyRoute->middleware());

        $limiterEmail = 'phase6-throttle-' . uniqid('', true) . '@example.com';
        for ($attempt = 1; $attempt <= 8; $attempt++) {
            $this->postJson('/api/preregister', [
                'email' => $limiterEmail,
                'website' => 'bot-signal',
            ])->assertStatus(200);
        }
        $this->postJson('/api/preregister', [
            'email' => $limiterEmail,
            'website' => 'bot-signal',
        ])->assertStatus(429);
    }

    public function test_phase_six_captcha_abuse_controls_cover_public_intake_aliases(): void
    {
        config()->set('services.recaptcha.secret', 'phase6-secret');

        Http::fake([
            'https://www.google.com/recaptcha/api/siteverify' => Http::response(['success' => false], 200),
        ]);

        $this->postJson('/api/support/ticket', [
            'requester_email' => 'phase6-support@example.com',
            'subject' => 'Phase 6 captcha',
            'description' => 'Captcha must reject bad token.',
            'captcha_token' => 'bad-token',
        ])->assertStatus(422);

        $this->postJson('/api/support/ticket', [
            'requester_email' => 'phase6-support-legacy@example.com',
            'subject' => 'Phase 6 captcha legacy field',
            'description' => 'Legacy recaptcha response field must reject bad token.',
            'g-recaptcha-response' => 'bad-token',
        ])->assertStatus(422);

        $this->postJson('/api/mobcontact', [
            'requester_email' => 'phase6-mobcontact@example.com',
            'subject' => 'Phase 6 mobcontact captcha',
            'description' => 'Alias endpoint must enforce captcha rules.',
            'g-recaptcha-response' => 'bad-token',
        ])->assertStatus(422);

        $this->postJson('/api/preregister', [
            'email' => 'phase6-preregister@example.com',
            'captcha_token' => 'bad-token',
        ])->assertStatus(422);

        Http::assertSentCount(4);
    }

    public function test_phase_six_certificate_flow_coverage_exists_for_approve_reject_resubmit(): void
    {
        $certificateResource = (string) file_get_contents(app_path('Filament/Resources/CertificateResource.php'));
        $mikitchnController = (string) file_get_contents(app_path('Http/Controllers/Api/MikitchnController.php'));

        $this->assertStringContainsString("Action::make('approve')", $certificateResource);
        $this->assertStringContainsString("Action::make('reject')", $certificateResource);
        $this->assertStringContainsString("BulkAction::make('bulk_approve')", $certificateResource);
        $this->assertStringContainsString("BulkAction::make('bulk_reject')", $certificateResource);
        $this->assertStringContainsString('lockForUpdate()', $certificateResource);
        $this->assertStringContainsString('hasValidCertificateDocument', $certificateResource);
        $this->assertStringContainsString("Forms\\Components\\Textarea::make('rejection_reason')", $certificateResource);
        $this->assertStringContainsString('$status = 0;', $mikitchnController);
        $this->assertStringContainsString('$certificate->status = $status;', $mikitchnController);
    }

    public function test_phase_six_ticket_lifecycle_and_sla_wiring_is_covered(): void
    {
        $supportService = app(SupportTicketService::class);
        $slaCommand = app()->make(\App\Console\Commands\SupportTicketSlaScanCommand::class);
        $slaJob = new ProcessSupportTicketSlaEscalationJob(1, 'first_response');
        $unitTest = (string) file_get_contents(base_path('tests/Unit/PhaseThreeSupportTicketServiceTest.php'));

        $this->assertTrue(method_exists($supportService, 'addReply'));
        $this->assertTrue(method_exists($supportService, 'transitionStatus'));
        $this->assertTrue(method_exists($supportService, 'assignTicket'));
        $this->assertTrue(method_exists($supportService, 'resolveTicket'));
        $this->assertTrue(method_exists($supportService, 'mergeInto'));
        $this->assertTrue(method_exists($supportService, 'splitTicket'));
        $this->assertSame('support:sla:scan', $slaCommand->getName());
        $this->assertSame('crm-escalations', $slaJob->queue);
        $this->assertContains(SupportTicket::STATUS_PENDING_USER, SupportTicket::statuses());
        $this->assertContains(SupportTicket::STATUS_RESOLVED, SupportTicket::statuses());
        $this->assertStringContainsString('test_reply_and_transition_rules_including_reopen_window', $unitTest);
        $this->assertStringContainsString('test_sla_scan_dispatches_only_valid_jobs_for_unresolved_tickets', $unitTest);
    }

    public function test_phase_six_policy_permission_boundaries_are_enforced(): void
    {
        $policyResource = (string) file_get_contents(app_path('Filament/Resources/PolicyResource.php'));
        $permissionSeeder = (string) file_get_contents(database_path('seeders/AdminRolePermissionSeeder.php'));

        $this->assertTrue(method_exists(PolicyResource::class, 'canViewAny'));
        $this->assertTrue(method_exists(PolicyResource::class, 'canCreate'));
        $this->assertTrue(method_exists(PolicyResource::class, 'canEdit'));
        $this->assertStringContainsString("return (bool) Filament::auth()->user()?->can('policies.view');", $policyResource);
        $this->assertStringContainsString("return (bool) Filament::auth()->user()?->can('policies.edit');", $policyResource);
        $this->assertStringContainsString("return (bool) Filament::auth()->user()?->can('policy_changes.publish');", $policyResource);
        $this->assertStringContainsString("'super_admin' => \$permissions", $permissionSeeder);
        $this->assertStringContainsString("'platform_admin' => [", $permissionSeeder);
        $this->assertStringContainsString("'operations' => [", $permissionSeeder);
        $this->assertStringContainsString("'customer_service' => [", $permissionSeeder);
        $this->assertStringContainsString("'policy_changes.publish'", $permissionSeeder);
    }

    public function test_phase_six_load_test_and_disaster_recovery_artifacts_exist(): void
    {
        $loadReadme = (string) file_get_contents(base_path('../deploy/load-tests/README.md'));
        $supportLoad = (string) file_get_contents(base_path('../deploy/load-tests/support-intake-load-test.js'));
        $adminLoad = (string) file_get_contents(base_path('../deploy/load-tests/admin-list-load-test.js'));
        $drScript = (string) file_get_contents(base_path('../deploy/scripts/validate-backup-restore.ps1'));
        $runbook = (string) file_get_contents(base_path('../docs/phase6_hardening_runbook.md'));
        $validationReport = (string) file_get_contents(base_path('../docs/phase6_validation_report.md'));

        $this->assertStringContainsString('support-intake-load-test.js', $loadReadme);
        $this->assertStringContainsString('admin-list-load-test.js', $loadReadme);
        $this->assertStringContainsString('POST /api/support/ticket', $loadReadme);
        $this->assertStringContainsString('ADMIN_COOKIE', $adminLoad);
        $this->assertStringContainsString('/admin/policies', $adminLoad);
        $this->assertStringContainsString('/admin/support-tickets', $adminLoad);
        $this->assertStringContainsString('/api/support/ticket', $supportLoad);
        $this->assertStringContainsString('CAPTCHA_TOKEN', $supportLoad);
        $this->assertStringContainsString('RequiredScopes', $drScript);
        $this->assertStringContainsString('RestoreEvidenceFile', $drScript);
        $this->assertStringContainsString('6.1 Redis queue + Horizon', $runbook);
        $this->assertStringContainsString('6.7 Disaster recovery runbook + backup validation', $runbook);
        $this->assertStringContainsString('Phase 6 Completion Matrix', $validationReport);
        $this->assertStringContainsString('| 6.1 Redis queue + Horizon | Complete |', $validationReport);
        $this->assertStringContainsString('| 6.7 Disaster recovery runbook + backup validation | Complete |', $validationReport);
    }
}
