<?php

namespace App\Jobs;

use App\Models\SupportTicket;
use App\Services\SupportTicketService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\DB;

class ProcessSupportTicketSlaEscalationJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(private int $ticketId, private string $reason)
    {
        $this->onQueue('crm-escalations');
    }

    public function handle(SupportTicketService $supportTicketService): void
    {
        DB::transaction(function () use ($supportTicketService): void {
            $ticket = SupportTicket::query()->lockForUpdate()->find($this->ticketId);
            if (! $ticket) {
                return;
            }

            if (
                $this->reason === 'first_response'
                && $ticket->first_response_breached_at === null
                && $ticket->first_responded_at === null
                && $ticket->resolved_at === null
            ) {
                $ticket->first_response_breached_at = now();
                $ticket->save();
                $supportTicketService->markEscalated($ticket, 'First response SLA breached');
            }

            if ($this->reason === 'resolution' && $ticket->resolution_breached_at === null && $ticket->resolved_at === null) {
                $ticket->resolution_breached_at = now();
                $ticket->save();
                $supportTicketService->markEscalated($ticket, 'Resolution SLA breached');
            }
        });
    }
}
