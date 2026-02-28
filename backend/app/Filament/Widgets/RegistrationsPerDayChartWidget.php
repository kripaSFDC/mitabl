<?php

namespace App\Filament\Widgets;

use Filament\Facades\Filament;
use Filament\Widgets\ChartWidget;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

class RegistrationsPerDayChartWidget extends ChartWidget
{
    protected static ?string $heading = 'Registrations / Day (Last 30 Days)';

    protected static ?int $sort = 9;

    public static function canView(): bool
    {
        return (bool) Filament::auth()->user()?->can('dashboard.view');
    }

    protected function getData(): array
    {
        $start = Carbon::today()->subDays(29);
        $end = Carbon::today();

        $raw = DB::table('users')
            ->selectRaw('DATE(created_at) as day, COUNT(*) as total')
            ->whereBetween('created_at', [$start->startOfDay(), $end->copy()->endOfDay()])
            ->groupBy('day')
            ->pluck('total', 'day');

        $labels = [];
        $values = [];
        $cursor = $start->copy()->startOfDay();
        while ($cursor->lte($end)) {
            $key = $cursor->toDateString();
            $labels[] = $cursor->format('M d');
            $values[] = (int) ($raw[$key] ?? 0);
            $cursor->addDay();
        }

        return [
            'datasets' => [
                [
                    'label' => 'Registrations',
                    'data' => $values,
                    'borderColor' => '#22c55e',
                    'backgroundColor' => 'rgba(34,197,94,0.15)',
                    'fill' => true,
                    'tension' => 0.3,
                ],
            ],
            'labels' => $labels,
        ];
    }

    protected function getType(): string
    {
        return 'line';
    }
}
