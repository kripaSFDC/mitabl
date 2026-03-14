<?php

namespace App\Console\Commands;

use App\Models\UserRole;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

class RepairUserRoleStateCommand extends Command
{
    protected $signature = 'roles:repair-state {--dry-run : Report counts only without persisting changes}';

    protected $description = 'Backfill missing user role memberships and repair onboarding memberships that have complete checklists.';

    public function handle(): int
    {
        $isDryRun = (bool) $this->option('dry-run');

        $missingMembershipCount = DB::table('users as u')
            ->leftJoin('user_roles as ur', function ($join): void {
                $join->on('ur.user_id', '=', 'u.id')
                    ->on('ur.role_id', '=', 'u.role_id');
            })
            ->whereNotNull('u.role_id')
            ->whereNull('ur.id')
            ->count();

        $onboardingRepairQuery = DB::table('user_roles as ur')
            ->join('user_role_onboarding_checklists as c', function ($join): void {
                $join->on('c.user_id', '=', 'ur.user_id')
                    ->on('c.role_id', '=', 'ur.role_id');
            })
            ->where('ur.role_id', 2)
            ->where('ur.status', UserRole::STATUS_ONBOARDING)
            ->where('c.vendor_account_completed', true)
            ->where('c.kitchen_profile_completed', true)
            ->where('c.certificate_completed', true)
            ->where('c.payout_setup_completed', true);

        $onboardingRepairCount = (clone $onboardingRepairQuery)->count();

        $backfilledMemberships = 0;
        $repairedOnboardingStatuses = 0;

        if (! $isDryRun) {
            DB::table('users')
                ->select(['id as user_id', 'role_id'])
                ->whereNotNull('role_id')
                ->orderBy('id')
                ->chunk(500, function ($users) use (&$backfilledMemberships): void {
                    $rows = [];
                    $timestamp = now();

                    foreach ($users as $user) {
                        $rows[] = [
                            'user_id' => (int) $user->user_id,
                            'role_id' => (int) $user->role_id,
                            'status' => UserRole::STATUS_ACTIVE,
                            'created_at' => $timestamp,
                            'updated_at' => $timestamp,
                        ];
                    }

                    if ($rows === []) {
                        return;
                    }

                    $backfilledMemberships += DB::table('user_roles')->insertOrIgnore($rows);
                });

            $membershipIdsToRepair = (clone $onboardingRepairQuery)
                ->select('ur.id')
                ->pluck('ur.id')
                ->all();

            if ($membershipIdsToRepair !== []) {
                $repairedOnboardingStatuses = DB::table('user_roles')
                    ->whereIn('id', $membershipIdsToRepair)
                    ->update([
                        'status' => UserRole::STATUS_ACTIVE,
                        'updated_at' => now(),
                    ]);
            }
        }

        $this->info('User role state repair summary');
        $this->line('- missing_memberships_detected: ' . $missingMembershipCount);
        $this->line('- onboarding_memberships_ready_for_activation: ' . $onboardingRepairCount);

        if ($isDryRun) {
            $this->line('- backfilled_memberships: 0 (dry-run)');
            $this->line('- repaired_onboarding_statuses: 0 (dry-run)');

            return self::SUCCESS;
        }

        $this->line('- backfilled_memberships: ' . $backfilledMemberships);
        $this->line('- repaired_onboarding_statuses: ' . $repairedOnboardingStatuses);

        return self::SUCCESS;
    }
}
