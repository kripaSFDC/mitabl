<?php

namespace App\Console\Commands;

use App\Models\AccountDeletionRequest;
use App\Models\User;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Log;

class PurgeDeletedAccountsCommand extends Command
{
    protected $signature = 'app:purge-deleted-accounts';

    protected $description = 'Hard-delete user accounts that were soft-deleted more than 30 days ago.';

    public function handle(): int
    {
        $cutoff = now()->subDays(30);

        $requests = AccountDeletionRequest::query()
            ->whereNull('data_purged_at')
            ->where('soft_deleted_at', '<=', $cutoff)
            ->get();

        $purged = 0;

        foreach ($requests as $request) {
            /** @var \App\Models\User|null $user */
            $user = User::withTrashed()->find($request->user_id);

            if (! $user) {
                // User was already hard-deleted; just mark the request as processed.
                $request->data_purged_at = now();
                $request->save();
                $purged++;
                continue;
            }

            // Skip if the user was restored by an admin after requesting deletion.
            if (! $user->trashed()) {
                Log::info('app:purge-deleted-accounts: skipping user ' . $user->id . ' — account was restored.');
                continue;
            }

            try {
                $user->forceDelete();
                $request->data_purged_at = now();
                $request->save();
                $purged++;
            } catch (\Throwable $e) {
                Log::warning('app:purge-deleted-accounts: failed to purge user ' . $user->id . ': ' . $e->getMessage());
            }
        }

        $this->info("Purged {$purged} account(s).");

        return self::SUCCESS;
    }
}
