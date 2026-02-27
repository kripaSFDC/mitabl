<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateOrdersTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('orders', function (Blueprint $table) {
            $table->id();
            $table->integer('mikitchn_id');
            $table->integer('user_id');
            $table->integer('dine_in')->default(0);
            $table->integer('take_away')->default(0);
            $table->integer('persons')->default(0);
            $table->date('delivery_date');
            $table->time('delivery_time_from');
            $table->time('delivery_time_to');
            $table->text('message')->nullable();
            $table->float('item_total_price');
            $table->integer('promo_code')->nullable();
            $table->float('taxes')->nullable();
            $table->float('total_price');
            $table->boolean('status')->default(2);
            $table->boolean('paid')->default(0);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('orders');
    }
}
