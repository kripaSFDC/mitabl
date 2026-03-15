<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('foods', function (Blueprint $table): void {
            if (! Schema::hasColumn('foods', 'dine_in')) {
                $table->integer('dine_in')->default(1)->after('status');
            }

            if (! Schema::hasColumn('foods', 'take_away')) {
                $table->integer('take_away')->default(1)->after('dine_in');
            }
        });
    }

    public function down(): void
    {
        Schema::table('foods', function (Blueprint $table): void {
            if (Schema::hasColumn('foods', 'take_away')) {
                $table->dropColumn('take_away');
            }

            if (Schema::hasColumn('foods', 'dine_in')) {
                $table->dropColumn('dine_in');
            }
        });
    }
};
