<?php

use Illuminate\Database\Migrations\Migration;

return new class extends Migration
{
    /**
     * Pre-registration has been reinstated for Module 7 (Lead Management).
     *
     * This migration is intentionally a no-op to preserve migration ordering in
     * environments that already include the historical retirement migration.
     */
    public function up(): void
    {
        // no-op
    }

    public function down(): void
    {
        // no-op
    }
};
