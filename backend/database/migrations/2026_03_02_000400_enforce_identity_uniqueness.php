<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        $this->cleanupDuplicateOtps();
        $this->cleanupDuplicateStripeAccounts();

        Schema::table('verify_otps', function (Blueprint $table): void {
            if (! $this->indexExists('verify_otps', 'verify_otps_user_id_unique')) {
                $table->unique('user_id', 'verify_otps_user_id_unique');
            }
        });

        Schema::table('stripe_accounts', function (Blueprint $table): void {
            if (! $this->indexExists('stripe_accounts', 'stripe_accounts_user_account_type_unique')) {
                $table->unique(['user_id', 'account_type'], 'stripe_accounts_user_account_type_unique');
            }
            if (! $this->indexExists('stripe_accounts', 'stripe_accounts_account_id_unique')) {
                $table->unique('account_id', 'stripe_accounts_account_id_unique');
            }
        });
    }

    public function down(): void
    {
        Schema::table('stripe_accounts', function (Blueprint $table): void {
            if ($this->indexExists('stripe_accounts', 'stripe_accounts_account_id_unique')) {
                $table->dropUnique('stripe_accounts_account_id_unique');
            }
            if ($this->indexExists('stripe_accounts', 'stripe_accounts_user_account_type_unique')) {
                $table->dropUnique('stripe_accounts_user_account_type_unique');
            }
        });

        Schema::table('verify_otps', function (Blueprint $table): void {
            if ($this->indexExists('verify_otps', 'verify_otps_user_id_unique')) {
                $table->dropUnique('verify_otps_user_id_unique');
            }
        });
    }

    private function cleanupDuplicateOtps(): void
    {
        $duplicateUserIds = DB::table('verify_otps')
            ->select('user_id')
            ->groupBy('user_id')
            ->havingRaw('COUNT(*) > 1')
            ->pluck('user_id');

        foreach ($duplicateUserIds as $userId) {
            $keepId = DB::table('verify_otps')
                ->where('user_id', $userId)
                ->max('id');

            DB::table('verify_otps')
                ->where('user_id', $userId)
                ->where('id', '<>', $keepId)
                ->delete();
        }
    }

    private function cleanupDuplicateStripeAccounts(): void
    {
        $duplicatePairs = DB::table('stripe_accounts')
            ->select('user_id', 'account_type')
            ->groupBy('user_id', 'account_type')
            ->havingRaw('COUNT(*) > 1')
            ->get();

        foreach ($duplicatePairs as $pair) {
            $keepId = DB::table('stripe_accounts')
                ->where('user_id', $pair->user_id)
                ->where('account_type', $pair->account_type)
                ->max('id');

            DB::table('stripe_accounts')
                ->where('user_id', $pair->user_id)
                ->where('account_type', $pair->account_type)
                ->where('id', '<>', $keepId)
                ->delete();
        }

        $duplicateExternalIds = DB::table('stripe_accounts')
            ->select('account_id')
            ->whereNotNull('account_id')
            ->where('account_id', '<>', '')
            ->groupBy('account_id')
            ->havingRaw('COUNT(*) > 1')
            ->pluck('account_id');

        foreach ($duplicateExternalIds as $accountId) {
            $keepId = DB::table('stripe_accounts')
                ->where('account_id', $accountId)
                ->max('id');

            DB::table('stripe_accounts')
                ->where('account_id', $accountId)
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
