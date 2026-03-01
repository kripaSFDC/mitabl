<?php

namespace Tests\Feature;

use App\Services\DiscoveryCacheService;
use Illuminate\Support\Facades\Cache;
use Tests\TestCase;

class HardeningRegressionTest extends TestCase
{
    public function test_queue_and_cache_config_default_to_redis_outside_testing_env(): void
    {
        $queueConfig = file_get_contents(config_path('queue.php'));
        $cacheConfig = file_get_contents(config_path('cache.php'));

        $this->assertStringContainsString("env('QUEUE_CONNECTION', env('APP_ENV') === 'testing' ? 'sync' : 'redis')", $queueConfig);
        $this->assertStringContainsString("env('CACHE_DRIVER', env('APP_ENV') === 'testing' ? 'array' : 'redis')", $cacheConfig);
    }

    public function test_env_template_enforces_redis_for_queue_and_cache(): void
    {
        $envExample = file_get_contents(base_path('.env.example'));
        $this->assertStringContainsString('QUEUE_CONNECTION=redis', $envExample);
        $this->assertStringContainsString('CACHE_DRIVER=redis', $envExample);
    }

    public function test_discovery_cache_invalidation_bumps_version(): void
    {
        $service = app(DiscoveryCacheService::class);
        Cache::forget('discovery:cache:version');

        $before = $service->cacheKey('nearest', ['lat' => '1']);
        $service->invalidateAll();
        $after = $service->cacheKey('nearest', ['lat' => '1']);

        $this->assertNotSame($before, $after);
    }

    public function test_discovery_cache_metrics_increment(): void
    {
        $service = app(DiscoveryCacheService::class);
        Cache::forget('discovery:metrics:hits');

        $service->incrementMetric('hits');

        $this->assertSame(1, (int) Cache::get('discovery:metrics:hits'));
    }

    public function test_no_plaintext_stripe_tokens_in_source_templates(): void
    {
        $envExample = file_get_contents(base_path('.env.example'));

        $this->assertStringNotContainsString('sk_test_', $envExample);
    }

    public function test_stripe_trait_no_longer_exists_and_payment_service_is_present(): void
    {
        $this->assertFileDoesNotExist(app_path('Traits/StripeTrait.php'));
        $this->assertFileExists(app_path('Services/PaymentService.php'));
    }

    public function test_root_compose_runs_migrations_before_backend_boot(): void
    {
        $compose = (string) file_get_contents(base_path('../docker-compose.yml'));

        $this->assertStringContainsString('db-migrate:', $compose);
        $this->assertStringContainsString('php artisan migrate --force', $compose);
        $this->assertStringContainsString('condition: service_completed_successfully', $compose);
    }

    public function test_critical_crm_and_policy_migrations_define_tables_indexes_and_constraints(): void
    {
        $checks = [
            '2026_02_28_000011_create_policies_table.php' => [
                "Schema::create('policies'",
                "->unique(['name', 'version'])",
                "policies_name_active_idx",
                "->constrained('admin_users')->nullOnDelete()",
            ],
            '2026_02_28_000012_create_policy_change_log_table.php' => [
                "Schema::create('policy_change_log'",
                "->constrained('policies')->cascadeOnDelete()",
                "policy_change_log_policy_created_idx",
            ],
            '2026_02_28_000005_create_support_tickets_table.php' => [
                "Schema::create('support_tickets'",
                "->unique()",
                "support_tickets_status_priority_assignee_idx",
                "support_tickets_requester_email_created_idx",
            ],
            '2026_02_28_000014_enhance_crm_phase3_tables.php' => [
                "Schema::create('crm_communication_logs'",
                'crm_comm_logs_status_channel_idx',
                'support_tickets_status_resolution_due_idx',
            ],
            '2026_02_28_000016_create_templates_table.php' => [
                "Schema::create('templates'",
                "->unique(['name', 'version'])",
                'templates_name_active_idx',
            ],
        ];

        foreach ($checks as $migration => $needles) {
            $contents = (string) file_get_contents(database_path("migrations/{$migration}"));
            foreach ($needles as $needle) {
                $this->assertStringContainsString($needle, $contents, "Missing [{$needle}] in {$migration}");
            }
        }
    }
}
