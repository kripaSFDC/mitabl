<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('mikitchns', function (Blueprint $table) {
            $table->unsignedInteger('advance_order_days')->nullable()->default(null)->after('take_away');
        });
    }

    public function down(): void
    {
        Schema::table('mikitchns', function (Blueprint $table) {
            $table->dropColumn('advance_order_days');
        });
    }
};
