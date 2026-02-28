<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::dropIfExists('sales_kitchens');
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (! Schema::hasTable('sales_kitchens')) {
            Schema::create('sales_kitchens', function (Blueprint $table): void {
                $table->id();
                $table->integer('mikitchn_id');
                $table->string('sales_mikitchn_id', 255);
                $table->timestamps();
            });
        }
    }
};
