<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        $this->cleanupDuplicateCompletedOrders();
        $this->cleanupDuplicateUserAuthTokens();

        Schema::table('completed_orders', function (Blueprint $table): void {
            if (! $this->indexExists('completed_orders', 'completed_orders_order_id_unique')) {
                $table->unique('order_id', 'completed_orders_order_id_unique');
            }
        });

        Schema::table('user_auth_tokens', function (Blueprint $table): void {
            if (! $this->indexExists('user_auth_tokens', 'user_auth_tokens_user_id_unique')) {
                $table->unique('user_id', 'user_auth_tokens_user_id_unique');
            }
        });
    }

    public function down(): void
    {
        Schema::table('user_auth_tokens', function (Blueprint $table): void {
            if ($this->indexExists('user_auth_tokens', 'user_auth_tokens_user_id_unique')) {
                $table->dropUnique('user_auth_tokens_user_id_unique');
            }
        });

        Schema::table('completed_orders', function (Blueprint $table): void {
            if ($this->indexExists('completed_orders', 'completed_orders_order_id_unique')) {
                $table->dropUnique('completed_orders_order_id_unique');
            }
        });
    }

    private function cleanupDuplicateCompletedOrders(): void
    {
        $duplicateOrderIds = DB::table('completed_orders')
            ->select('order_id')
            ->groupBy('order_id')
            ->havingRaw('COUNT(*) > 1')
            ->pluck('order_id');

        foreach ($duplicateOrderIds as $orderId) {
            $keepId = DB::table('completed_orders')
                ->where('order_id', $orderId)
                ->max('id');

            DB::table('completed_orders')
                ->where('order_id', $orderId)
                ->where('id', '<>', $keepId)
                ->delete();
        }
    }

    private function cleanupDuplicateUserAuthTokens(): void
    {
        $duplicateUserIds = DB::table('user_auth_tokens')
            ->select('user_id')
            ->groupBy('user_id')
            ->havingRaw('COUNT(*) > 1')
            ->pluck('user_id');

        foreach ($duplicateUserIds as $userId) {
            $keepId = DB::table('user_auth_tokens')
                ->where('user_id', $userId)
                ->max('id');

            DB::table('user_auth_tokens')
                ->where('user_id', $userId)
                ->where('id', '<>', $keepId)
                ->delete();
        }
    }

    private function indexExists(string $table, string $index): bool
    {
        if (! $this->supportsInformationSchemaLookups()) {
            return false;
        }

        $result = DB::selectOne(
            'SELECT COUNT(1) AS aggregate FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = ? AND index_name = ?',
            [$table, $index]
        );

        return ((int) ($result->aggregate ?? 0)) > 0;
    }

    private function supportsInformationSchemaLookups(): bool
    {
        $driver = DB::connection()->getDriverName();

        return in_array($driver, ['mysql', 'mariadb'], true);
    }
};
