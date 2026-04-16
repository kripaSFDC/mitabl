<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('account_deletion_requests', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id');
            $table->string('reason', 500)->nullable();
            $table->timestamp('soft_deleted_at');
            $table->timestamp('data_purged_at')->nullable();
            $table->timestamps();

            // FK uses cascadeOnDelete so purging the user record also cleans this row.
            $table->foreign('user_id')->references('id')->on('users')->cascadeOnDelete();
            $table->index('data_purged_at');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('account_deletion_requests');
    }
};
