<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('orders', function (Blueprint $table): void {
            if (! Schema::hasColumn('orders', 'dine_in_slot_id')) {
                $table->unsignedBigInteger('dine_in_slot_id')->nullable()->after('persons');
                $table->index('dine_in_slot_id');
            }
        });
    }

    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table): void {
            if (Schema::hasColumn('orders', 'dine_in_slot_id')) {
                $table->dropIndex(['dine_in_slot_id']);
                $table->dropColumn('dine_in_slot_id');
            }
        });
    }
};
