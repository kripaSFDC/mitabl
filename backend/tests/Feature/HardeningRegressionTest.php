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

    public function test_no_plaintext_salesforce_or_stripe_tokens_in_source_templates(): void
    {
        $envExample = file_get_contents(base_path('.env.example'));
        $webApiController = file_get_contents(app_path('Http/Controllers/Api/WebApiToCurlController.php'));
        $registrationView = file_get_contents(resource_path('views/frontend/registration.blade.php'));
        $contactView = file_get_contents(resource_path('views/frontend/contact.blade.php'));
        $mobileContactView = file_get_contents(resource_path('views/mob/contact.blade.php'));

        $this->assertStringNotContainsString('sk_test_', $envExample);
        $this->assertStringNotContainsString('00D0w', $webApiController);
        $this->assertStringNotContainsString('Integration@', $webApiController);
        $this->assertStringNotContainsString('00D5i000004SJla', $registrationView);
        $this->assertStringNotContainsString('00D5i000004SJla', $contactView);
        $this->assertStringNotContainsString('00D5i000004SJla', $mobileContactView);
    }

    public function test_stripe_trait_no_longer_exists_and_payment_service_is_present(): void
    {
        $this->assertFileDoesNotExist(app_path('Traits/StripeTrait.php'));
        $this->assertFileExists(app_path('Services/PaymentService.php'));
    }
}
