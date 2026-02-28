<?php

namespace App\Filament\Widgets;

use App\Models\SupportTicket;
use Filament\Widgets\StatsOverviewWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;

class CrmQueueStatsWidget extends StatsOverviewWidget
{
    protected static ?int $sort = 1;

    protected function getStats(): array
    {
        $openStatuses = [
            SupportTicket::STATUS_OPEN,
            SupportTicket::STATUS_IN_PROGRESS,
            SupportTicket::STATUS_PENDING_USER,
        ];

        $queueDepth = SupportTicket::query()->whereIn('status', $openStatuses)->count();
        $firstResponseBreached = SupportTicket::query()
            ->whereNull('first_responded_at')
            ->whereNotNull('first_response_due_at')
            ->where('first_response_due_at', '<=', now())
            ->count();
        $resolutionBreached = SupportTicket::query()
            ->whereNull('resolved_at')
            ->whereNotNull('resolution_due_at')
            ->where('resolution_due_at', '<=', now())
            ->count();
        $reopenedRate = $this->reopenedTicketRate();

        return [
            Stat::make('Queue depth', (string) $queueDepth)
                ->description('Open + in progress + pending user')
                ->color($queueDepth > 0 ? 'warning' : 'success'),
            Stat::make('First-response SLA breaches', (string) $firstResponseBreached)
                ->description('Breach count')
                ->color($firstResponseBreached > 0 ? 'danger' : 'success'),
            Stat::make('Resolution SLA breaches', (string) $resolutionBreached)
                ->description('Breach count')
                ->color($resolutionBreached > 0 ? 'danger' : 'success'),
            Stat::make('Reopened ticket rate (30d)', $reopenedRate . '%')
                ->description('Reopened / resolved')
                ->color((float) $reopenedRate >= 10.0 ? 'warning' : 'success'),
        ];
    }

    private function reopenedTicketRate(): string
    {
        $resolvedCount = SupportTicket::query()
            ->where('created_at', '>=', now()->subDays(30))
            ->whereNotNull('resolved_at')
            ->count();

        if ($resolvedCount === 0) {
            return '0.0';
        }

        $reopenedCount = SupportTicket::query()
            ->where('created_at', '>=', now()->subDays(30))
            ->where('reopened_count', '>', 0)
            ->count();

        return number_format(($reopenedCount / $resolvedCount) * 100, 1);
    }
}
