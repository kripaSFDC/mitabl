<?php

namespace App\Providers;

use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Foundation\Support\Providers\RouteServiceProvider as ServiceProvider;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\Facades\Route;
use Throwable;

class RouteServiceProvider extends ServiceProvider
{
    /**
     * The path to the "home" route for your application.
     *
     * This is used by Laravel authentication to redirect users after login.
     *
     * @var string
     */
    public const HOME = '/home';

    /**
     * The controller namespace for the application.
     *
     * When present, controller route declarations will automatically be prefixed with this namespace.
     *
     * @var string|null
     */
    // protected $namespace = 'App\\Http\\Controllers';

    /**
     * Define your route model bindings, pattern filters, etc.
     *
     * @return void
     */
    public function boot()
    {
        $this->configureRateLimiting();

        $this->routes(function () {
            Route::prefix('api')
                ->middleware('api')
                ->group(base_path('routes/api.php'));

            Route::middleware('web')
                ->group(base_path('routes/web.php'));
        });
    }

    /**
     * Configure the rate limiters for the application.
     *
     * @return void
     */
    protected function configureRateLimiting()
    {
        RateLimiter::for('api', function (Request $request) {
            return Limit::perMinute(60)->by($this->resolveRateLimitActorKey($request, 'api'));
        });

        RateLimiter::for('support-intake', function (Request $request) {
            $email = strtolower(trim((string) (
                $request->input('requester_email')
                ?? $request->input('email')
                ?? $request->input('SuppliedEmail')
                ?? $request->input('Email')
                ?? ''
            )));
            $ip = (string) $request->ip();
            $emailOrIpKey = $email !== '' ? "support-intake:email:{$email}" : "support-intake:ip:{$ip}";

            return [
                // Tight burst control per requester identity.
                Limit::perMinute(4)->by($emailOrIpKey),
                // Backstop by source IP to reduce spray attempts across changing emails.
                Limit::perHour(30)->by("support-intake-hour-ip:{$ip}"),
            ];
        });


        RateLimiter::for('pre-register-intake', function (Request $request) {
            $email = strtolower(trim((string) $request->input('email', '')));
            $phone = preg_replace('/\D+/', '', (string) $request->input('phone', ''));
            $ip = (string) $request->ip();
            $keySeed = $email !== '' ? $email : ($phone !== '' ? $phone : $ip);

            return [
                // Burst protection for a single identity attempting repeated form submits.
                Limit::perMinute(6)->by('pre-register-intake:' . $keySeed),
                // Backstop to slow spray attempts from a single source IP.
                Limit::perHour(30)->by('pre-register-intake-hour-ip:' . $ip),
            ];
        });

        RateLimiter::for('support-read', function (Request $request) {
            return Limit::perMinute(30)->by($this->resolveRateLimitActorKey($request, 'support-read'));
        });

        RateLimiter::for('support-reply', function (Request $request) {
            return Limit::perMinute(12)->by($this->resolveRateLimitActorKey($request, 'support-reply'));
        });
    }

    private function resolveRateLimitActorKey(Request $request, string $prefix): string
    {
        try {
            $userId = optional($request->user())->id;
        } catch (Throwable) {
            $userId = null;
        }

        if ($userId) {
            return "{$prefix}:user:{$userId}";
        }

        return "{$prefix}:ip:" . (string) $request->ip();
    }
}
