<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class RemoveNameFromStripeBankAccounts extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('stripe_bank_accounts', function (Blueprint $table) {
            $table->dropColumn('name');
            $table->dropColumn('bank_number');
            $table->dropColumn('bsb');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('stripe_bank_accounts', function (Blueprint $table) {
            $table->string('name');
            $table->string('bank_number',255);
            $table->string('bsb');
        });
    }
}
