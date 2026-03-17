<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (DB::getDriverName() !== 'mysql' || ! Schema::hasTable('user_role_onboarding_checklists')) {
            return;
        }

        $column = DB::table('information_schema.columns')
            ->select(['column_type'])
            ->where('table_schema', DB::getDatabaseName())
            ->where('table_name', 'user_role_onboarding_checklists')
            ->where('column_name', 'role_id')
            ->first();

        if ($column && strtolower((string) $column->column_type) !== 'int(10) unsigned') {
            DB::statement('ALTER TABLE `user_role_onboarding_checklists` MODIFY `role_id` INT UNSIGNED NOT NULL');
        }

        $foreignKeyExists = DB::table('information_schema.table_constraints')
            ->where('table_schema', DB::getDatabaseName())
            ->where('table_name', 'user_role_onboarding_checklists')
            ->where('constraint_name', 'user_role_onboarding_checklists_role_id_foreign')
            ->exists();

        if (! $foreignKeyExists) {
            DB::statement('ALTER TABLE `user_role_onboarding_checklists` ADD CONSTRAINT `user_role_onboarding_checklists_role_id_foreign` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`) ON DELETE CASCADE');
        }
    }

    public function down(): void
    {
        if (DB::getDriverName() !== 'mysql' || ! Schema::hasTable('user_role_onboarding_checklists')) {
            return;
        }

        $foreignKeyExists = DB::table('information_schema.table_constraints')
            ->where('table_schema', DB::getDatabaseName())
            ->where('table_name', 'user_role_onboarding_checklists')
            ->where('constraint_name', 'user_role_onboarding_checklists_role_id_foreign')
            ->exists();

        if ($foreignKeyExists) {
            DB::statement('ALTER TABLE `user_role_onboarding_checklists` DROP FOREIGN KEY `user_role_onboarding_checklists_role_id_foreign`');
        }
    }
};
