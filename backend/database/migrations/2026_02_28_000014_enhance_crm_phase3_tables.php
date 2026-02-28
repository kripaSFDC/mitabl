<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('support_tickets', function (Blueprint $table) {
            $table->timestamp('closed_at')->nullable()->after('resolved_at');
            $table->foreignId('merged_into_ticket_id')->nullable()->after('closed_at')->constrained('support_tickets')->nullOnDelete();
            $table->foreignId('split_from_ticket_id')->nullable()->after('merged_into_ticket_id')->constrained('support_tickets')->nullOnDelete();
            $table->string('requester_token', 80)->nullable()->after('split_from_ticket_id');
            $table->string('intake_fingerprint', 64)->nullable()->after('requester_token');
            $table->unsignedSmallInteger('spam_score')->default(0)->after('intake_fingerprint');
            $table->timestamp('spam_detected_at')->nullable()->after('spam_score');
            $table->timestamp('first_response_breached_at')->nullable()->after('first_responded_at');
            $table->timestamp('resolution_breached_at')->nullable()->after('resolved_at');
            $table->unsignedInteger('reopened_count')->default(0)->after('resolution_breached_at');
            $table->timestamp('last_message_at')->nullable()->after('reopened_count');

            $table->index(['status', 'first_response_due_at'], 'support_tickets_status_first_response_due_idx');
            $table->index(['status', 'resolution_due_at'], 'support_tickets_status_resolution_due_idx');
            $table->index(['merged_into_ticket_id'], 'support_tickets_merged_into_idx');
            $table->index(['split_from_ticket_id'], 'support_tickets_split_from_idx');
            $table->index(['requester_token'], 'support_tickets_requester_token_idx');
            $table->index(['intake_fingerprint', 'created_at'], 'support_tickets_intake_fingerprint_created_idx');
        });

        Schema::table('pre_registrations', function (Blueprint $table) {
            $table->foreignId('assigned_to')->nullable()->after('followed_up_by')->constrained('admin_users')->nullOnDelete();
            $table->string('duplicate_fingerprint', 64)->nullable()->after('assigned_to');
            $table->unsignedSmallInteger('spam_score')->default(0)->after('duplicate_fingerprint');
            $table->timestamp('spam_detected_at')->nullable()->after('spam_score');
            $table->timestamp('last_contacted_at')->nullable()->after('followed_up_at');

            $table->index(['assigned_to', 'status'], 'pre_registrations_assigned_status_idx');
            $table->index(['duplicate_fingerprint', 'created_at'], 'pre_registrations_duplicate_fingerprint_created_idx');
        });

        Schema::create('crm_communication_logs', function (Blueprint $table) {
            $table->id();
            $table->string('channel');
            $table->string('template');
            $table->string('recipient');
            $table->string('subject')->nullable();
            $table->string('status')->default('queued');
            $table->json('metadata')->nullable();
            $table->foreignId('support_ticket_id')->nullable()->constrained('support_tickets')->nullOnDelete();
            $table->foreignId('pre_registration_id')->nullable()->constrained('pre_registrations')->nullOnDelete();
            $table->timestamp('queued_at')->nullable();
            $table->timestamp('sent_at')->nullable();
            $table->timestamps();

            $table->index(['status', 'channel'], 'crm_comm_logs_status_channel_idx');
            $table->index(['support_ticket_id', 'created_at'], 'crm_comm_logs_ticket_created_idx');
            $table->index(['pre_registration_id', 'created_at'], 'crm_comm_logs_prereg_created_idx');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('crm_communication_logs');

        Schema::table('pre_registrations', function (Blueprint $table) {
            $table->dropIndex('pre_registrations_assigned_status_idx');
            $table->dropIndex('pre_registrations_duplicate_fingerprint_created_idx');
            $table->dropConstrainedForeignId('assigned_to');
            $table->dropColumn([
                'duplicate_fingerprint',
                'spam_score',
                'spam_detected_at',
                'last_contacted_at',
            ]);
        });

        Schema::table('support_tickets', function (Blueprint $table) {
            $table->dropIndex('support_tickets_status_first_response_due_idx');
            $table->dropIndex('support_tickets_status_resolution_due_idx');
            $table->dropIndex('support_tickets_merged_into_idx');
            $table->dropIndex('support_tickets_split_from_idx');
            $table->dropIndex('support_tickets_requester_token_idx');
            $table->dropIndex('support_tickets_intake_fingerprint_created_idx');
            $table->dropConstrainedForeignId('merged_into_ticket_id');
            $table->dropConstrainedForeignId('split_from_ticket_id');
            $table->dropColumn([
                'closed_at',
                'requester_token',
                'intake_fingerprint',
                'spam_score',
                'spam_detected_at',
                'first_response_breached_at',
                'resolution_breached_at',
                'reopened_count',
                'last_message_at',
            ]);
        });
    }
};
