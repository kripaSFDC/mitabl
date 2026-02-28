<?php

namespace App\Filament\Widgets;

use App\Services\SystemHealthService;
use Filament\Facades\Filament;
use Filament\Widgets\StatsOverviewWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;
use Illuminate\Support\Facades\DB;

class SystemHealthSummaryWidget extends StatsOverviewWidget
{
    protected static ?int $sort = 7;

    protected static ?string $pollingInterval = '30s';

    public static function canView(): bool
    {
        return (bool) Filament::auth()->user()?->can('health.view');
    }

    protected function getStats(): array
    {
        $summary = app(SystemHealthService::class)->runChecks();
        $checks = collect($summary['checks'] ?? []);

        $healthy = $checks->where('status', 'ok')->count();
        $warning = $checks->where('status', 'warning')->count();
        $error = $checks->where('status', 'error')->count();

        $failedJobs = 0;
        try {
            $failedJobs = DB::table('failed_jobs')->count();
        } catch (\Throwable $throwable) {
            $failedJobs = 0;
        }

        return [
            Stat::make('System checks (healthy)', sprintf('%d/%d', $healthy, max($checks->count(), 1)))
                ->description('Warnings: ' . $warning . ' | Errors: ' . $error)
                ->color($error > 0 ? 'danger' : ($warning > 0 ? 'warning' : 'success')),
            Stat::make('Overall status', (string) str($summary['overall'] ?? 'unknown')->replace('_', ' ')->title())
                ->description('Platform health aggregation')
                ->color(match ($summary['overall'] ?? 'unknown') {
                    'healthy' => 'success',
                    'at_risk' => 'warning',
                    default => 'danger',
                }),
            Stat::make('Failed jobs', (string) $failedJobs)
                ->description('Current failed_jobs backlog')
                ->color($failedJobs > 0 ? 'danger' : 'success'),
        ];
    }
}
