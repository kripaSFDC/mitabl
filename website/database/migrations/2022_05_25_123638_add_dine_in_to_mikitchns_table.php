<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddDineInToMikitchnsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('mikitchns', function (Blueprint $table) {
            $table->integer('dine_in')->default(1)->after('images');
            $table->integer('take_away')->default(1)->after('dine_in');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('mikitchns', function (Blueprint $table) {
            $table->dropColumn('dine_in');
            $table->dropColumn('take_away');
        });
    }
}
