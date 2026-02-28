<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('policy_change_log', function (Blueprint $table) {
            $table->id();
            $table->foreignId('policy_id')->constrained('policies')->cascadeOnDelete();
            $table->string('action');
            $table->foreignId('changed_by')->nullable()->constrained('admin_users')->nullOnDelete();
            $table->unsignedInteger('from_version')->nullable();
            $table->unsignedInteger('to_version')->nullable();
            $table->text('change_summary')->nullable();
            $table->json('before_payload')->nullable();
            $table->json('after_payload')->nullable();
            $table->uuid('correlation_id')->nullable();
            $table->timestamps();

            $table->index(['policy_id', 'created_at'], 'policy_change_log_policy_created_idx');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('policy_change_log');
    }
};
