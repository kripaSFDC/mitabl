<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Schema;
// use Database\Seeders\CookingStylesSeeder;
// use Database\Seeders\SpecialDietsSeeder;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     *
     * @return void
     */
    public function run()
    {
        // \App\Models\User::factory(10)->create();
        $permissionTableNames = config('permission.table_names', []);
        $rolesTable = $permissionTableNames['roles'] ?? 'admin_roles';
        $permissionsTable = $permissionTableNames['permissions'] ?? 'admin_permissions';

        if (Schema::hasTable('roles')) {
            $this->call(CoreUserRolesSeeder::class);
        }

        if (Schema::hasTable('cooking_styles')) {
            $this->call(CookingStylesSeeder::class);
        }

        if (Schema::hasTable('special_diets')) {
            $this->call(SpecialDietsSeeder::class);
        }

        if (Schema::hasTable($rolesTable) && Schema::hasTable($permissionsTable)) {
            $this->call(AdminRolePermissionSeeder::class);
        }

        if (Schema::hasTable('admin_users') && Schema::hasTable($rolesTable)) {
            $this->call(AdminUserSeeder::class);
            $this->call(AdminRbacTestUsersSeeder::class);
        }

        if (Schema::hasTable('tags')) {
            $this->call(TagTaxonomySeeder::class);
        }
    }
}
