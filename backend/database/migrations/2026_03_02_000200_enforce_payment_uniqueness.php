<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        $this->cleanupDuplicatePayments();

        Schema::table('payments', function (Blueprint $table): void {
            if (! $this->indexExists('payments', 'payments_order_id_unique')) {
                $table->unique('order_id', 'payments_order_id_unique');
            }
            if (! $this->indexExists('payments', 'payments_payment_id_unique')) {
                $table->unique('payment_id', 'payments_payment_id_unique');
            }
        });
    }

    public function down(): void
    {
        Schema::table('payments', function (Blueprint $table): void {
            if ($this->indexExists('payments', 'payments_order_id_unique')) {
                $table->dropUnique('payments_order_id_unique');
            }
            if ($this->indexExists('payments', 'payments_payment_id_unique')) {
                $table->dropUnique('payments_payment_id_unique');
            }
        });
    }

    private function cleanupDuplicatePayments(): void
    {
        $duplicateOrderIds = DB::table('payments')
            ->select('order_id')
            ->groupBy('order_id')
            ->havingRaw('COUNT(*) > 1')
            ->pluck('order_id');

        foreach ($duplicateOrderIds as $orderId) {
            $keepId = DB::table('payments')
                ->where('order_id', $orderId)
                ->max('id');

            DB::table('payments')
                ->where('order_id', $orderId)
                ->where('id', '<>', $keepId)
                ->delete();
        }

        $duplicatePaymentIds = DB::table('payments')
            ->select('payment_id')
            ->whereNotNull('payment_id')
            ->groupBy('payment_id')
            ->havingRaw('COUNT(*) > 1')
            ->pluck('payment_id');

        foreach ($duplicatePaymentIds as $paymentId) {
            $keepId = DB::table('payments')
                ->where('payment_id', $paymentId)
                ->max('id');

            DB::table('payments')
                ->where('payment_id', $paymentId)
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
