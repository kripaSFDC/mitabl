<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateMikitchnsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('mikitchns', function (Blueprint $table) {
            $table->id();
            $table->integer('user_id');
            $table->string('name');
            $table->string('address');
            $table->string('phone');
            $table->integer('no_of_seats')->default(0);
            $table->longText('timings')->nullable();
            $table->longText('images')->nullable();
            $table->longText('description')->nullable();
            $table->string('abn',11)->default(0);
            $table->string('certificate_no')->default(0);
            $table->string('certificate_doc')->nullable();
            $table->string('status')->default(0);
            $table->double('latitude')->default(35.4735);
            $table->double('longitude')->default(149.0124);
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
        Schema::dropIfExists('mikitchns');
    }
}
