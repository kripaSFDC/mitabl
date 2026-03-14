<?php

use App\Models\UserRole;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::table('users')
            ->select(['id as user_id', 'role_id'])
            ->whereNotNull('role_id')
            ->orderBy('id')
            ->chunk(500, function ($users): void {
                $rows = [];
                $timestamp = now();

                foreach ($users as $user) {
                    $rows[] = [
                        'user_id' => (int) $user->user_id,
                        'role_id' => (int) $user->role_id,
                        'status' => UserRole::STATUS_ACTIVE,
                        'created_at' => $timestamp,
                        'updated_at' => $timestamp,
                    ];
                }

                if ($rows !== []) {
                    DB::table('user_roles')->upsert(
                        $rows,
                        ['user_id', 'role_id'],
                        ['updated_at']
                    );
                }
            });
    }

    public function down(): void
    {
        // Intentional no-op: preserve role memberships once created.
    }
};

