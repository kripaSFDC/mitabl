<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::dropIfExists('sales_kitchens');
    }

    public function down(): void
    {
        // The legacy Salesforce mapping schema has been retired and is not recreated on rollback.
    }
};
