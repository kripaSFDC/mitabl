<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('internal_notes', function (Blueprint $table) {
            $table->id();
            $table->morphs('noteable');
            $table->foreignId('author_id')->nullable()->constrained('admin_users')->nullOnDelete();
            $table->text('note');
            $table->timestamps();
        });

        Schema::create('tags', function (Blueprint $table) {
            $table->id();
            $table->string('name')->unique();
            $table->string('description')->nullable();
            $table->timestamps();
        });

        Schema::create('taggables', function (Blueprint $table) {
            $table->foreignId('tag_id')->constrained()->cascadeOnDelete();
            $table->morphs('taggable');
            $table->primary(['tag_id', 'taggable_id', 'taggable_type']);
        });

        Schema::create('watch_subscriptions', function (Blueprint $table) {
            $table->id();
            $table->morphs('watchable');
            $table->foreignId('admin_user_id')->constrained('admin_users')->cascadeOnDelete();
            $table->timestamps();
            $table->unique(['watchable_type', 'watchable_id', 'admin_user_id'], 'watch_subscriptions_unique');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('watch_subscriptions');
        Schema::dropIfExists('taggables');
        Schema::dropIfExists('tags');
        Schema::dropIfExists('internal_notes');
    }
};
