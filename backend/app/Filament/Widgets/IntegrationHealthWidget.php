<?php

namespace App\Filament\Widgets;

use App\Services\SystemHealthService;
use Filament\Facades\Filament;
use Filament\Widgets\StatsOverviewWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;

class IntegrationHealthWidget extends StatsOverviewWidget
{
    protected static ?int $sort = 5;

    protected static ?string $pollingInterval = '30s';

    public static function canView(): bool
    {
        return (bool) Filament::auth()->user()?->can('dashboard.view');
    }

    protected function getStats(): array
    {
        $summary = app(SystemHealthService::class)->runChecks();
        $checks = collect($summary['checks'] ?? [])->keyBy('key');

        return [
            $this->mapCheckToStat($checks->get('mail'), 'Mail'),
            $this->mapCheckToStat($checks->get('storage'), 'Storage'),
            $this->mapCheckToStat($checks->get('fcm'), 'FCM'),
            $this->mapCheckToStat($checks->get('stripe'), 'Stripe'),
        ];
    }

    private function mapCheckToStat(?array $check, string $label): Stat
    {
        $status = (string) ($check['status'] ?? 'unknown');
        $message = (string) ($check['message'] ?? 'No health data available.');

        return Stat::make($label, strtoupper($status))
            ->description($message)
            ->color(match ($status) {
                'ok' => 'success',
                'warning' => 'warning',
                default => 'danger',
            });
    }
}
