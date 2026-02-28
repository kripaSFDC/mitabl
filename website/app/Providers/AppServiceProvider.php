<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use Illuminate\Routing\UrlGenerator;
use Illuminate\Support\Facades\Log;

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
        Log::withContext([
            'service' => (string) env('APP_SERVICE', 'marketing-web'),
            'environment' => (string) config('app.env', app()->environment()),
            'release_phase' => 'phase-5.5',
        ]);

        if (env('APP_ENV') !== 'local') {
            $url->forceScheme('https');
        }
    }
}
