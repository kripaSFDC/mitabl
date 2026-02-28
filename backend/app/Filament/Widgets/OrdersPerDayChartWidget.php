<?php

namespace App\Filament\Widgets;

use Filament\Facades\Filament;
use Filament\Widgets\ChartWidget;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

class OrdersPerDayChartWidget extends ChartWidget
{
    protected static ?string $heading = 'Orders / Day (Last 30 Days)';

    protected static ?int $sort = 8;

    public static function canView(): bool
    {
        return (bool) Filament::auth()->user()?->can('dashboard.view');
    }

    protected function getData(): array
    {
        $start = Carbon::today()->subDays(29);
        $end = Carbon::today();

        $raw = DB::table('orders')
            ->selectRaw('DATE(delivery_date) as day, COUNT(*) as total')
            ->whereBetween('delivery_date', [$start->toDateString(), $end->toDateString()])
            ->groupBy('day')
            ->pluck('total', 'day');

        $labels = [];
        $values = [];
        $cursor = $start->copy();
        while ($cursor->lte($end)) {
            $key = $cursor->toDateString();
            $labels[] = $cursor->format('M d');
            $values[] = (int) ($raw[$key] ?? 0);
            $cursor->addDay();
        }

        return [
            'datasets' => [
                [
                    'label' => 'Orders',
                    'data' => $values,
                    'borderColor' => '#0ea5e9',
                    'backgroundColor' => 'rgba(14,165,233,0.15)',
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
