<?php

namespace App\Providers;

use App\Services\PlatformRuntimeConfigService;
use Illuminate\Support\ServiceProvider;
use App\Observers\OrderObserver;
use App\Observers\MikitchnObserver;
use App\Observers\ReviewObserver;
use App\Observers\UserObserver;
use App\Observers\FoodsObserver;
use App\Observers\CertificateObserver;
use App\Models\Order;
use App\Models\Mikitchn;
use App\Models\Review;
use App\Models\User;
use App\Models\Foods;
use App\Models\Certificate;
use Illuminate\Routing\UrlGenerator;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Queue;
use Illuminate\Support\Str;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     *
     * @return void
     */
    public function register()
    {
        //
    }

    /**
     * Bootstrap any application services.
     *
     * @return void
     */
    public function boot(UrlGenerator $url)
    {
        app(PlatformRuntimeConfigService::class)->apply();

        $this->applyServiceLogContext();

        if (app()->environment('production', 'staging')) {
            $url->forceScheme('https');
            $url->forceRootUrl(rtrim((string) config('app.url'), '/'));
        }


        Order::observe(OrderObserver::class);
        Mikitchn::observe(MikitchnObserver::class);
        Review::observe(ReviewObserver::class);
        User::observe(UserObserver::class);
        Foods::observe(FoodsObserver::class);
        Certificate::observe(CertificateObserver::class);

        Queue::before(function (): void {
            // Keep long-running queue workers in sync with DB-backed runtime settings.
            app(PlatformRuntimeConfigService::class)->apply();
        });

        Queue::after(function ($event) {
            $payload = $event->job->payload();
            $queuedAt = $payload['pushedAt'] ?? null;
            $latencyMs = null;
            if ($queuedAt) {
                $latencyMs = (int) ((microtime(true) - (float) $queuedAt) * 1000);
            }
            Log::info('queue.job.processed', [
                'name' => $event->job->resolveName(),
                'connection' => $event->connectionName,
                'queue_latency_ms' => $latencyMs,
            ]);
        });

        Queue::failing(function ($event) {
            Log::error('queue.job.failed', [
                'name' => $event->job->resolveName(),
                'connection' => $event->connectionName,
                'error' => $event->exception->getMessage(),
            ]);
        });
    }

    private function applyServiceLogContext(): void
    {
        $service = (string) env('APP_SERVICE', 'backend-api');
        $environment = (string) config('app.env', app()->environment());

        Log::withContext([
            'service' => $service,
            'environment' => $environment,
            'release_phase' => 'phase-5.5',
            // Boot-scoped correlation for infra/runtime logs.
            'boot_id' => (string) Str::uuid(),
        ]);
    }
}
