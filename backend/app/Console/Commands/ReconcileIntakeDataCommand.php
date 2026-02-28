<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;

class ReconcileIntakeDataCommand extends Command
{
    protected $signature = 'crm:reconcile-intake {--write : Persist normalized values and FK repairs} {--report= : Absolute or relative JSON report path}';

    protected $description = 'One-time reconciliation for pre-registrations and support tickets.';

    public function handle(): int
    {
        $write = (bool) $this->option('write');
        $startedAt = now();

        $beforeCounts = $this->countsSnapshot();
        $preDuplicates = $this->preRegistrationDuplicateSummary();
        $ticketDuplicates = $this->supportTicketDuplicateSummary();
        $normalizationPlan = $this->collectNormalizationPlan();
        $fkPlan = $this->collectForeignKeyRepairPlan();

        $mutations = [
            'normalized_pre_registrations' => 0,
            'normalized_support_tickets' => 0,
            'repaired_ticket_user_links' => 0,
            'repaired_ticket_order_links' => 0,
            'repaired_ticket_mikitchn_links' => 0,
        ];

        if ($write) {
            $mutations = DB::transaction(function () use ($normalizationPlan, $fkPlan): array {
                return [
                    'normalized_pre_registrations' => $this->applyPreRegistrationNormalization($normalizationPlan['pre_registrations']),
                    'normalized_support_tickets' => $this->applySupportTicketNormalization($normalizationPlan['support_tickets']),
                    'repaired_ticket_user_links' => $this->applyNulling('support_tickets', 'user_id', $fkPlan['invalid_user_ticket_ids']),
                    'repaired_ticket_order_links' => $this->applyNulling('support_tickets', 'order_id', $fkPlan['invalid_order_ticket_ids']),
                    'repaired_ticket_mikitchn_links' => $this->applyNulling('support_tickets', 'mikitchn_id', $fkPlan['invalid_mikitchn_ticket_ids']),
                ];
            });
        }

        $afterCounts = $this->countsSnapshot();

        $report = [
            'started_at' => $startedAt->toISOString(),
            'completed_at' => now()->toISOString(),
            'write_mode' => $write,
            'counts' => [
                'before' => $beforeCounts,
                'after' => $afterCounts,
            ],
            'duplicates' => [
                'pre_registrations' => $preDuplicates,
                'support_tickets' => $ticketDuplicates,
            ],
            'normalization' => [
                'pre_registration_candidates' => count($normalizationPlan['pre_registrations']),
                'support_ticket_candidates' => count($normalizationPlan['support_tickets']),
            ],
            'fk_consistency' => $fkPlan,
            'mutations' => $mutations,
        ];

        $reportPath = $this->persistReport($report);

        $this->info('CRM intake reconciliation complete.');
        $this->line('Mode: ' . ($write ? 'write' : 'dry-run'));
        $this->line('Report: ' . $reportPath);
        $this->table(
            ['Metric', 'Value'],
            [
                ['Pre-registration duplicates', (string) ($preDuplicates['duplicate_groups'] ?? 0)],
                ['Support ticket duplicates', (string) ($ticketDuplicates['duplicate_groups'] ?? 0)],
                ['Pre-registration normalization candidates', (string) count($normalizationPlan['pre_registrations'])],
                ['Support ticket normalization candidates', (string) count($normalizationPlan['support_tickets'])],
                ['Invalid ticket user links', (string) count($fkPlan['invalid_user_ticket_ids'])],
                ['Invalid ticket order links', (string) count($fkPlan['invalid_order_ticket_ids'])],
                ['Invalid ticket mikitchn links', (string) count($fkPlan['invalid_mikitchn_ticket_ids'])],
            ]
        );

        return self::SUCCESS;
    }

    private function countsSnapshot(): array
    {
        return [
            'pre_registrations_total' => DB::table('pre_registrations')->count(),
            'support_tickets_total' => DB::table('support_tickets')->count(),
            'pre_registrations_with_email' => DB::table('pre_registrations')->whereNotNull('email')->count(),
            'pre_registrations_with_phone' => DB::table('pre_registrations')->whereNotNull('phone')->count(),
            'support_tickets_with_email' => DB::table('support_tickets')->whereNotNull('requester_email')->count(),
            'support_tickets_with_phone' => DB::table('support_tickets')->whereNotNull('requester_phone')->count(),
        ];
    }

    private function preRegistrationDuplicateSummary(): array
    {
        $groups = DB::table('pre_registrations')
            ->select('duplicate_fingerprint', DB::raw('COUNT(*) as total'))
            ->whereNotNull('duplicate_fingerprint')
            ->groupBy('duplicate_fingerprint')
            ->havingRaw('COUNT(*) > 1')
            ->orderByDesc('total')
            ->limit(25)
            ->get();

        return [
            'duplicate_groups' => $groups->count(),
            'records_in_duplicate_groups' => (int) $groups->sum('total'),
            'top_groups' => $groups->map(fn ($row): array => [
                'duplicate_fingerprint' => $row->duplicate_fingerprint,
                'total' => (int) $row->total,
            ])->all(),
        ];
    }

    private function supportTicketDuplicateSummary(): array
    {
        $groups = DB::table('support_tickets')
            ->select('intake_fingerprint', DB::raw('COUNT(*) as total'))
            ->whereNotNull('intake_fingerprint')
            ->groupBy('intake_fingerprint')
            ->havingRaw('COUNT(*) > 1')
            ->orderByDesc('total')
            ->limit(25)
            ->get();

        return [
            'duplicate_groups' => $groups->count(),
            'records_in_duplicate_groups' => (int) $groups->sum('total'),
            'top_groups' => $groups->map(fn ($row): array => [
                'intake_fingerprint' => $row->intake_fingerprint,
                'total' => (int) $row->total,
            ])->all(),
        ];
    }

    private function collectNormalizationPlan(): array
    {
        $preRegistrations = DB::table('pre_registrations')
            ->select('id', 'email', 'phone')
            ->get()
            ->map(function ($row): ?array {
                $email = $this->normalizeEmail($row->email);
                $phone = $this->normalizePhone($row->phone);
                $currentEmail = $row->email === null ? null : trim((string) $row->email);
                $currentPhone = $row->phone === null ? null : trim((string) $row->phone);

                if ($email === $currentEmail && $phone === $currentPhone) {
                    return null;
                }

                return [
                    'id' => (int) $row->id,
                    'email' => $email,
                    'phone' => $phone,
                ];
            })
            ->filter()
            ->values()
            ->all();

        $supportTickets = DB::table('support_tickets')
            ->select('id', 'requester_email', 'requester_phone')
            ->get()
            ->map(function ($row): ?array {
                $email = $this->normalizeEmail($row->requester_email);
                $phone = $this->normalizePhone($row->requester_phone);
                $currentEmail = $row->requester_email === null ? null : trim((string) $row->requester_email);
                $currentPhone = $row->requester_phone === null ? null : trim((string) $row->requester_phone);

                if ($email === $currentEmail && $phone === $currentPhone) {
                    return null;
                }

                return [
                    'id' => (int) $row->id,
                    'requester_email' => $email,
                    'requester_phone' => $phone,
                ];
            })
            ->filter()
            ->values()
            ->all();

        return [
            'pre_registrations' => $preRegistrations,
            'support_tickets' => $supportTickets,
        ];
    }

    private function collectForeignKeyRepairPlan(): array
    {
        $invalidUserTicketIds = DB::table('support_tickets as st')
            ->leftJoin('users as u', 'u.id', '=', 'st.user_id')
            ->whereNotNull('st.user_id')
            ->whereNull('u.id')
            ->pluck('st.id')
            ->map(fn ($id): int => (int) $id)
            ->all();

        $invalidOrderTicketIds = DB::table('support_tickets as st')
            ->leftJoin('orders as o', 'o.id', '=', 'st.order_id')
            ->whereNotNull('st.order_id')
            ->whereNull('o.id')
            ->pluck('st.id')
            ->map(fn ($id): int => (int) $id)
            ->all();

        $invalidMikitchnTicketIds = DB::table('support_tickets as st')
            ->leftJoin('mikitchns as mk', 'mk.id', '=', 'st.mikitchn_id')
            ->whereNotNull('st.mikitchn_id')
            ->whereNull('mk.id')
            ->pluck('st.id')
            ->map(fn ($id): int => (int) $id)
            ->all();

        return [
            'invalid_user_ticket_ids' => $invalidUserTicketIds,
            'invalid_order_ticket_ids' => $invalidOrderTicketIds,
            'invalid_mikitchn_ticket_ids' => $invalidMikitchnTicketIds,
        ];
    }

    private function applyPreRegistrationNormalization(array $rows): int
    {
        $updated = 0;
        foreach ($rows as $row) {
            $updated += DB::table('pre_registrations')
                ->where('id', $row['id'])
                ->update([
                    'email' => $row['email'],
                    'phone' => $row['phone'],
                    'updated_at' => now(),
                ]);
        }

        return $updated;
    }

    private function applySupportTicketNormalization(array $rows): int
    {
        $updated = 0;
        foreach ($rows as $row) {
            $updated += DB::table('support_tickets')
                ->where('id', $row['id'])
                ->update([
                    'requester_email' => $row['requester_email'],
                    'requester_phone' => $row['requester_phone'],
                    'updated_at' => now(),
                ]);
        }

        return $updated;
    }

    private function applyNulling(string $table, string $column, array $ids): int
    {
        if ($ids === []) {
            return 0;
        }

        return DB::table($table)->whereIn('id', $ids)->update([
            $column => null,
            'updated_at' => now(),
        ]);
    }

    private function normalizeEmail(mixed $value): ?string
    {
        if ($value === null) {
            return null;
        }

        $email = strtolower(trim((string) $value));
        return $email === '' ? null : $email;
    }

    private function normalizePhone(mixed $value): ?string
    {
        if ($value === null) {
            return null;
        }

        $raw = trim((string) $value);
        if ($raw === '') {
            return null;
        }

        $hasPlus = str_starts_with($raw, '+');
        $digits = preg_replace('/\D+/', '', $raw) ?? '';
        if ($digits === '') {
            return null;
        }

        return $hasPlus ? '+' . $digits : $digits;
    }

    private function persistReport(array $report): string
    {
        $reportOption = (string) $this->option('report');
        if ($reportOption !== '') {
            $path = str_starts_with($reportOption, '/')
                ? $reportOption
                : base_path($reportOption);
        } else {
            $path = storage_path('app/reports/intake_reconciliation_' . now()->format('Ymd_His') . '.json');
        }

        File::ensureDirectoryExists(dirname($path));
        File::put($path, json_encode($report, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES));

        return $path;
    }
}
