<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('foods', function (Blueprint $table): void {
            if (! Schema::hasColumn('foods', 'available_date')) {
                $table->date('available_date')->nullable()->after('take_away');
            }

            if (! Schema::hasColumn('foods', 'available_days')) {
                $table->json('available_days')->nullable()->after('available_date');
            }

            if (! Schema::hasColumn('foods', 'available_from_time')) {
                $table->time('available_from_time')->nullable()->after('available_days');
            }

            if (! Schema::hasColumn('foods', 'available_to_time')) {
                $table->time('available_to_time')->nullable()->after('available_from_time');
            }
        });
    }

    public function down(): void
    {
        Schema::table('foods', function (Blueprint $table): void {
            $columns = [];

            foreach (['available_to_time', 'available_from_time', 'available_days', 'available_date'] as $column) {
                if (Schema::hasColumn('foods', $column)) {
                    $columns[] = $column;
                }
            }

            if ($columns !== []) {
                $table->dropColumn($columns);
            }
        });
    }
};
