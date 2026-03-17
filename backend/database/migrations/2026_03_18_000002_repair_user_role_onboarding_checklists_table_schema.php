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

        $column = DB::selectOne(
            'SELECT COLUMN_TYPE AS column_type FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = ? AND column_name = ? LIMIT 1',
            ['user_role_onboarding_checklists', 'role_id']
        );
        $columnType = strtolower((string) data_get($column, 'column_type', data_get($column, 'COLUMN_TYPE', '')));

        if ($columnType !== 'int(10) unsigned') {
            DB::statement('ALTER TABLE `user_role_onboarding_checklists` MODIFY `role_id` INT UNSIGNED NOT NULL');
        }

        $foreignKeyExists = DB::selectOne(
            'SELECT CONSTRAINT_NAME AS constraint_name FROM information_schema.table_constraints WHERE table_schema = DATABASE() AND table_name = ? AND constraint_name = ? LIMIT 1',
            ['user_role_onboarding_checklists', 'user_role_onboarding_checklists_role_id_foreign']
        ) !== null;

        if (! $foreignKeyExists) {
            DB::statement('ALTER TABLE `user_role_onboarding_checklists` ADD CONSTRAINT `user_role_onboarding_checklists_role_id_foreign` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`) ON DELETE CASCADE');
        }
    }

    public function down(): void
    {
        if (DB::getDriverName() !== 'mysql' || ! Schema::hasTable('user_role_onboarding_checklists')) {
            return;
        }

        $foreignKeyExists = DB::selectOne(
            'SELECT CONSTRAINT_NAME AS constraint_name FROM information_schema.table_constraints WHERE table_schema = DATABASE() AND table_name = ? AND constraint_name = ? LIMIT 1',
            ['user_role_onboarding_checklists', 'user_role_onboarding_checklists_role_id_foreign']
        ) !== null;

        if ($foreignKeyExists) {
            DB::statement('ALTER TABLE `user_role_onboarding_checklists` DROP FOREIGN KEY `user_role_onboarding_checklists_role_id_foreign`');
        }
    }
};
