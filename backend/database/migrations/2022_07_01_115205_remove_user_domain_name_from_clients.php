<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class RemoveUserDomainNameFromClients extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('cards', function (Blueprint $table) {
            $table->dropColumn('name');
            $table->dropColumn('card_number');
            $table->dropColumn('exp_date');
            $table->dropColumn('cvc');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('cards', function (Blueprint $table) {
            $table->string('name');
            $table->string('card_number',255);
            $table->string('exp_date');
            $table->string('cvc');
        });
    }
}
