<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('user_role_onboarding_checklists')) {
            return;
        }

        Schema::create('user_role_onboarding_checklists', function (Blueprint $table): void {
            $table->id();
            $table->unsignedBigInteger('user_id');
            // Legacy roles table uses increments('id'), so keep this aligned for the FK.
            $table->unsignedInteger('role_id');
            $table->boolean('vendor_account_completed')->default(false);
            $table->boolean('kitchen_profile_completed')->default(false);
            $table->boolean('certificate_completed')->default(false);
            $table->boolean('payout_setup_completed')->default(false);
            $table->timestamps();

            $table->unique(['user_id', 'role_id']);
            $table->index(['role_id']);
            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
            $table->foreign('role_id')->references('id')->on('roles')->onDelete('cascade');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('user_role_onboarding_checklists');
    }
};
