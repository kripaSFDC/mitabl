<?php

namespace App\Console\Commands;

use App\Jobs\ProcessSupportTicketSlaEscalationJob;
use App\Models\SupportTicket;
use Illuminate\Console\Command;

class SupportTicketSlaScanCommand extends Command
{
    protected $signature = 'support:sla:scan';

    protected $description = 'Scan support tickets and enqueue SLA escalation jobs';

    public function handle(): int
    {
        $openStatuses = [
            SupportTicket::STATUS_OPEN,
            SupportTicket::STATUS_IN_PROGRESS,
            SupportTicket::STATUS_PENDING_USER,
            SupportTicket::STATUS_RESOLVED,
        ];

        $firstResponseBreaches = SupportTicket::query()
            ->whereIn('status', $openStatuses)
            ->whereNull('first_responded_at')
            ->whereNull('resolved_at')
            ->whereNull('first_response_breached_at')
            ->whereNotNull('first_response_due_at')
            ->where('first_response_due_at', '<=', now())
            ->pluck('id');

        foreach ($firstResponseBreaches as $ticketId) {
            ProcessSupportTicketSlaEscalationJob::dispatch((int) $ticketId, 'first_response');
        }

        $resolutionBreaches = SupportTicket::query()
            ->whereIn('status', $openStatuses)
            ->whereNull('resolved_at')
            ->whereNull('resolution_breached_at')
            ->whereNotNull('resolution_due_at')
            ->where('resolution_due_at', '<=', now())
            ->pluck('id');

        foreach ($resolutionBreaches as $ticketId) {
            ProcessSupportTicketSlaEscalationJob::dispatch((int) $ticketId, 'resolution');
        }

        $this->info(sprintf(
            'Enqueued SLA checks: first-response=%d, resolution=%d',
            $firstResponseBreaches->count(),
            $resolutionBreaches->count()
        ));

        return self::SUCCESS;
    }
}
