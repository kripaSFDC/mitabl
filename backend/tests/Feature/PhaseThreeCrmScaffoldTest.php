<?php

namespace Tests\Feature;

use Tests\TestCase;

class PhaseThreeCrmScaffoldTest extends TestCase
{
    public function test_phase_three_crm_files_exist(): void
    {
        $requiredFiles = [
            'app/Filament/Resources/SupportTicketResource.php',
            'app/Filament/Resources/SupportTicketResource/Pages/ListSupportTickets.php',
            'app/Filament/Resources/PreRegistrationResource.php',
            'app/Filament/Resources/PreRegistrationResource/Pages/ListPreRegistrations.php',
            'app/Http/Controllers/Api/SupportTicketController.php',
            'app/Services/SupportTicketService.php',
            'app/Services/PreRegistrationService.php',
            'app/Services/CrmCommunicationService.php',
            'app/Console/Commands/SupportTicketSlaScanCommand.php',
            'app/Jobs/ProcessSupportTicketSlaEscalationJob.php',
            'app/Filament/Widgets/CrmQueueStatsWidget.php',
            'app/Filament/Widgets/CrmAgingBucketsChart.php',
            'app/Models/CrmCommunicationLog.php',
            'database/migrations/2026_02_28_000014_enhance_crm_phase3_tables.php',
            'config/support.php',
            'resources/views/Mail/supportTicketReply.blade.php',
            'resources/views/Mail/supportTicketEscalated.blade.php',
            'resources/views/Mail/preRegistrationAcknowledged.blade.php',
        ];

        foreach ($requiredFiles as $path) {
            $this->assertFileExists(base_path($path), 'Missing required Phase 3 scaffold file: ' . $path);
        }
    }

    public function test_phase_three_routes_and_scheduler_hooks_exist(): void
    {
        $apiRoutes = (string) file_get_contents(base_path('routes/api.php'));
        $kernel = (string) file_get_contents(app_path('Console/Kernel.php'));
        $panelProvider = (string) file_get_contents(app_path('Providers/Filament/AdminPanelProvider.php'));

        $this->assertStringContainsString("Route::post('support/ticket'", $apiRoutes);
        $this->assertStringContainsString("Route::get('support/ticket/{id}'", $apiRoutes);
        $this->assertStringContainsString("Route::post('support/ticket/{id}/reply'", $apiRoutes);
        $this->assertStringContainsString("support:sla:scan", $kernel);
        $this->assertStringContainsString('CrmQueueStatsWidget::class', $panelProvider);
        $this->assertStringContainsString('CrmAgingBucketsChart::class', $panelProvider);
    }
}
