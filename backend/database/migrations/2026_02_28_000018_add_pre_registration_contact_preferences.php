<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('pre_registrations', function (Blueprint $table): void {
            $table->string('communication_preference', 20)->default('email')->after('consent_to_contact');
            $table->timestamp('consent_captured_at')->nullable()->after('communication_preference');
            $table->index(['communication_preference'], 'pre_registrations_comm_pref_idx');
        });
    }

    public function down(): void
    {
        Schema::table('pre_registrations', function (Blueprint $table): void {
            $table->dropIndex('pre_registrations_comm_pref_idx');
            $table->dropColumn(['communication_preference', 'consent_captured_at']);
        });
    }
};
