<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Tests\TestCase;

class PhaseFiveReconciliationCommandTest extends TestCase
{
    use RefreshDatabase;

    public function test_reconciliation_command_produces_duplicate_and_count_report_in_dry_run(): void
    {
        DB::table('pre_registrations')->insert([
            [
                'first_name' => 'Alpha',
                'last_name' => 'Lead',
                'email' => 'alpha@example.com',
                'phone' => '0400000001',
                'city' => 'Sydney',
                'interested_as' => 'foodie',
                'source' => 'website',
                'status' => 'new',
                'duplicate_fingerprint' => 'fp-1',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'first_name' => 'Beta',
                'last_name' => 'Lead',
                'email' => 'beta@example.com',
                'phone' => '0400000002',
                'city' => 'Melbourne',
                'interested_as' => 'cook',
                'source' => 'website',
                'status' => 'new',
                'duplicate_fingerprint' => 'fp-1',
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);

        DB::table('support_tickets')->insert([
            [
                'ticket_number' => 'TKT-000001',
                'requester_email' => 'ticket@example.com',
                'requester_phone' => '0400000010',
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
        $this->assertSame(1, $report['duplicates']['pre_registrations']['duplicate_groups']);
        $this->assertSame(1, $report['duplicates']['support_tickets']['duplicate_groups']);
    }

    public function test_reconciliation_command_write_mode_normalizes_emails_and_phones(): void
    {
        $preRegistrationId = DB::table('pre_registrations')->insertGetId([
            'first_name' => 'Case',
            'last_name' => 'Lead',
            'email' => '  CASE@EXAMPLE.COM  ',
            'phone' => '+61 (400) 123-456',
            'city' => 'Brisbane',
            'interested_as' => 'foodie',
            'source' => 'website',
            'status' => 'new',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

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

        $this->assertDatabaseHas('pre_registrations', [
            'id' => $preRegistrationId,
            'email' => 'case@example.com',
            'phone' => '+61400123456',
        ]);

        $this->assertDatabaseHas('support_tickets', [
            'id' => $ticketId,
            'requester_email' => 'help@example.com',
            'requester_phone' => '+61401222333',
        ]);
    }
}
