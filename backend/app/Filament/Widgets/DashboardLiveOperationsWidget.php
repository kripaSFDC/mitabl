<?php

namespace App\Filament\Widgets;

use App\Models\SupportTicket;
use Filament\Facades\Filament;
use Filament\Widgets\StatsOverviewWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;
use Illuminate\Support\Facades\DB;

class DashboardLiveOperationsWidget extends StatsOverviewWidget
{
    protected static ?int $sort = 4;

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

        $pendingCertificateApprovals = DB::table('certificates')->where('status', 0)->count();
        $openSupportTickets = DB::table('support_tickets')->whereIn('status', $activeStatuses)->count();

        $riskWindowMinutes = 30;
        $now = now();
        $windowEnd = now()->addMinutes($riskWindowMinutes);

        $slaAtRisk = DB::table('support_tickets')
            ->whereIn('status', $activeStatuses)
            ->where(function ($query) use ($now, $windowEnd) {
                $query->where(function ($first) use ($now, $windowEnd) {
                    $first->whereNull('first_responded_at')
                        ->whereNotNull('first_response_due_at')
                        ->whereBetween('first_response_due_at', [$now, $windowEnd]);
                })->orWhere(function ($resolution) use ($now, $windowEnd) {
                    $resolution->whereNull('resolved_at')
                        ->whereNotNull('resolution_due_at')
                        ->whereBetween('resolution_due_at', [$now, $windowEnd]);
                });
            })
            ->count();

        $slaOverdue = DB::table('support_tickets')
            ->whereIn('status', $activeStatuses)
            ->where(function ($query) use ($now) {
                $query->where(function ($first) use ($now) {
                    $first->whereNull('first_responded_at')
                        ->whereNotNull('first_response_due_at')
                        ->where('first_response_due_at', '<', $now);
                })->orWhere(function ($resolution) use ($now) {
                    $resolution->whereNull('resolved_at')
                        ->whereNotNull('resolution_due_at')
                        ->where('resolution_due_at', '<', $now);
                });
            })
            ->count();

        $failedJobs = 0;
        $queueLatencySeconds = 0;
        try {
            $failedJobs = DB::table('failed_jobs')->count();
            $oldestAvailableAt = DB::table('jobs')->min('available_at');
            if (is_numeric($oldestAvailableAt)) {
                $queueLatencySeconds = max(now()->timestamp - (int) $oldestAvailableAt, 0);
            }
        } catch (\Throwable $throwable) {
            $failedJobs = 0;
            $queueLatencySeconds = 0;
        }

        return [
            Stat::make('Pending certificate approvals', (string) $pendingCertificateApprovals)
                ->description('certificates.status=0')
                ->color($pendingCertificateApprovals > 0 ? 'warning' : 'success'),
            Stat::make('Open support tickets', (string) $openSupportTickets)
                ->description('open / in_progress / pending_user')
                ->color($openSupportTickets > 0 ? 'warning' : 'success'),
            Stat::make('SLA breach risk', (string) $slaAtRisk)
                ->description("Due in {$riskWindowMinutes}m: {$slaAtRisk}, overdue: {$slaOverdue}")
                ->color(($slaAtRisk + $slaOverdue) > 0 ? 'warning' : 'success'),
            Stat::make('Queue failed jobs', (string) $failedJobs)
                ->description('failed_jobs backlog')
                ->color($failedJobs > 0 ? 'danger' : 'success'),
            Stat::make('Queue latency snapshot', $queueLatencySeconds . 's')
                ->description('Oldest pending job wait')
                ->color($queueLatencySeconds > 300 ? 'warning' : 'success'),
        ];
    }
}
