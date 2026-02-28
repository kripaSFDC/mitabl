<?php

namespace Tests\Feature;

use Tests\TestCase;

class PhaseOneTwoPermissionMatrixRegressionTest extends TestCase
{
    public function test_phase_two_permissions_exist_in_admin_permission_seed(): void
    {
        $seeder = (string) file_get_contents(database_path('seeders/AdminRolePermissionSeeder.php'));

        $requiredPermissions = [
            'certificates.view',
            'certificates.review',
            'users.view',
            'users.edit',
            'users.suspend',
            'kitchens.view',
            'kitchens.edit',
            'orders.view',
            'orders.override_status',
            'orders.refund',
            'promo_codes.view',
            'promo_codes.edit',
        ];

        foreach ($requiredPermissions as $permission) {
            $this->assertStringContainsString("'{$permission}'", $seeder);
        }
    }

    public function test_phase_two_roles_have_expected_capability_slices(): void
    {
        $seeder = (string) file_get_contents(database_path('seeders/AdminRolePermissionSeeder.php'));

        $this->assertStringContainsString("'operations' => [", $seeder);
        $this->assertStringContainsString("'orders.override_status'", $seeder);
        $this->assertStringContainsString("'orders.refund'", $seeder);

        $this->assertStringContainsString("'customer_service' => [", $seeder);
        $this->assertStringContainsString("'users.view'", $seeder);
        $this->assertStringContainsString("'orders.view'", $seeder);

        $this->assertStringContainsString("'finance_readonly' => [", $seeder);
        $this->assertStringContainsString("'payments.view'", $seeder);
    }
}
