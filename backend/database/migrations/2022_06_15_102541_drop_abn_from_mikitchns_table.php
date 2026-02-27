<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class DropAbnFromMikitchnsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('mikitchns', function (Blueprint $table) {
            $table->dropColumn('abn','certificate_no','certificate_doc');
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
            //
        });
    }
}
