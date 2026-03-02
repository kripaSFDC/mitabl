<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('verify_otps', function (Blueprint $table): void {
            if (! Schema::hasColumn('verify_otps', 'expires_at')) {
                $table->dateTime('expires_at')->nullable()->after('otp');
            }
            if (! Schema::hasColumn('verify_otps', 'attempts')) {
                $table->unsignedTinyInteger('attempts')->default(0)->after('expires_at');
            }
            if (! Schema::hasColumn('verify_otps', 'locked_until')) {
                $table->dateTime('locked_until')->nullable()->after('attempts');
            }
        });
    }

    public function down(): void
    {
        Schema::table('verify_otps', function (Blueprint $table): void {
            if (Schema::hasColumn('verify_otps', 'locked_until')) {
                $table->dropColumn('locked_until');
            }
            if (Schema::hasColumn('verify_otps', 'attempts')) {
                $table->dropColumn('attempts');
            }
            if (Schema::hasColumn('verify_otps', 'expires_at')) {
                $table->dropColumn('expires_at');
            }
        });
    }
};
