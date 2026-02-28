<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('pre_registrations', function (Blueprint $table) {
            $table->id();
            $table->string('first_name');
            $table->string('last_name');
            $table->string('email')->nullable();
            $table->string('phone')->nullable();
            $table->string('city')->nullable();
            $table->string('interested_as');
            $table->string('source');
            $table->string('status')->default('new');
            $table->text('notes')->nullable();
            $table->boolean('consent_to_contact')->default(false);
            $table->foreignId('followed_up_by')->nullable()->constrained('admin_users')->nullOnDelete();
            $table->timestamp('followed_up_at')->nullable();
            $table->foreignId('converted_user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();

            $table->index(['status', 'source'], 'pre_registrations_status_source_idx');
            $table->index(['email', 'phone'], 'pre_registrations_email_phone_idx');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('pre_registrations');
    }
};
