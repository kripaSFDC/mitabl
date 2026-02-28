<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('support_ticket_attachments', function (Blueprint $table): void {
            $table->string('sha256', 64)->nullable()->after('uploaded_by_id');
            $table->string('scan_status', 20)->default('pending')->after('sha256');
            $table->timestamp('scanned_at')->nullable()->after('scan_status');
            $table->timestamp('malware_detected_at')->nullable()->after('scanned_at');

            $table->index(['scan_status', 'created_at'], 'support_ticket_attachments_scan_status_idx');
            $table->index(['sha256'], 'support_ticket_attachments_sha256_idx');
        });
    }

    public function down(): void
    {
        Schema::table('support_ticket_attachments', function (Blueprint $table): void {
            $table->dropIndex('support_ticket_attachments_scan_status_idx');
            $table->dropIndex('support_ticket_attachments_sha256_idx');
            $table->dropColumn(['sha256', 'scan_status', 'scanned_at', 'malware_detected_at']);
        });
    }
};
