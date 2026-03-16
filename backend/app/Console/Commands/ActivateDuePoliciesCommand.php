<?php

namespace App\Console\Commands;

use App\Models\Policy;
use App\Models\PolicyChangeLog;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class ActivateDuePoliciesCommand extends Command
{
    protected $signature = 'platform:policies:activate-due';

    protected $description = 'Activate scheduled policy versions whose effective_at has passed.';

    public function handle(): int
    {
        $activated = 0;

        $names = Policy::query()
            ->where('active', false)
            ->whereNotNull('effective_at')
            ->where('effective_at', '<=', now())
            ->distinct()
            ->pluck('name');

        foreach ($names as $name) {
            if (! is_string($name) || $name === '') {
                continue;
            }

            DB::transaction(function () use ($name, &$activated): void {
                Policy::query()
                    ->where('name', $name)
                    ->lockForUpdate()
                    ->get(['id']);

                $target = Policy::query()
                    ->where('name', $name)
                    ->where('active', false)
                    ->whereNotNull('effective_at')
                    ->where('effective_at', '<=', now())
                    ->orderByDesc('effective_at')
                    ->orderByDesc('version')
                    ->first();

                if (! $target) {
                    return;
                }

                $previousActive = Policy::query()
                    ->where('name', $name)
                    ->where('active', true)
                    ->first();

                Policy::query()
                    ->where('name', $name)
                    ->where('active', true)
                    ->update(['active' => false]);

                $target->active = true;
                $target->save();

                PolicyChangeLog::create([
                    'policy_id' => $target->id,
                    'action' => 'activated_effective',
                    'changed_by' => null,
                    'from_version' => $previousActive?->version,
                    'to_version' => $target->version,
                    'change_summary' => 'Auto-activated on effective_at by scheduler.',
                    'before_payload' => $previousActive?->definition,
                    'after_payload' => $target->definition,
                    'correlation_id' => null,
                ]);

                $activated++;
            });
        }

        Log::info('policy.activate_due.completed', ['activated' => $activated]);
        $this->info('Activated due policy versions: ' . $activated);

        return self::SUCCESS;
    }
}
