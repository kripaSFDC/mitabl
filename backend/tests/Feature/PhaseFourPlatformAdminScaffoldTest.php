<?php

namespace Tests\Feature;

use Tests\TestCase;

class PhaseFourPlatformAdminScaffoldTest extends TestCase
{
    public function test_phase_four_platform_admin_files_exist(): void
    {
        $requiredFiles = [
            'app/Filament/Pages/PlatformSettingsPage.php',
            'resources/views/filament/pages/platform-settings-page.blade.php',
            'app/Filament/Resources/PolicyResource.php',
            'app/Filament/Resources/PolicyResource/Pages/ListPolicies.php',
            'app/Filament/Resources/PolicyResource/Pages/CreatePolicy.php',
            'app/Filament/Resources/PolicyResource/Pages/EditPolicy.php',
            'resources/views/filament/resources/policy-resource/diff-preview.blade.php',
            'app/Filament/Pages/SystemHealthPage.php',
            'resources/views/filament/pages/system-health-page.blade.php',
            'app/Filament/Pages/QueueOpsPage.php',
            'resources/views/filament/pages/queue-ops-page.blade.php',
            'app/Filament/Pages/IntegrationLogsPage.php',
            'resources/views/filament/pages/integration-logs-page.blade.php',
            'app/Filament/Pages/SecurityAdminPage.php',
            'resources/views/filament/pages/security-admin-page.blade.php',
            'app/Filament/Widgets/SlaHealthWidget.php',
            'app/Filament/Widgets/SystemHealthSummaryWidget.php',
            'app/Services/SystemHealthService.php',
            'app/Console/Commands/PlatformSyntheticHealthCheckCommand.php',
            'app/Services/AdminAuditLogService.php',
            'app/Http/Middleware/RecordAdminAction.php',
            'app/Models/AdminActionLog.php',
            'app/Filament/Resources/AdminActionLogResource.php',
            'app/Filament/Resources/AuditLogResource.php',
            'app/Models/InternalNote.php',
            'app/Models/Tag.php',
            'app/Models/WatchSubscription.php',
            'database/migrations/2026_02_28_000021_create_admin_action_logs_table.php',
            'database/migrations/2026_02_28_000016_create_collaboration_tables.php',
        ];

        foreach ($requiredFiles as $path) {
            $this->assertFileExists(base_path($path), 'Missing required Phase 4 file: ' . $path);
        }
    }

    public function test_phase_four_widgets_and_audit_middleware_are_registered_in_admin_panel(): void
    {
        $panelProvider = (string) file_get_contents(app_path('Providers/Filament/AdminPanelProvider.php'));

        $this->assertStringContainsString('SlaHealthWidget::class', $panelProvider);
        $this->assertStringContainsString('SystemHealthSummaryWidget::class', $panelProvider);
        $this->assertStringContainsString('RecordAdminAction::class', $panelProvider);
    }
}
