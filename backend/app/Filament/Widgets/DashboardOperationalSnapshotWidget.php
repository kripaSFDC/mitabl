<?php

namespace App\Filament\Widgets;

use Filament\Facades\Filament;
use Filament\Widgets\StatsOverviewWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

class DashboardOperationalSnapshotWidget extends StatsOverviewWidget
{
    protected static ?int $sort = 3;

    public static function canView(): bool
    {
        return (bool) Filament::auth()->user()?->can('dashboard.view');
    }

    protected function getStats(): array
    {
        $foodies = DB::table('users')->where('role_id', 3)->count();
        $cooks = DB::table('users')->where('role_id', 2)->count();
        $activeKitchens = DB::table('mikitchns')->where('status', 1)->count();
        $ordersToday = DB::table('orders')->whereDate('delivery_date', now()->toDateString())->count();

        $monthStart = Carbon::now()->startOfMonth();
        $monthEnd = Carbon::now()->endOfMonth();
        $revenueThisMonth = (float) DB::table('payments')
            ->join('orders', 'orders.id', '=', 'payments.order_id')
            ->where('payments.confirm', 1)
            ->where('orders.status', 3)
            ->whereBetween('payments.created_at', [$monthStart, $monthEnd])
            ->sum('payments.amount');

        return [
            Stat::make('Foodies', (string) $foodies)
                ->description('Users (role_id=3)')
                ->color('info'),
            Stat::make('Cooks', (string) $cooks)
                ->description('Users (role_id=2)')
                ->color('info'),
            Stat::make('Active kitchens', (string) $activeKitchens)
                ->description('mikitchns.status=1')
                ->color($activeKitchens > 0 ? 'success' : 'warning'),
            Stat::make('Orders today', (string) $ordersToday)
                ->description('orders.delivery_date=today')
                ->color($ordersToday > 0 ? 'success' : 'gray'),
            Stat::make('Revenue this month', '$' . number_format($revenueThisMonth, 2))
                ->description('payments joined confirmed orders')
                ->color('success'),
        ];
    }
}
