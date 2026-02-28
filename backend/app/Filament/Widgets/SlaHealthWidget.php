<?php

namespace App\Filament\Widgets;

use App\Models\SupportTicket;
use Filament\Facades\Filament;
use Filament\Widgets\StatsOverviewWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;

class SlaHealthWidget extends StatsOverviewWidget
{
    protected static ?int $sort = 6;

    protected static ?string $pollingInterval = '30s';

    public static function canView(): bool
    {
        return (bool) Filament::auth()->user()?->can('dashboard.view');
    }

    protected function getStats(): array
    {
        $activeStatuses = [
            SupportTicket::STATUS_OPEN,
            SupportTicket::STATUS_IN_PROGRESS,
            SupportTicket::STATUS_PENDING_USER,
        ];

        $now = now();
        $atRiskWindow = now()->addMinutes(30);

        $openTickets = SupportTicket::query()
            ->whereIn('status', $activeStatuses)
            ->count();

        $firstResponseBreached = SupportTicket::query()
            ->whereIn('status', $activeStatuses)
            ->whereNull('first_responded_at')
            ->whereNotNull('first_response_due_at')
            ->where('first_response_due_at', '<', $now)
            ->count();

        $resolutionBreached = SupportTicket::query()
            ->whereIn('status', $activeStatuses)
            ->whereNull('resolved_at')
            ->whereNotNull('resolution_due_at')
            ->where('resolution_due_at', '<', $now)
            ->count();

        $slaAtRisk = SupportTicket::query()
            ->whereIn('status', $activeStatuses)
            ->where(function ($query) use ($atRiskWindow) {
                $query->where(function ($first) use ($atRiskWindow) {
                    $first->whereNull('first_responded_at')
                        ->whereNotNull('first_response_due_at')
                        ->whereBetween('first_response_due_at', [now(), $atRiskWindow]);
                })->orWhere(function ($resolution) use ($atRiskWindow) {
                    $resolution->whereNull('resolved_at')
                        ->whereNotNull('resolution_due_at')
                        ->whereBetween('resolution_due_at', [now(), $atRiskWindow]);
                });
            })
            ->count();

        return [
            Stat::make('Open active tickets', (string) $openTickets)
                ->description('Open/in-progress/pending-user queue')
                ->color($openTickets > 0 ? 'warning' : 'success'),
            Stat::make('First-response breached', (string) $firstResponseBreached)
                ->description('Tickets past first response target')
                ->color($firstResponseBreached > 0 ? 'danger' : 'success'),
            Stat::make('Resolution breached', (string) $resolutionBreached)
                ->description('Tickets past resolution target')
                ->color($resolutionBreached > 0 ? 'danger' : 'success'),
            Stat::make('SLA at risk (30m)', (string) $slaAtRisk)
                ->description('Likely to breach soon')
                ->color($slaAtRisk > 0 ? 'warning' : 'success'),
        ];
    }
}
