<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Queue;
use Illuminate\Support\Facades\Redis;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Cache;
use App\Models\PlatformSetting;

class SystemHealthService
{
    public function runChecks(): array
    {
        $checks = [
            $this->checkDatabase(),
            $this->checkRedis(),
            $this->checkQueue(),
            $this->checkQueueProcessing(),
            $this->checkMail(),
            $this->checkTicketIntake(),
            $this->checkStorage(),
            $this->checkFcm(),
            $this->checkStripe(),
            $this->checkSchedulerHeartbeat(),
            $this->checkDegradedMode(),
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
        $startedAt = microtime(true);

        try {
            DB::connection()->getPdo();
            $latencyMs = (int) round((microtime(true) - $startedAt) * 1000);
            $status = $latencyMs > 250 ? 'warning' : 'ok';

            return [
                'key' => 'database',
                'label' => 'Database',
                'status' => $status,
                'message' => 'Database connection is healthy. Latency: ' . $latencyMs . 'ms.',
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

    private function checkRedis(): array
    {
        try {
            Redis::connection()->ping();

            return [
                'key' => 'redis',
                'label' => 'Redis',
                'status' => 'ok',
                'message' => 'Redis connection is healthy.',
            ];
        } catch (\Throwable $throwable) {
            return [
                'key' => 'redis',
                'label' => 'Redis',
                'status' => $this->isProductionLike() ? 'error' : 'warning',
                'message' => 'Redis check failed: ' . $throwable->getMessage(),
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
            $oldestPending = DB::table('jobs')->min('created_at');
            $poisonCount = DB::table('failed_jobs')
                ->get(['payload', 'exception'])
                ->filter(fn ($job): bool => $this->isPoisonFailedJob((string) $job->payload, (string) $job->exception))
                ->count();
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

        $oldestAgeMinutes = $oldestPending ? now()->diffInMinutes($oldestPending) : 0;

        if ($failedJobsCount > 100) {
            $status = 'error';
            $message = 'Dead-letter queue pressure detected (' . $failedJobsCount . ' failed jobs).';
        } elseif ($failedJobsCount > 0) {
            $status = 'warning';
            $message = 'Failed jobs detected (' . $failedJobsCount . ').';
        } elseif ($jobsCount > 1000 || $oldestAgeMinutes > 60) {
            $status = 'warning';
            $message = 'Queue backlog is high (' . $jobsCount . ' pending jobs, oldest age: ' . $oldestAgeMinutes . ' min).';
        }

        if ($poisonCount > 0) {
            $status = $status === 'error' ? 'error' : 'warning';
            $message .= ' Potential poison-message retries: ' . $poisonCount . '.';
        }

        return [
            'key' => 'queue_processing',
            'label' => 'Queue Processing',
            'status' => $status,
            'message' => $message,
        ];
    }

    private function checkSchedulerHeartbeat(): array
    {
        $lastRun = Cache::get('platform.health.synthetic.last_run_at');

        if (! $lastRun) {
            return [
                'key' => 'scheduler',
                'label' => 'Scheduler',
                'status' => 'warning',
                'message' => 'No scheduler heartbeat found yet.',
            ];
        }

        $lastRunAt = \Carbon\Carbon::parse((string) $lastRun);
        $ageMinutes = now()->diffInMinutes($lastRunAt);

        if ($ageMinutes > 15) {
            return [
                'key' => 'scheduler',
                'label' => 'Scheduler',
                'status' => 'error',
                'message' => 'Scheduler heartbeat stale (' . $ageMinutes . ' min). Possible failed cron.',
            ];
        }

        return [
            'key' => 'scheduler',
            'label' => 'Scheduler',
            'status' => $ageMinutes > 7 ? 'warning' : 'ok',
            'message' => 'Scheduler heartbeat age: ' . $ageMinutes . ' min.',
        ];
    }

    private function checkDegradedMode(): array
    {
        try {
            $setting = PlatformSetting::query()->where('key', 'incident.degraded_mode')->first();
            $value = $this->normalizeSettingValue($setting?->value);
            $enabled = filter_var(data_get($value, 'enabled', false), FILTER_VALIDATE_BOOL);
            $postmortem = (string) data_get($value, 'postmortem_url', '');
            $annotation = trim((string) data_get($value, 'annotation', data_get($value, 'incident_note', '')));

            if (! $enabled) {
                return [
                    'key' => 'degraded_mode',
                    'label' => 'Partial Outage Mode',
                    'status' => 'ok',
                    'message' => 'Degraded mode is disabled.',
                ];
            }

            return [
                'key' => 'degraded_mode',
                'label' => 'Partial Outage Mode',
                'status' => 'warning',
                'message' => 'Degraded mode is active.'
                    . ($annotation !== '' ? ' Incident: ' . $annotation . '.' : '')
                    . ($postmortem !== '' ? ' Postmortem: ' . $postmortem : ''),
            ];
        } catch (\Throwable $throwable) {
            return [
                'key' => 'degraded_mode',
                'label' => 'Partial Outage Mode',
                'status' => 'warning',
                'message' => 'Unable to determine degraded mode status: ' . $throwable->getMessage(),
            ];
        }
    }

    private function isPoisonFailedJob(string $payload, string $exception): bool
    {
        $attempts = $this->extractAttemptsFromFailedPayload($payload, $exception);

        if ($attempts >= 5) {
            return true;
        }

        return str_contains(strtolower($exception), 'attempted too many times');
    }

    private function extractAttemptsFromFailedPayload(string $payload, string $exception): int
    {
        $decoded = json_decode($payload, true);
        if (is_array($decoded)) {
            $directAttempts = (int) data_get($decoded, 'attempts', 0);
            if ($directAttempts > 0) {
                return $directAttempts;
            }

            $maxTries = (int) data_get($decoded, 'maxTries', 0);
            if ($maxTries > 0) {
                return $maxTries;
            }
        }

        if (preg_match('/attempted\s+(\d+)\s+times/i', $exception, $matches) === 1) {
            return (int) ($matches[1] ?? 0);
        }

        return 0;
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
        $hasPreRegisterRoute = false;

        foreach ($routes as $route) {
            $uri = trim((string) $route->uri(), '/');
            $methods = $route->methods();

            if (in_array('POST', $methods, true) && $uri === 'api/support/ticket') {
                $hasSupportTicketRoute = true;
            }

            if (in_array('POST', $methods, true) && $uri === 'api/preregister') {
                $hasPreRegisterRoute = true;
            }
        }

        if ($hasSupportTicketRoute || $hasPreRegisterRoute) {
            return [
                'key' => 'ticket_intake',
                'label' => 'Ticket Intake',
                'status' => 'warning',
                'message' => 'Legacy public intake routes are still enabled and should be removed.',
            ];
        }

        return [
            'key' => 'ticket_intake',
            'label' => 'Ticket Intake',
            'status' => 'ok',
            'message' => 'Legacy public intake routes are disabled.',
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


    private function normalizeSettingValue(mixed $value): array
    {
        if (is_array($value)) {
            return $value;
        }

        if (is_string($value) && $value !== '') {
            $decoded = json_decode($value, true);
            if (is_array($decoded)) {
                return $decoded;
            }
        }

        return [];
    }

    private function isProductionLike(): bool
    {
        $environment = strtolower((string) config('app.env', app()->environment()));

        return ! in_array($environment, ['local', 'testing'], true);
    }
}
