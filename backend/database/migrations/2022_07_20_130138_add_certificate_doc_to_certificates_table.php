<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddCertificateDocToCertificatesTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('certificates', function (Blueprint $table) {
            $table->string('certificate_doc',555)->after('certificate_no')->nullable();
            $table->integer('status')->after('certificate_doc')->default(0);
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
            $table->dropColumn('certificate_doc');
            $table->dropColumn('status');
        });
    }
}
