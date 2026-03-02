<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('templates')) {
            return;
        }

        Schema::create('templates', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('channel')->default('email');
            $table->string('subject')->nullable();
            $table->json('body');
            $table->unsignedInteger('version')->default(1);
            $table->boolean('active')->default(false);
            $table->foreignId('created_by')->nullable()->constrained('admin_users')->nullOnDelete();
            $table->foreignId('updated_by')->nullable()->constrained('admin_users')->nullOnDelete();
            $table->timestamps();

            $table->unique(['name', 'version']);
            $table->index(['name', 'active'], 'templates_name_active_idx');
        });
    }

    public function down(): void
    {
        if (! Schema::hasTable('templates')) {
            return;
        }

        Schema::drop('templates');
    }
};
