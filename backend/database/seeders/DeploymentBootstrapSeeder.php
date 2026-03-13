<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Schema;

class DeploymentBootstrapSeeder extends Seeder
{
    public function run(): void
    {
        // Mobile app auth depends on these legacy rows (users.role_id -> roles.id).
        if (Schema::hasTable('roles')) {
            $this->call(CoreUserRolesSeeder::class);
        }

        $permissionTableNames = config('permission.table_names', []);
        $adminRolesTable = $permissionTableNames['roles'] ?? 'admin_roles';
        $adminPermissionsTable = $permissionTableNames['permissions'] ?? 'admin_permissions';

        // CRM/admin access control for Filament panel.
        if (Schema::hasTable($adminRolesTable) && Schema::hasTable($adminPermissionsTable)) {
            $this->call(AdminRolePermissionSeeder::class);
        }

        // First-deploy bootstrap admin creation is idempotent and env-gated inside the seeder.
        if (Schema::hasTable('admin_users') && Schema::hasTable($adminRolesTable)) {
            $this->call(AdminUserSeeder::class);
        }
    }
}
