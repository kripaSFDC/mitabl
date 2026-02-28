<?php

namespace App\Filament\Pages;

use App\Services\AdminAuditLogService;
use App\Services\SystemHealthService;
use Filament\Facades\Filament;
use Filament\Notifications\Notification;
use Filament\Pages\Page;

class SystemHealthPage extends Page
{
    protected static ?string $navigationIcon = 'heroicon-o-heart';

    protected static ?string $navigationGroup = 'Platform';

    protected static ?int $navigationSort = 30;

    protected static ?string $title = 'System Health';

    protected static string $view = 'filament.pages.system-health-page';

    public array $healthSummary = [];

    public function mount(SystemHealthService $healthService): void
    {
        $this->healthSummary = $healthService->runChecks();
    }

    public function refreshChecks(SystemHealthService $healthService): void
    {
        $this->healthSummary = $healthService->runChecks();

        app(AdminAuditLogService::class)->log('system_health.refresh', request(), [
            'overall' => $this->healthSummary['overall'] ?? 'unknown',
            'failing_checks' => $this->healthSummary['failing_checks'] ?? null,
        ]);

        Notification::make()->title('System checks refreshed.')->success()->send();
    }

    public static function canAccess(): bool
    {
        return (bool) Filament::auth()->user()?->can('health.view');
    }
}

