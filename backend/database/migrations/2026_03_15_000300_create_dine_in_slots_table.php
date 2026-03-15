<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('dine_in_slots', function (Blueprint $table): void {
            $table->id();
            $table->unsignedBigInteger('mikitchn_id');
            $table->unsignedTinyInteger('day_of_week');
            $table->time('start_time');
            $table->time('end_time');
            $table->unsignedInteger('seat_capacity')->nullable();
            $table->integer('status')->default(1);
            $table->timestamps();

            $table->index(['mikitchn_id', 'day_of_week', 'status'], 'dine_in_slots_kitchen_day_status_idx');
            $table->unique(['mikitchn_id', 'day_of_week', 'start_time', 'end_time'], 'dine_in_slots_unique_window');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('dine_in_slots');
    }
};
