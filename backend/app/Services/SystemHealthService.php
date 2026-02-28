<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Queue;
use Illuminate\Support\Facades\Redis;
use Illuminate\Support\Facades\Storage;

class SystemHealthService
{
    public function runChecks(): array
    {
        $checks = [
            $this->checkDatabase(),
            $this->checkQueue(),
            $this->checkQueueProcessing(),
            $this->checkMail(),
            $this->checkTicketIntake(),
            $this->checkStorage(),
            $this->checkFcm(),
            $this->checkStripe(),
        ];

        $failed = collect($checks)->whereIn('status', ['error', 'warning'])->count();

        return [
            'overall' => $failed === 0 ? 'healthy' : ($failed >= 3 ? 'degraded' : 'at_risk'),
            'failing_checks' => $failed,
            'checks' => $checks,
        ];
    }

    private function checkDatabase(): array
    {
        try {
            DB::connection()->getPdo();

            return [
                'key' => 'database',
                'label' => 'Database',
                'status' => 'ok',
                'message' => 'Database connection is healthy.',
            ];
        } catch (\Throwable $throwable) {
            return [
                'key' => 'database',
                'label' => 'Database',
                'status' => 'error',
                'message' => 'Database connection failed: ' . $throwable->getMessage(),
            ];
        }
    }

    private function checkQueue(): array
    {
        $connection = (string) config('queue.default');
        $failedJobs = null;
        $isProductionLike = $this->isProductionLike();

        try {
            $failedJobs = DB::table('failed_jobs')->count();
        } catch (\Throwable $throwable) {
            // Fallback if failed_jobs table has not been migrated in local env.
        }

        try {
            if ($connection === 'redis') {
                Redis::connection()->ping();
            } else {
                Queue::connection($connection);
            }

            if ($connection === 'sync' && $isProductionLike) {
                return [
                    'key' => 'queue',
                    'label' => 'Queue',
                    'status' => 'error',
                    'message' => 'Queue default is "sync" in a non-local environment. Configure Redis workers/Horizon.',
                ];
            }

            $status = ($failedJobs !== null && $failedJobs > 0) ? 'warning' : 'ok';
            $message = 'Queue connection reachable.';
            if ($failedJobs !== null) {
                $message .= ' Failed jobs: ' . $failedJobs . '.';
            }

            return [
                'key' => 'queue',
                'label' => 'Queue',
                'status' => $status,
                'message' => $message,
            ];
        } catch (\Throwable $throwable) {
            return [
                'key' => 'queue',
                'label' => 'Queue',
                'status' => 'error',
                'message' => 'Queue check failed: ' . $throwable->getMessage(),
            ];
        }
    }

    private function checkQueueProcessing(): array
    {
        try {
            $jobsCount = DB::table('jobs')->count();
            $failedJobsCount = DB::table('failed_jobs')->count();
        } catch (\Throwable $throwable) {
            return [
                'key' => 'queue_processing',
                'label' => 'Queue Processing',
                'status' => $this->isProductionLike() ? 'error' : 'warning',
                'message' => 'Queue processing tables unavailable: ' . $throwable->getMessage(),
            ];
        }

        $status = 'ok';
        $message = 'Queue backlog is within threshold.';

        if ($failedJobsCount > 0) {
            $status = 'warning';
            $message = 'Failed jobs detected (' . $failedJobsCount . ').';
        } elseif ($jobsCount > 1000) {
            $status = 'warning';
            $message = 'Queue backlog is high (' . $jobsCount . ' pending jobs).';
        }

        return [
            'key' => 'queue_processing',
            'label' => 'Queue Processing',
            'status' => $status,
            'message' => $message,
        ];
    }

    private function checkMail(): array
    {
        $mailer = (string) config('mail.default');
        $host = (string) config('mail.mailers.smtp.host');
        $fromAddress = (string) config('mail.from.address');
        $isProductionLike = $this->isProductionLike();

        if ($mailer === '') {
            return [
                'key' => 'mail',
                'label' => 'Mail',
                'status' => 'error',
                'message' => 'No default mailer configured.',
            ];
        }

        if ($mailer === 'smtp' && $host === '') {
            return [
                'key' => 'mail',
                'label' => 'Mail',
                'status' => $isProductionLike ? 'error' : 'warning',
                'message' => 'SMTP selected but MAIL_HOST is not configured.',
            ];
        }

        if ($fromAddress === '') {
            return [
                'key' => 'mail',
                'label' => 'Mail',
                'status' => $isProductionLike ? 'error' : 'warning',
                'message' => 'MAIL_FROM_ADDRESS is not configured.',
            ];
        }

        try {
            Mail::mailer($mailer);
        } catch (\Throwable $throwable) {
            return [
                'key' => 'mail',
                'label' => 'Mail',
                'status' => 'error',
                'message' => 'Mailer initialization failed: ' . $throwable->getMessage(),
            ];
        }

        return [
            'key' => 'mail',
            'label' => 'Mail',
            'status' => 'ok',
            'message' => 'Mailer configured: ' . $mailer . '.',
        ];
    }

    private function checkTicketIntake(): array
    {
        $routes = app('router')->getRoutes();

        $hasSupportTicketRoute = false;
        $hasMobContactRoute = false;
        $hasPreRegisterRoute = false;
        $supportHasThrottle = false;
        $mobContactHasThrottle = false;
        $preRegisterHasThrottle = false;

        foreach ($routes as $route) {
            $uri = trim((string) $route->uri(), '/');
            $methods = $route->methods();
            $middleware = $route->middleware();

            if (in_array('POST', $methods, true) && $uri === 'api/support/ticket') {
                $hasSupportTicketRoute = true;
                $supportHasThrottle = collect($middleware)
                    ->contains(fn ($item): bool => is_string($item) && str_starts_with($item, 'throttle:support-intake'));
            }

            if (in_array('POST', $methods, true) && $uri === 'api/mobcontact') {
                $hasMobContactRoute = true;
                $mobContactHasThrottle = collect($middleware)
                    ->contains(fn ($item): bool => is_string($item) && str_starts_with($item, 'throttle:support-intake'));
            }

            if (in_array('POST', $methods, true) && $uri === 'api/preregister') {
                $hasPreRegisterRoute = true;
                $preRegisterHasThrottle = collect($middleware)
                    ->contains(fn ($item): bool => is_string($item) && str_starts_with($item, 'throttle:support-intake'));
            }
        }

        if (! $hasSupportTicketRoute || ! $hasMobContactRoute || ! $hasPreRegisterRoute) {
            return [
                'key' => 'ticket_intake',
                'label' => 'Ticket Intake',
                'status' => 'error',
                'message' => 'Support intake routes are incomplete. Expected POST /api/support/ticket, /api/mobcontact, and /api/preregister.',
            ];
        }

        if (! $supportHasThrottle || ! $mobContactHasThrottle || ! $preRegisterHasThrottle) {
            return [
                'key' => 'ticket_intake',
                'label' => 'Ticket Intake',
                'status' => 'warning',
                'message' => 'Support intake throttling is missing on one or more public intake routes.',
            ];
        }

        return [
            'key' => 'ticket_intake',
            'label' => 'Ticket Intake',
            'status' => 'ok',
            'message' => 'Support intake routes and throttles are configured.',
        ];
    }

    private function checkStorage(): array
    {
        $disk = (string) config('filesystems.default', 'local');
        $path = 'healthcheck/platform-health-' . now()->timestamp . '.txt';

        try {
            Storage::disk($disk)->put($path, 'ok');
            Storage::disk($disk)->delete($path);

            return [
                'key' => 'storage',
                'label' => 'Storage',
                'status' => 'ok',
                'message' => 'Storage read/write check succeeded on disk: ' . $disk . '.',
            ];
        } catch (\Throwable $throwable) {
            return [
                'key' => 'storage',
                'label' => 'Storage',
                'status' => 'error',
                'message' => 'Storage check failed: ' . $throwable->getMessage(),
            ];
        }
    }

    private function checkFcm(): array
    {
        $fcmKey = (string) env('FCM_SERVER_KEY', '');

        if ($fcmKey === '') {
            return [
                'key' => 'fcm',
                'label' => 'FCM',
                'status' => 'warning',
                'message' => 'FCM server key is not configured.',
            ];
        }

        return [
            'key' => 'fcm',
            'label' => 'FCM',
            'status' => 'ok',
            'message' => 'FCM server key is configured.',
        ];
    }

    private function checkStripe(): array
    {
        $secret = (string) config('stripe.api_keys.secret_key');

        if ($secret === '') {
            return [
                'key' => 'stripe',
                'label' => 'Stripe',
                'status' => 'warning',
                'message' => 'Stripe secret key is not configured.',
            ];
        }

        return [
            'key' => 'stripe',
            'label' => 'Stripe',
            'status' => 'ok',
            'message' => 'Stripe credentials are configured.',
        ];
    }

    private function isProductionLike(): bool
    {
        $environment = strtolower((string) config('app.env', app()->environment()));

        return ! in_array($environment, ['local', 'testing'], true);
    }
}
