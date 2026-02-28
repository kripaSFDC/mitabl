<?php

namespace Tests\Feature;

use App\Models\AdminUser;
use App\Models\PlatformSetting;
use App\Models\Policy;
use App\Models\PolicyChangeLog;
use App\Models\PreRegistration;
use App\Models\SupportTicket;
use App\Models\SupportTicketAttachment;
use App\Models\SupportTicketEvent;
use App\Models\SupportTicketMessage;
use Tests\TestCase;

class PhaseOneFoundationRegressionTest extends TestCase
{
    public function test_phase_one_dependencies_are_declared(): void
    {
        $composer = json_decode((string) file_get_contents(base_path('composer.json')), true);
        $require = $composer['require'] ?? [];

        $this->assertArrayHasKey('filament/filament', $require);
        $this->assertArrayHasKey('spatie/laravel-permission', $require);
    }

    public function test_admin_guard_provider_and_broker_are_separate(): void
    {
        $this->assertSame('admin_users', config('auth.guards.admin.provider'));
        $this->assertSame(AdminUser::class, config('auth.providers.admin_users.model'));
        $this->assertSame('admin_password_resets', config('auth.passwords.admin_users.table'));

        $panelProvider = (string) file_get_contents(app_path('Providers/Filament/AdminPanelProvider.php'));
        $this->assertStringContainsString("->authGuard('admin')", $panelProvider);
        $this->assertStringContainsString("->authPasswordBroker('admin_users')", $panelProvider);
    }

    public function test_filament_panel_provider_is_registered_and_branding_env_keys_exist(): void
    {
        $appConfig = (string) file_get_contents(config_path('app.php'));
        $envExample = (string) file_get_contents(base_path('.env.example'));

        $this->assertStringContainsString('App\\Providers\\Filament\\AdminPanelProvider::class', $appConfig);
        $this->assertStringContainsString('ADMIN_PANEL_PATH=', $envExample);
        $this->assertStringContainsString('ADMIN_BRAND_LOGO_URL=', $envExample);
    }

    public function test_admin_permission_tables_are_scoped(): void
    {
        $this->assertSame('admin_roles', config('permission.table_names.roles'));
        $this->assertSame('admin_permissions', config('permission.table_names.permissions'));
        $this->assertNotSame('default', config('permission.cache.store'));
    }

    public function test_phase_one_migration_files_exist(): void
    {
        $requiredMigrations = [
            '2026_02_28_000001_create_admin_users_table.php',
            '2026_02_28_000002_create_admin_permission_tables.php',
            '2026_02_28_000003_add_rejected_fields_to_certificates_table.php',
            '2026_02_28_000004_add_suspended_to_users_table.php',
            '2026_02_28_000005_create_support_tickets_table.php',
            '2026_02_28_000006_create_support_ticket_messages_table.php',
            '2026_02_28_000007_create_support_ticket_attachments_table.php',
            '2026_02_28_000008_create_support_ticket_events_table.php',
            '2026_02_28_000009_create_pre_registrations_table.php',
            '2026_02_28_000010_create_platform_settings_table.php',
            '2026_02_28_000011_create_policies_table.php',
            '2026_02_28_000012_create_policy_change_log_table.php',
            '2026_02_28_000013_create_admin_password_resets_table.php',
            '2026_02_28_000020_drop_sales_kitchens_table.php',
        ];

        foreach ($requiredMigrations as $file) {
            $this->assertFileExists(database_path('migrations/'.$file));
        }
    }

    public function test_phase_one_models_exist(): void
    {
        $this->assertTrue(class_exists(AdminUser::class));
        $this->assertTrue(class_exists(SupportTicket::class));
        $this->assertTrue(class_exists(SupportTicketMessage::class));
        $this->assertTrue(class_exists(SupportTicketAttachment::class));
        $this->assertTrue(class_exists(SupportTicketEvent::class));
        $this->assertTrue(class_exists(PreRegistration::class));
        $this->assertTrue(class_exists(PlatformSetting::class));
        $this->assertTrue(class_exists(Policy::class));
        $this->assertTrue(class_exists(PolicyChangeLog::class));
    }
}
