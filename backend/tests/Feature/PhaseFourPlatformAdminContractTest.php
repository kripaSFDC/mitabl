<?php

namespace Tests\Feature;

use Tests\TestCase;

class PhaseFourPlatformAdminContractTest extends TestCase
{
    public function test_policy_resource_contains_versioning_workflow_actions(): void
    {
        $resource = (string) file_get_contents(app_path('Filament/Resources/PolicyResource.php'));
        $createPage = (string) file_get_contents(app_path('Filament/Resources/PolicyResource/Pages/CreatePolicy.php'));
        $editPage = (string) file_get_contents(app_path('Filament/Resources/PolicyResource/Pages/EditPolicy.php'));

        $this->assertStringContainsString("Action::make('publish')", $resource);
        $this->assertStringContainsString("Action::make('view_diff')", $resource);
        $this->assertStringContainsString("Action::make('create_version')", $resource);
        $this->assertStringContainsString("Action::make('rollback')", $resource);
        $this->assertStringContainsString('PolicyChangeLog::create', $resource);
        $this->assertStringContainsString('hasActiveVersion', $resource);
        $this->assertStringContainsString('lockForUpdate', $resource);
        $this->assertStringContainsString('json_decode', $createPage);
        $this->assertStringContainsString('nextVersion', $createPage);
        $this->assertStringContainsString('Active policy versions are immutable', $editPage);
        $this->assertStringContainsString('before_payload', $editPage);
    }

    public function test_platform_admin_pages_include_required_health_and_queue_controls(): void
    {
        $settingsPage = (string) file_get_contents(app_path('Filament/Pages/PlatformSettingsPage.php'));
        $healthPage = (string) file_get_contents(app_path('Filament/Pages/SystemHealthPage.php'));
        $queuePage = (string) file_get_contents(app_path('Filament/Pages/QueueOpsPage.php'));
        $securityPage = (string) file_get_contents(app_path('Filament/Pages/SecurityAdminPage.php'));
        $securityView = (string) file_get_contents(resource_path('views/filament/pages/security-admin-page.blade.php'));
        $queueView = (string) file_get_contents(resource_path('views/filament/pages/queue-ops-page.blade.php'));
        $integrationPage = (string) file_get_contents(app_path('Filament/Pages/IntegrationLogsPage.php'));
        $healthService = (string) file_get_contents(app_path('Services/SystemHealthService.php'));
        $settingRegistry = (string) file_get_contents(app_path('Services/PlatformSettingRegistry.php'));
        $kernel = (string) file_get_contents(app_path('Console/Kernel.php'));
        $syntheticCommand = (string) file_get_contents(app_path('Console/Commands/PlatformSyntheticHealthCheckCommand.php'));
        $activateDuePolicyCommand = (string) file_get_contents(app_path('Console/Commands/ActivateDuePoliciesCommand.php'));
        $apiRoutes = (string) file_get_contents(base_path('routes/api.php'));

        $this->assertStringContainsString('class PlatformSettingsPage', $settingsPage);
        $this->assertStringContainsString("Repeater::make('settings')", $settingsPage);
        $this->assertStringContainsString("Textarea::make('change_reason')", $settingsPage);
        $this->assertStringContainsString('function save()', $settingsPage);
        $this->assertStringContainsString('Duplicate setting keys are not allowed', $settingsPage);
        $this->assertStringContainsString('High-risk settings require publish-level approval permission', $settingsPage);
        $this->assertStringContainsString('Change reason is required for high-risk settings', $settingsPage);
        $this->assertStringContainsString('isHighRiskKey', $settingsPage);
        $this->assertStringContainsString('calculateRetainedIds', $settingsPage);
        $this->assertStringContainsString('resolveExistingSetting', $settingsPage);
        $this->assertStringContainsString('strtolower', $settingsPage);
        $this->assertStringContainsString('catch (ValidationException', $settingsPage);
        $this->assertStringContainsString('isNewRecord', $settingsPage);
        $this->assertStringContainsString('PlatformSettingRegistry', $settingsPage);
        $this->assertStringContainsString("'onboarding.enabled'", $settingRegistry);
        $this->assertStringContainsString("'maintenance.read_only_mode'", $settingRegistry);
        $this->assertStringContainsString("'incident.degraded_mode'", $settingRegistry);
        $this->assertStringContainsString('refreshChecks', $healthPage);
        $this->assertStringContainsString('runChecks', $healthService);
        $this->assertStringContainsString('checkDatabase', $healthService);
        $this->assertStringContainsString('checkQueue', $healthService);
        $this->assertStringContainsString('checkQueueProcessing', $healthService);
        $this->assertStringContainsString('checkMail', $healthService);
        $this->assertStringContainsString('Mail::mailer', $healthService);
        $this->assertStringContainsString('checkTicketIntake', $healthService);
        $this->assertStringContainsString('checkStorage', $healthService);
        $this->assertStringContainsString('checkFcm', $healthService);
        $this->assertStringContainsString('checkStripe', $healthService);
        $this->assertStringContainsString('checkSchedulerHeartbeat', $healthService);
        $this->assertStringContainsString('checkDegradedMode', $healthService);
        $this->assertStringContainsString('platform:health:synthetic', $kernel);
        $this->assertStringContainsString('platform:policies:activate-due', $kernel);
        $this->assertStringContainsString('class PlatformSyntheticHealthCheckCommand', $syntheticCommand);
        $this->assertStringContainsString('class ActivateDuePoliciesCommand', $activateDuePolicyCommand);
        $this->assertStringContainsString('retryJob', $queuePage);
        $this->assertStringContainsString('requeueJob', $queuePage);
        $this->assertStringContainsString('discardJob', $queuePage);
        $this->assertStringContainsString('retryAll', $queuePage);
        $this->assertStringContainsString('loadMetrics', $queuePage);
        $this->assertStringContainsString('canManageQueue', $queuePage);
        $this->assertStringContainsString('@if ($canManageQueue)', $queueView);
        $this->assertStringContainsString('Queue depth', $queueView);
        $this->assertStringContainsString('class IntegrationLogsPage', $integrationPage);
        $this->assertStringContainsString('class SecurityAdminPage', $securityPage);
        $this->assertStringContainsString('dormantAdmins', $securityPage);
        $this->assertStringContainsString("iam.manage", $securityPage);
        $this->assertStringContainsString('Dormant Admins', $securityView);
        $this->assertStringContainsString('/health/live', $apiRoutes);
        $this->assertStringContainsString('/health/ready', $apiRoutes);
    }

    public function test_admin_action_logs_are_immutable_and_audited(): void
    {
        $model = (string) file_get_contents(app_path('Models/AdminActionLog.php'));
        $auditService = (string) file_get_contents(app_path('Services/AdminAuditLogService.php'));
        $middleware = (string) file_get_contents(app_path('Http/Middleware/RecordAdminAction.php'));
        $resource = (string) file_get_contents(app_path('Filament/Resources/AdminActionLogResource.php'));

        $this->assertStringContainsString('Admin action logs are immutable and cannot be updated', $model);
        $this->assertStringContainsString('Admin action logs are immutable and cannot be deleted', $model);
        $this->assertStringContainsString('sanitizePayload', $auditService);
        $this->assertStringContainsString('Auth::guard(\'admin\')->check()', $middleware);
        $this->assertStringContainsString('admin.livewire.', $middleware);
        $this->assertStringContainsString('canViewAny', $resource);
        $this->assertStringContainsString('audit_logs.view', $resource);
    }
}
