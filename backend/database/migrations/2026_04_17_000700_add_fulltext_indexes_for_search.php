<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('foods', function (Blueprint $table) {
            $table->fullText(['food_name', 'description'], 'ft_foods_search');
        });

        Schema::table('mikitchns', function (Blueprint $table) {
            $table->fullText(['name', 'description'], 'ft_mikitchns_search');
        });
    }

    public function down(): void
    {
        Schema::table('foods', function (Blueprint $table) {
            $table->dropFullText('ft_foods_search');
        });

        Schema::table('mikitchns', function (Blueprint $table) {
            $table->dropFullText('ft_mikitchns_search');
        });
    }
};
