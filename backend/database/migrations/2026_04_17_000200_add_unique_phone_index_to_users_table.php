<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Generated columns and the duplicate-phone cleanup are MySQL-only.
        // SQLite (used in tests) does not support stored generated columns.
        if (DB::connection()->getDriverName() !== 'mysql') {
            return;
        }

        // Clean up duplicate phone numbers before adding the unique constraint.
        // For each duplicate phone, keep the most recently created user and nullify
        // the phone on older accounts so the unique index can be created cleanly.
        $duplicates = DB::table('users')
            ->select('phone', DB::raw('MAX(id) as keep_id'))
            ->whereNotNull('phone')
            ->where('phone', '!=', '')
            ->whereNull('deleted_at')
            ->groupBy('phone')
            ->havingRaw('COUNT(*) > 1')
            ->get();

        foreach ($duplicates as $dup) {
            DB::table('users')
                ->where('phone', $dup->phone)
                ->where('id', '!=', $dup->keep_id)
                ->whereNull('deleted_at')
                ->update(['phone' => null]);
        }

        // Add a generated column that holds the phone value only for non-deleted users.
        // This allows MySQL to enforce uniqueness on active (non-soft-deleted) accounts
        // while permitting new registrations to reuse phones from soft-deleted users.
        Schema::table('users', function (Blueprint $table) {
            $table->string('phone_normalized', 30)
                ->nullable()
                ->storedAs("CASE WHEN deleted_at IS NULL THEN phone ELSE NULL END")
                ->after('phone');

            $table->unique('phone_normalized', 'users_phone_active_unique');
        });
    }

    public function down(): void
    {
        if (DB::connection()->getDriverName() !== 'mysql') {
            return;
        }

        Schema::table('users', function (Blueprint $table) {
            $table->dropUnique('users_phone_active_unique');
            $table->dropColumn('phone_normalized');
        });
    }
};
