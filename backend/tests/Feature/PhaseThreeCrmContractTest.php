<?php

namespace Tests\Feature;

use Tests\TestCase;

class PhaseThreeCrmContractTest extends TestCase
{
    public function test_support_ticket_resource_contains_required_workflow_actions(): void
    {
        $resource = (string) file_get_contents(app_path('Filament/Resources/SupportTicketResource.php'));
        $createPage = (string) file_get_contents(app_path('Filament/Resources/SupportTicketResource/Pages/CreateSupportTicket.php'));

        $this->assertStringContainsString("Action::make('assign_to_me')", $resource);
        $this->assertStringContainsString("Action::make('assign')", $resource);
        $this->assertStringContainsString("Action::make('reply')", $resource);
        $this->assertStringContainsString("Action::make('internal_note')", $resource);
        $this->assertStringContainsString("Action::make('resolve')", $resource);
        $this->assertStringContainsString("Action::make('transition')", $resource);
        $this->assertStringContainsString("Action::make('merge')", $resource);
        $this->assertStringContainsString("Action::make('split')", $resource);
        $this->assertStringContainsString("TernaryFilter::make('my_queue')", $resource);
        $this->assertStringContainsString("TernaryFilter::make('sla_risk')", $resource);
        $this->assertStringContainsString('public static function canEdit($record): bool', $resource);
        $this->assertStringContainsString('return false;', $resource);
        $this->assertStringContainsString('handleRecordCreation', $createPage);
        $this->assertStringContainsString('SupportTicketService', $createPage);
        $this->assertStringContainsString("'skip_duplicate_check' => true", $createPage);
    }
    public function test_phase_three_abuse_controls_and_sla_automation_are_present(): void
    {
        $supportController = (string) file_get_contents(app_path('Http/Controllers/Api/SupportTicketController.php'));
        $routeProvider = (string) file_get_contents(app_path('Providers/RouteServiceProvider.php'));
        $service = (string) file_get_contents(app_path('Services/SupportTicketService.php'));
        $command = (string) file_get_contents(app_path('Console/Commands/SupportTicketSlaScanCommand.php'));
        $preRegistrationService = (string) file_get_contents(app_path('Services/PreRegistrationService.php'));
        $eventProvider = (string) file_get_contents(app_path('Providers/EventServiceProvider.php'));
        $listener = (string) file_get_contents(app_path('Listeners/MarkCrmCommunicationDelivered.php'));

        $this->assertStringContainsString('support.honeypot_field', $supportController);
        $this->assertStringContainsString('validateCaptchaToken', $supportController);
        $this->assertStringContainsString('InvalidArgumentException', $supportController);
        $this->assertStringContainsString("RateLimiter::for('support-intake'", $routeProvider);
        $this->assertStringContainsString("->middleware('throttle:support-intake')", (string) file_get_contents(base_path('routes/api.php')));
        $this->assertStringContainsString('duplicate_window_minutes', $service);
        $this->assertStringContainsString('SupportTicketEscalatedNotification', $service);
        $this->assertStringContainsString('Terminal tickets cannot be reassigned.', $service);
        $this->assertStringContainsString('Only active tickets can be resolved.', $service);
        $this->assertStringContainsString('ProcessSupportTicketSlaEscalationJob::dispatch', $command);
        $this->assertStringContainsString('no-email', $preRegistrationService);
        $this->assertStringContainsString('no-phone', $preRegistrationService);
        $this->assertStringContainsString("'Illuminate\\Mail\\Events\\MessageSent'", $eventProvider);
        $this->assertStringContainsString('MarkCrmCommunicationDelivered::class', $eventProvider);
        $this->assertStringContainsString("->where('status', 'queued')", $listener);
        $this->assertStringContainsString("\$log->status = 'sent';", $listener);
    }
}
