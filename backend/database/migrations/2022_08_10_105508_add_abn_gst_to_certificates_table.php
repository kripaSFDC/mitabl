<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddAbnGstToCertificatesTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('certificates', function (Blueprint $table) {
            $table->integer('abn_gst')->after('certificate_doc');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('certificates', function (Blueprint $table) {
            $table->dropColumn('abn_gst');
        });
    }
}
