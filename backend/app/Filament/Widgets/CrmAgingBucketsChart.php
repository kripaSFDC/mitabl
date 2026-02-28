<?php

namespace App\Filament\Widgets;

use App\Models\SupportTicket;
use Filament\Facades\Filament;
use Filament\Widgets\ChartWidget;

class CrmAgingBucketsChart extends ChartWidget
{
    protected static ?string $heading = 'Support Ticket Aging Buckets';

    protected static ?int $sort = 2;

    public static function canView(): bool
    {
        return (bool) Filament::auth()->user()?->can('dashboard.view');
    }

    protected function getData(): array
    {
        $active = SupportTicket::query()
            ->whereIn('status', [
                SupportTicket::STATUS_OPEN,
                SupportTicket::STATUS_IN_PROGRESS,
                SupportTicket::STATUS_PENDING_USER,
            ]);

        $bucket0To4 = (clone $active)->where('created_at', '>=', now()->subHours(4))->count();
        $bucket4To24 = (clone $active)
            ->whereBetween('created_at', [now()->subDay(), now()->subHours(4)])
            ->count();
        $bucket1To3d = (clone $active)
            ->whereBetween('created_at', [now()->subDays(3), now()->subDay()])
            ->count();
        $bucketOver3d = (clone $active)->where('created_at', '<', now()->subDays(3))->count();

        return [
            'datasets' => [
                [
                    'label' => 'Tickets',
                    'data' => [$bucket0To4, $bucket4To24, $bucket1To3d, $bucketOver3d],
                    'backgroundColor' => ['#38bdf8', '#f59e0b', '#f97316', '#ef4444'],
                ],
            ],
            'labels' => ['0-4h', '4-24h', '1-3d', '>3d'],
        ];
    }

    protected function getType(): string
    {
        return 'bar';
    }
}
