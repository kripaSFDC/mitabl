<?php

namespace Tests\Feature;

use Tests\TestCase;

class AdminRbacTestUsersSeederTest extends TestCase
{
    public function test_database_seeder_calls_rbac_test_user_seeder(): void
    {
        $databaseSeeder = (string) file_get_contents(database_path('seeders/DatabaseSeeder.php'));

        $this->assertStringContainsString('AdminRbacTestUsersSeeder::class', $databaseSeeder);
    }

    public function test_rbac_test_user_seeder_covers_all_admin_roles_and_override_logic(): void
    {
        $seeder = (string) file_get_contents(database_path('seeders/AdminRbacTestUsersSeeder.php'));

        $this->assertStringContainsString("'super_admin'", $seeder);
        $this->assertStringContainsString("'platform_admin'", $seeder);
        $this->assertStringContainsString("'operations'", $seeder);
        $this->assertStringContainsString("'customer_service'", $seeder);
        $this->assertStringContainsString("'finance_readonly'", $seeder);

        $this->assertStringContainsString('$overrideExisting = false', $seeder);
        $this->assertStringContainsString('firstOrNew', $seeder);
    }
}
