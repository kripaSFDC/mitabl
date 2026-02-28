<?php

namespace App\Console\Commands;

use App\Services\SystemHealthService;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;

class PlatformSyntheticHealthCheckCommand extends Command
{
    protected $signature = 'platform:health:synthetic';

    protected $description = 'Run synthetic platform health checks and log results for operations monitoring.';

    public function handle(SystemHealthService $healthService): int
    {
        Cache::put('platform.health.synthetic.last_run_at', now()->toIso8601String(), now()->addDay());

        $summary = $healthService->runChecks();
        $overall = (string) ($summary['overall'] ?? 'unknown');
        $checks = collect($summary['checks'] ?? []);

        $warnings = $checks->where('status', 'warning')->values();
        $errors = $checks->where('status', 'error')->values();

        Log::info('platform.health.synthetic', [
            'overall' => $overall,
            'failing_checks' => (int) ($summary['failing_checks'] ?? 0),
            'warning_keys' => $warnings->pluck('key')->all(),
            'error_keys' => $errors->pluck('key')->all(),
        ]);

        if ($errors->isNotEmpty()) {
            $this->error('Synthetic health checks found critical failures.');
        } elseif ($warnings->isNotEmpty()) {
            $this->warn('Synthetic health checks found warnings.');
        } else {
            $this->info('Synthetic health checks are healthy.');
        }

        return self::SUCCESS;
    }
}
