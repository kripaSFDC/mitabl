<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class CoreUserRolesSeeder extends Seeder
{
    public function run(): void
    {
        if (! Schema::hasTable('roles')) {
            return;
        }

        $rows = [
            ['id' => 1, 'role' => 'Admin'],
            ['id' => 2, 'role' => 'Restaurant'],
            ['id' => 3, 'role' => 'Foodie'],
        ];

        foreach ($rows as $row) {
            DB::table('roles')->updateOrInsert(
                ['id' => $row['id']],
                [
                    'role' => $row['role'],
                    'updated_at' => now(),
                    'created_at' => now(),
                ]
            );
        }
    }
}
