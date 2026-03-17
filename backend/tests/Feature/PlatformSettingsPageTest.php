<?php

namespace Tests\Feature;

use App\Filament\Pages\PlatformSettingsPage;
use App\Models\AdminUser;
use App\Models\PlatformSetting;
use App\Models\PlatformSettingChangeRequest;
use Database\Seeders\AdminRolePermissionSeeder;
use Filament\Facades\Filament;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Livewire\Livewire;
use Tests\TestCase;

class PlatformSettingsPageTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(AdminRolePermissionSeeder::class);
        Filament::setCurrentPanel(Filament::getPanel('admin'));
    }

    public function test_super_admin_can_save_multiple_smtp_string_settings_at_once(): void
    {
        $admin = $this->makeAdmin('super_admin');
        $this->actingAs($admin, 'admin');

        $rows = app(\App\Services\PlatformSettingRegistry::class)->forAdminForm();
        $rows = $this->replaceSettingValue($rows, 'email.smtp.host', 'value_string', 'smtp.example.test');
        $rows = $this->replaceSettingValue($rows, 'email.smtp.username', 'value_string', 'smtp-user');

        Livewire::test(PlatformSettingsPage::class)
            ->set('data.settings', $rows)
            ->call('save');

        $this->assertSame(['value' => 'smtp.example.test'], PlatformSetting::query()->where('key', 'email.smtp.host')->first()?->value);
        $this->assertSame(['value' => 'smtp-user'], PlatformSetting::query()->where('key', 'email.smtp.username')->first()?->value);
    }

    public function test_save_persists_low_risk_changes_while_high_risk_changes_wait_for_approval(): void
    {
        $admin = $this->makeAdmin('super_admin');
        $this->actingAs($admin, 'admin');

        $rows = app(\App\Services\PlatformSettingRegistry::class)->forAdminForm();
        $rows = $this->replaceSettingValue($rows, 'support.honeypot_field', 'value_string', 'contact_company');
        $rows = $this->replaceSettingValue($rows, 'session.lifetime_minutes', 'value_integer', 45);

        Livewire::test(PlatformSettingsPage::class)
            ->set('data.settings', $rows)
            ->set('data.change_reason', 'Tighten session timeout')
            ->set('data.current_password', 'password')
            ->call('save');

        $this->assertSame(['value' => 'contact_company'], PlatformSetting::query()->where('key', 'support.honeypot_field')->first()?->value);
        $this->assertNull(PlatformSetting::query()->where('key', 'session.lifetime_minutes')->first());

        $changeRequest = PlatformSettingChangeRequest::query()->where('setting_key', 'session.lifetime_minutes')->first();
        $this->assertNotNull($changeRequest);
        $this->assertSame(PlatformSettingChangeRequest::STATUS_VALIDATED, $changeRequest->status);
        $this->assertSame(['value' => 45], $changeRequest->proposed_value);
    }

    public function test_second_admin_approval_activates_high_risk_request(): void
    {
        $requester = $this->makeAdmin('super_admin', 'requester@example.test');
        $approver = $this->makeAdmin('super_admin', 'approver@example.test');

        $request = PlatformSettingChangeRequest::query()->create([
            'setting_key' => 'session.lifetime_minutes',
            'proposed_value' => ['value' => 30],
            'value_type' => 'integer',
            'change_reason' => 'Shorten session lifetime',
            'risk_level' => 'high',
            'status' => PlatformSettingChangeRequest::STATUS_VALIDATED,
            'requested_by' => $requester->id,
            'validated_at' => now(),
        ]);

        $this->actingAs($approver, 'admin');

        Livewire::test(PlatformSettingsPage::class)
            ->call('approveRequest', $request->id);

        $request->refresh();

        $this->assertSame(PlatformSettingChangeRequest::STATUS_ACTIVATED, $request->status);
        $this->assertSame($approver->id, $request->approved_by);
        $this->assertSame($approver->id, $request->activated_by);
        $this->assertSame(['value' => 30], PlatformSetting::query()->where('key', 'session.lifetime_minutes')->first()?->value);
    }

    public function test_pending_high_risk_request_does_not_block_unrelated_low_risk_save_or_duplicate_requests(): void
    {
        $admin = $this->makeAdmin('super_admin');
        $this->actingAs($admin, 'admin');

        PlatformSettingChangeRequest::query()->create([
            'setting_key' => 'session.lifetime_minutes',
            'proposed_value' => ['value' => 45],
            'value_type' => 'integer',
            'description' => 'Session idle timeout in minutes before logout.',
            'change_reason' => 'Existing pending request',
            'risk_level' => 'high',
            'status' => PlatformSettingChangeRequest::STATUS_VALIDATED,
            'requested_by' => $admin->id,
            'validated_at' => now(),
        ]);

        $rows = app(\App\Services\PlatformSettingRegistry::class)->forAdminForm();
        $rows = $this->replaceSettingValue($rows, 'support.honeypot_field', 'value_string', 'contact_company');

        Livewire::test(PlatformSettingsPage::class)
            ->set('data.settings', $rows)
            ->call('save');

        $this->assertSame(['value' => 'contact_company'], PlatformSetting::query()->where('key', 'support.honeypot_field')->first()?->value);
        $this->assertCount(1, PlatformSettingChangeRequest::query()->where('setting_key', 'session.lifetime_minutes')->get());
    }

    public function test_high_risk_description_change_is_preserved_until_activation(): void
    {
        $requester = $this->makeAdmin('super_admin', 'desc-requester@example.test');
        $approver = $this->makeAdmin('super_admin', 'desc-approver@example.test');

        $this->actingAs($requester, 'admin');

        $rows = app(\App\Services\PlatformSettingRegistry::class)->forAdminForm();
        $rows = $this->replaceSettingValue($rows, 'session.lifetime_minutes', 'value_integer', 30);
        $rows = $this->replaceSettingValue($rows, 'session.lifetime_minutes', 'description', 'Short admin session timeout');

        Livewire::test(PlatformSettingsPage::class)
            ->set('data.settings', $rows)
            ->set('data.change_reason', 'Update timeout guidance')
            ->set('data.current_password', 'password')
            ->call('save');

        $request = PlatformSettingChangeRequest::query()->where('setting_key', 'session.lifetime_minutes')->first();

        $this->assertNotNull($request);
        $this->assertSame('Short admin session timeout', $request->description);

        $this->actingAs($approver, 'admin');

        Livewire::test(PlatformSettingsPage::class)
            ->call('approveRequest', $request->id);

        $setting = PlatformSetting::query()->where('key', 'session.lifetime_minutes')->first();

        $this->assertNotNull($setting);
        $this->assertSame('Short admin session timeout', $setting->description);
    }

    /**
     * @param  array<int, array<string, mixed>>  $rows
     * @return array<int, array<string, mixed>>
     */
    private function replaceSettingValue(array $rows, string $key, string $field, mixed $value): array
    {
        foreach ($rows as &$row) {
            if (($row['key'] ?? null) !== $key) {
                continue;
            }

            $row[$field] = $value;
            break;
        }

        return $rows;
    }

    private function makeAdmin(string $role, ?string $email = null): AdminUser
    {
        $admin = AdminUser::query()->create([
            'name' => ucfirst(str_replace('_', ' ', $role)),
            'email' => $email ?? $role . '@example.test',
            'password' => Hash::make('password'),
            'is_active' => true,
        ]);

        $admin->assignRole($role);

        return $admin;
    }
}
