<?php

namespace App\Filament\Pages;

use App\Models\CrmCommunicationLog;
use App\Services\AdminAuditLogService;
use App\Services\CrmCommunicationService;
use Filament\Facades\Filament;
use Filament\Notifications\Notification;
use Filament\Pages\Page;

class IntegrationLogsPage extends Page
{
    protected static ?string $navigationIcon = 'heroicon-o-circle-stack';
    protected static ?string $navigationGroup = 'Platform';
    protected static ?int $navigationSort = 45;
    protected static ?string $title = 'Integration Logs';
    protected static string $view = 'filament.pages.integration-logs-page';

    public array $logs = [];
    public bool $canManage = false;

    public function mount(): void
    {
        $this->canManage = (bool) Filament::auth()->user()?->can('integration_logs.manage');
        $this->loadLogs();
    }

    public function refresh(): void
    {
        $this->loadLogs();

        app(AdminAuditLogService::class)->log('integration_logs.refresh', request(), [
            'visible_logs' => count($this->logs),
        ]);
    }

    public function replayFailed(int $logId): void
    {
        if (! $this->canManage) {
            Notification::make()->title('You do not have permission to replay integration events.')->danger()->send();
            return;
        }

        $log = CrmCommunicationLog::query()->with('supportTicket.messages')->find($logId);
        if (! $log || ! in_array($log->status, ['failed', 'error'], true)) {
            Notification::make()->title('Only failed integration logs can be replayed.')->warning()->send();
            return;
        }

        try {
            $ticket = $log->supportTicket;
            if (! $ticket) {
                throw new \RuntimeException('No support ticket is associated with this integration log.');
            }

            $service = app(CrmCommunicationService::class);
            if ($log->template === 'support_ticket_acknowledged') {
                $service->sendTicketAcknowledgement($ticket);
            } elseif ($log->template === 'support_ticket_reply') {
                $message = (string) optional($ticket->messages->where('sender_type', 'admin')->sortByDesc('id')->first())->message;
                $service->sendTicketReply($ticket, $message !== '' ? $message : 'Follow-up from support team.');
            } else {
                throw new \RuntimeException('Replay is currently supported for support acknowledgement/reply templates only.');
            }

            $metadata = is_array($log->metadata) ? $log->metadata : [];
            $metadata['manual_replay_requested_at'] = now()->toISOString();
            $metadata['manual_replay_requested_by'] = Filament::auth()->id();
            $log->metadata = $metadata;
            $log->save();

            app(AdminAuditLogService::class)->log('integration_logs.replay', request(), [
                'log_id' => $log->id,
                'template' => $log->template,
            ]);

            Notification::make()->title('Replay queued.')->success()->send();
            $this->loadLogs();
        } catch (\Throwable $throwable) {
            Notification::make()->title('Replay failed: ' . $throwable->getMessage())->danger()->send();
        }
    }

    private function loadLogs(): void
    {
        try {
            $this->logs = CrmCommunicationLog::query()
                ->latest('id')
                ->limit(200)
                ->get()
                ->map(function (CrmCommunicationLog $log): array {
                    $metadata = is_array($log->metadata) ? $log->metadata : [];

                    return [
                        'id' => $log->id,
                        'channel' => (string) $log->channel,
                        'template' => (string) $log->template,
                        'recipient' => (string) $log->recipient,
                        'status' => (string) $log->status,
                        'response_status' => data_get($metadata, 'response_status'),
                        'error_body' => (string) data_get($metadata, 'error_body', ''),
                        'retry_attempts' => (int) data_get($metadata, 'retry_attempts', 0),
                        'created_at' => optional($log->created_at)?->toDateTimeString(),
                    ];
                })
                ->all();
        } catch (\Throwable $throwable) {
            $this->logs = [];
        }
    }

    public static function canAccess(): bool
    {
        return (bool) Filament::auth()->user()?->can('integration_logs.view');
    }
}
