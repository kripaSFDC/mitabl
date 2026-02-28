<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

class PhaseFiveCutoverReconciliationCommand extends Command
{
    protected $signature = 'phase5:cutover:reconcile {--normalize : Normalize email/phone fields before reporting}';

    protected $description = 'Generate Phase 5 cutover reconciliation report for CRM intake data integrity.';

    public function handle(): int
    {
        if ((bool) $this->option('normalize')) {
            $this->normalizeIntakeData();
        }

        $summary = [
            'timestamp' => now()->toIso8601String(),
            'counts' => [
                'pre_registrations' => DB::table('pre_registrations')->count(),
                'support_tickets' => DB::table('support_tickets')->count(),
            ],
            'duplicates' => [
                'pre_registrations_by_fingerprint' => $this->preRegistrationDuplicateGroups(),
                'support_tickets_by_intake_fingerprint' => $this->supportTicketDuplicateGroups(),
            ],
            'orphan_links' => [
                'support_tickets_user_id' => $this->orphanCount('support_tickets', 'users', 'user_id'),
                'support_tickets_order_id' => $this->orphanCount('support_tickets', 'orders', 'order_id'),
                'support_tickets_mikitchn_id' => $this->orphanCount('support_tickets', 'mikitchns', 'mikitchn_id'),
            ],
        ];

        $this->line(json_encode($summary, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES));

        return 0;
    }

    private function normalizeIntakeData(): void
    {
        DB::table('pre_registrations')
            ->whereNotNull('email')
            ->update([
                'email' => DB::raw('LOWER(TRIM(email))'),
            ]);

        DB::table('support_tickets')
            ->whereNotNull('requester_email')
            ->update([
                'requester_email' => DB::raw('LOWER(TRIM(requester_email))'),
            ]);

        DB::table('pre_registrations')
            ->whereNotNull('phone')
            ->update([
                'phone' => DB::raw("REPLACE(REPLACE(REPLACE(REPLACE(TRIM(phone), ' ', ''), '-', ''), '(', ''), ')', '')"),
            ]);

        DB::table('support_tickets')
            ->whereNotNull('requester_phone')
            ->update([
                'requester_phone' => DB::raw("REPLACE(REPLACE(REPLACE(REPLACE(TRIM(requester_phone), ' ', ''), '-', ''), '(', ''), ')', '')"),
            ]);
    }

    private function preRegistrationDuplicateGroups(): int
    {
        return DB::table('pre_registrations')
            ->select('duplicate_fingerprint')
            ->whereNotNull('duplicate_fingerprint')
            ->groupBy('duplicate_fingerprint')
            ->havingRaw('COUNT(*) > 1')
            ->count();
    }

    private function supportTicketDuplicateGroups(): int
    {
        return DB::table('support_tickets')
            ->select('intake_fingerprint')
            ->whereNotNull('intake_fingerprint')
            ->groupBy('intake_fingerprint')
            ->havingRaw('COUNT(*) > 1')
            ->count();
    }

    private function orphanCount(string $table, string $relatedTable, string $foreignKey): int
    {
        return DB::table($table)
            ->leftJoin($relatedTable, $table . '.' . $foreignKey, '=', $relatedTable . '.id')
            ->whereNotNull($table . '.' . $foreignKey)
            ->whereNull($relatedTable . '.id')
            ->count();
    }
}
