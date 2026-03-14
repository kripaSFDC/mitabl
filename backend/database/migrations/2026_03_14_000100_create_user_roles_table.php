<?php

use App\Models\UserRole;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('user_roles', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id');
            $table->unsignedBigInteger('role_id');
            $table->enum('status', [
                UserRole::STATUS_ACTIVE,
                UserRole::STATUS_ONBOARDING,
                UserRole::STATUS_DISABLED,
            ])->default(UserRole::STATUS_ACTIVE);
            $table->timestamps();

            $table->unique(['user_id', 'role_id']);
            $table->index(['user_id', 'status']);
            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
            $table->foreign('role_id')->references('id')->on('roles')->onDelete('cascade');
        });

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
                        ['status', 'updated_at']
                    );
                }
            });
    }

    public function down(): void
    {
        Schema::dropIfExists('user_roles');
    }
};
