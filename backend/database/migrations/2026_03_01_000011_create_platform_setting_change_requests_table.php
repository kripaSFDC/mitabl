<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('platform_setting_change_requests', function (Blueprint $table) {
            $table->id();
            $table->string('setting_key')->index();
            $table->json('proposed_value')->nullable();
            $table->string('value_type')->default('json');
            $table->text('change_reason')->nullable();
            $table->string('risk_level')->default('high');
            $table->string('status')->default('validated')->index();
            $table->foreignId('requested_by')->nullable()->constrained('admin_users')->nullOnDelete();
            $table->foreignId('approved_by')->nullable()->constrained('admin_users')->nullOnDelete();
            $table->foreignId('activated_by')->nullable()->constrained('admin_users')->nullOnDelete();
            $table->timestamp('validated_at')->nullable();
            $table->timestamp('approved_at')->nullable();
            $table->timestamp('activated_at')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('platform_setting_change_requests');
    }
};
