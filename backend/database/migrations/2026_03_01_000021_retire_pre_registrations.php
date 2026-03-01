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
                $table->string('last_name')->nullable();
                $table->string('email')->nullable();
                $table->string('phone', 32)->nullable();
                $table->string('city')->nullable();
                $table->string('interested_as', 32);
                $table->string('source', 32)->default('website');
                $table->string('status', 32)->default('new');
                $table->text('notes')->nullable();
                $table->foreignId('followed_up_by')->nullable()->constrained('admin_users')->nullOnDelete();
                $table->timestamp('followed_up_at')->nullable();
                $table->json('metadata')->nullable();
                $table->timestamps();

                $table->index(['status', 'source'], 'pre_registrations_status_source_idx');
                $table->index(['email', 'phone'], 'pre_registrations_email_phone_idx');
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
