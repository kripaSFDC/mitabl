<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Tests\TestCase;

class PhaseFiveReconciliationCommandTest extends TestCase
{
    use RefreshDatabase;

    public function test_reconciliation_command_dry_run_writes_report_with_ticket_duplicate_summary(): void
    {
        DB::table('support_tickets')->insert([
            [
                'ticket_number' => 'TKT-000001',
                'requester_email' => 'ticket@example.com',
                'requester_phone' => '0400000000',
                'subject' => 'Help needed',
                'description' => 'Issue details',
                'source' => 'website',
                'category' => 'general',
                'priority' => 'normal',
                'status' => 'open',
                'intake_fingerprint' => 'tfp-1',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'ticket_number' => 'TKT-000002',
                'requester_email' => 'ticket@example.com',
                'requester_phone' => '0400000010',
                'subject' => 'Help needed',
                'description' => 'Issue details duplicate',
                'source' => 'website',
                'category' => 'general',
                'priority' => 'normal',
                'status' => 'open',
                'intake_fingerprint' => 'tfp-1',
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);

        $reportPath = 'storage/app/reports/test_reconcile_dry_run.json';
        File::delete(base_path($reportPath));

        $this->artisan('crm:reconcile-intake', [
            '--report' => $reportPath,
        ])->assertSuccessful();

        $this->assertFileExists(base_path($reportPath));
        $report = json_decode((string) file_get_contents(base_path($reportPath)), true);

        $this->assertIsArray($report);
        $this->assertSame(false, $report['write_mode']);
        $this->assertSame(1, $report['duplicates']['support_tickets']['duplicate_groups']);
    }

    public function test_reconciliation_command_write_mode_normalizes_emails_and_phones(): void
    {
        $ticketId = DB::table('support_tickets')->insertGetId([
            'ticket_number' => 'TKT-009999',
            'requester_email' => '  HELP@EXAMPLE.COM  ',
            'requester_phone' => '+61 401-222-333',
            'subject' => 'Normalization',
            'description' => 'Normalize contact channels',
            'source' => 'website',
            'category' => 'general',
            'priority' => 'normal',
            'status' => 'open',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $reportPath = 'storage/app/reports/test_reconcile_write.json';
        File::delete(base_path($reportPath));

        $this->artisan('crm:reconcile-intake', [
            '--write' => true,
            '--report' => $reportPath,
        ])->assertSuccessful();

        $this->assertDatabaseHas('support_tickets', [
            'id' => $ticketId,
            'requester_email' => 'help@example.com',
            'requester_phone' => '+61401222333',
        ]);
    }
}
