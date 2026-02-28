<?php

namespace Tests\Feature;

use Tests\TestCase;

class AdminDesignComplianceRegressionTest extends TestCase
{
    public function test_mobile_api_does_not_expose_admin_financial_actions(): void
    {
        $apiRoutes = (string) file_get_contents(base_path('routes/api.php'));
        $userController = (string) file_get_contents(app_path('Http/Controllers/Api/User/UserController.php'));

        $this->assertStringNotContainsString("Route::post('fullrefund'", $apiRoutes);
        $this->assertStringNotContainsString("Route::post('topups'", $apiRoutes);
        $this->assertStringContainsString('Forbidden. Manual refunds are restricted to admin identities in the web admin panel.', $userController);
        $this->assertStringContainsString('Forbidden. Top-up operations are restricted to admin identities in the web admin panel.', $userController);
    }

    public function test_high_risk_actions_require_step_up_authentication(): void
    {
        $userResource = (string) file_get_contents(app_path('Filament/Resources/UserResource.php'));
        $orderResource = (string) file_get_contents(app_path('Filament/Resources/OrderResource.php'));
        $supportTicketResource = (string) file_get_contents(app_path('Filament/Resources/SupportTicketResource.php'));
        $policyResource = (string) file_get_contents(app_path('Filament/Resources/PolicyResource.php'));
        $platformSettingsPage = (string) file_get_contents(app_path('Filament/Pages/PlatformSettingsPage.php'));

        $this->assertStringContainsString("TextInput::make('current_password')", $userResource);
        $this->assertStringContainsString('validateCurrentPassword(', $userResource);
        $this->assertStringContainsString("Action::make('suspend')", $userResource);
        $this->assertStringContainsString("Action::make('unsuspend')", $userResource);

        $this->assertStringContainsString("TextInput::make('current_password')", $orderResource);
        $this->assertStringContainsString('validateCurrentPassword(', $orderResource);
        $this->assertStringContainsString("Action::make('override_status')", $orderResource);
        $this->assertStringContainsString("Action::make('refund_full')", $orderResource);

        $this->assertStringContainsString("Action::make('transition')", $supportTicketResource);
        $this->assertStringContainsString("TextInput::make('current_password')", $supportTicketResource);
        $this->assertStringContainsString('validateCurrentPassword(', $supportTicketResource);

        $this->assertStringContainsString("TextInput::make('current_password')", $policyResource);
        $this->assertStringContainsString('validateCurrentPassword(', $policyResource);
        $this->assertStringContainsString("Action::make('publish')", $policyResource);
        $this->assertStringContainsString("Action::make('rollback')", $policyResource);

        $this->assertStringContainsString("TextInput::make('current_password')", $platformSettingsPage);
        $this->assertStringContainsString('isHighRiskKey(', $platformSettingsPage);
        $this->assertStringContainsString('validateCurrentPassword(', $platformSettingsPage);
    }

    public function test_dashboard_widgets_cover_required_operational_metrics(): void
    {
        $panelProvider = (string) file_get_contents(app_path('Providers/Filament/AdminPanelProvider.php'));
        $snapshotWidget = (string) file_get_contents(app_path('Filament/Widgets/DashboardOperationalSnapshotWidget.php'));
        $liveWidget = (string) file_get_contents(app_path('Filament/Widgets/DashboardLiveOperationsWidget.php'));
        $integrationWidget = (string) file_get_contents(app_path('Filament/Widgets/IntegrationHealthWidget.php'));
        $crmQueueWidget = (string) file_get_contents(app_path('Filament/Widgets/CrmQueueStatsWidget.php'));
        $crmAgingWidget = (string) file_get_contents(app_path('Filament/Widgets/CrmAgingBucketsChart.php'));
        $ordersChart = (string) file_get_contents(app_path('Filament/Widgets/OrdersPerDayChartWidget.php'));
        $registrationsChart = (string) file_get_contents(app_path('Filament/Widgets/RegistrationsPerDayChartWidget.php'));

        $this->assertStringContainsString('DashboardOperationalSnapshotWidget::class', $panelProvider);
        $this->assertStringContainsString('DashboardLiveOperationsWidget::class', $panelProvider);
        $this->assertStringContainsString('IntegrationHealthWidget::class', $panelProvider);
        $this->assertStringContainsString('CrmQueueStatsWidget::class', $panelProvider);
        $this->assertStringContainsString('CrmAgingBucketsChart::class', $panelProvider);
        $this->assertStringContainsString('OrdersPerDayChartWidget::class', $panelProvider);
        $this->assertStringContainsString('RegistrationsPerDayChartWidget::class', $panelProvider);

        $this->assertStringContainsString("where('role_id', 3)", $snapshotWidget);
        $this->assertStringContainsString("where('role_id', 2)", $snapshotWidget);
        $this->assertStringContainsString("where('status', 1)", $snapshotWidget);
        $this->assertStringContainsString("whereDate('delivery_date'", $snapshotWidget);
        $this->assertStringContainsString("join('orders'", $snapshotWidget);
        $this->assertStringContainsString("where('payments.confirm', 1)", $snapshotWidget);

        $this->assertStringContainsString("protected static ?string \$pollingInterval = '30s';", $liveWidget);
        $this->assertStringContainsString("where('status', 0)", $liveWidget);
        $this->assertStringContainsString("whereIn('status'", $liveWidget);
        $this->assertStringContainsString("DB::table('failed_jobs')", $liveWidget);
        $this->assertStringContainsString("DB::table('jobs')", $liveWidget);

        $this->assertStringContainsString("protected static ?string \$pollingInterval = '30s';", $integrationWidget);
        $this->assertStringContainsString("mapCheckToStat(\$checks->get('mail')", $integrationWidget);
        $this->assertStringContainsString("mapCheckToStat(\$checks->get('storage')", $integrationWidget);
        $this->assertStringContainsString("mapCheckToStat(\$checks->get('fcm')", $integrationWidget);
        $this->assertStringContainsString("mapCheckToStat(\$checks->get('stripe')", $integrationWidget);
        $this->assertStringContainsString("can('dashboard.view')", $crmQueueWidget);
        $this->assertStringContainsString("can('dashboard.view')", $crmAgingWidget);

        $this->assertStringContainsString("DATE(delivery_date)", $ordersChart);
        $this->assertStringContainsString("subDays(29)", $ordersChart);
        $this->assertStringContainsString("DATE(created_at)", $registrationsChart);
        $this->assertStringContainsString("subDays(29)", $registrationsChart);
    }

    public function test_operations_role_excludes_manual_refund_permission(): void
    {
        $seeder = (string) file_get_contents(database_path('seeders/AdminRolePermissionSeeder.php'));

        $matched = preg_match("/'operations'\\s*=>\\s*\\[(.*?)\\],\\s*'customer_service'/s", $seeder, $matches);
        $this->assertSame(1, $matched, 'Failed to extract operations role permission block.');
        $operationsBlock = (string) ($matches[1] ?? '');

        $this->assertStringContainsString("'orders.override_status'", $operationsBlock);
        $this->assertStringNotContainsString("'orders.refund'", $operationsBlock);
    }

    public function test_payments_resource_is_read_only_and_permission_gated(): void
    {
        $resource = (string) file_get_contents(app_path('Filament/Resources/PaymentResource.php'));

        $this->assertStringContainsString("can('payments.view')", $resource);
        $this->assertStringContainsString("can('payments.refund')", $resource);
        $this->assertStringContainsString('public static function canCreate(): bool', $resource);
        $this->assertStringContainsString('return false;', $resource);
        $this->assertStringContainsString("Action::make('open_in_stripe')", $resource);
        $this->assertStringContainsString("Action::make('refund_full')", $resource);
    }
}
