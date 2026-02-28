<?php

namespace App\Filament\Pages;

use App\Models\CrmCommunicationLog;
use App\Services\AdminAuditLogService;
use Filament\Facades\Filament;
use Filament\Pages\Page;

class IntegrationLogsPage extends Page
{
    protected static ?string $navigationIcon = 'heroicon-o-circle-stack';

    protected static ?string $navigationGroup = 'Platform';

    protected static ?int $navigationSort = 45;

    protected static ?string $title = 'Integration Logs';

    protected static string $view = 'filament.pages.integration-logs-page';

    public array $logs = [];

    public function mount(): void
    {
        $this->loadLogs();
    }

    public function refresh(): void
    {
        $this->loadLogs();

        app(AdminAuditLogService::class)->log('integration_logs.refresh', request(), [
            'visible_logs' => count($this->logs),
        ]);
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
