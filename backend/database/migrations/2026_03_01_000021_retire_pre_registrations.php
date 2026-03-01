<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('crm_communication_logs') && Schema::hasColumn('crm_communication_logs', 'pre_registration_id')) {
            Schema::table('crm_communication_logs', function (Blueprint $table): void {
                $table->dropForeign(['pre_registration_id']);
                $table->dropIndex('crm_comm_logs_prereg_created_idx');
                $table->dropColumn('pre_registration_id');
            });
        }

        Schema::dropIfExists('pre_registrations');
    }

    public function down(): void
    {
        if (! Schema::hasTable('pre_registrations')) {
            Schema::create('pre_registrations', function (Blueprint $table): void {
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
                $table->string('communication_preference', 20)->default('email');
                $table->timestamp('consent_captured_at')->nullable();
                $table->foreignId('followed_up_by')->nullable()->constrained('admin_users')->nullOnDelete();
                $table->foreignId('assigned_to')->nullable()->constrained('admin_users')->nullOnDelete();
                $table->timestamp('followed_up_at')->nullable();
                $table->foreignId('converted_user_id')->nullable()->constrained('users')->nullOnDelete();
                $table->string('duplicate_fingerprint', 64)->nullable();
                $table->unsignedSmallInteger('spam_score')->default(0);
                $table->timestamp('spam_detected_at')->nullable();
                $table->timestamp('last_contacted_at')->nullable();
                $table->json('metadata')->nullable();
                $table->timestamps();

                $table->index(['status', 'source'], 'pre_registrations_status_source_idx');
                $table->index(['email', 'phone'], 'pre_registrations_email_phone_idx');
                $table->index(['communication_preference'], 'pre_registrations_comm_pref_idx');
                $table->index(['assigned_to', 'status'], 'pre_registrations_assigned_status_idx');
                $table->index(['duplicate_fingerprint', 'created_at'], 'pre_registrations_duplicate_fingerprint_created_idx');
            });
        }

        if (Schema::hasTable('crm_communication_logs') && ! Schema::hasColumn('crm_communication_logs', 'pre_registration_id')) {
            Schema::table('crm_communication_logs', function (Blueprint $table): void {
                $table->foreignId('pre_registration_id')->nullable()->after('support_ticket_id')->constrained('pre_registrations')->nullOnDelete();
                $table->index(['pre_registration_id', 'created_at'], 'crm_comm_logs_prereg_created_idx');
            });
        }
    }
};
