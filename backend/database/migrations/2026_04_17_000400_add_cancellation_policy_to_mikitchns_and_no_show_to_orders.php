<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('mikitchns', function (Blueprint $table): void {
            if (! Schema::hasColumn('mikitchns', 'cancellation_window_hours')) {
                $table->unsignedSmallInteger('cancellation_window_hours')->nullable()->after('take_away');
            }
            if (! Schema::hasColumn('mikitchns', 'no_show_penalty_pct')) {
                $table->unsignedTinyInteger('no_show_penalty_pct')->nullable()->after('cancellation_window_hours');
            }
        });

        Schema::table('orders', function (Blueprint $table): void {
            if (! Schema::hasColumn('orders', 'no_show')) {
                $table->boolean('no_show')->default(false)->after('status');
            }
            if (! Schema::hasColumn('orders', 'no_show_at')) {
                $table->timestamp('no_show_at')->nullable()->after('no_show');
            }
        });
    }

    public function down(): void
    {
        Schema::table('mikitchns', function (Blueprint $table): void {
            $cols = [];
            foreach (['no_show_penalty_pct', 'cancellation_window_hours'] as $col) {
                if (Schema::hasColumn('mikitchns', $col)) {
                    $cols[] = $col;
                }
            }
            if ($cols !== []) {
                $table->dropColumn($cols);
            }
        });

        Schema::table('orders', function (Blueprint $table): void {
            $cols = [];
            foreach (['no_show_at', 'no_show'] as $col) {
                if (Schema::hasColumn('orders', $col)) {
                    $cols[] = $col;
                }
            }
            if ($cols !== []) {
                $table->dropColumn($cols);
            }
        });
    }
};
