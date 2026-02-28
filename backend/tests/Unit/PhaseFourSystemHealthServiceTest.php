<?php

namespace Tests\Unit;

use App\Services\SystemHealthService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class PhaseFourSystemHealthServiceTest extends TestCase
{
    use RefreshDatabase;

    public function test_run_checks_returns_expected_shape_and_keys(): void
    {
        config([
            'queue.default' => 'sync',
            'mail.default' => 'smtp',
            'mail.mailers.smtp.host' => '',
            'mail.from.address' => 'ops@example.com',
        ]);

        $summary = app(SystemHealthService::class)->runChecks();

        $this->assertArrayHasKey('overall', $summary);
        $this->assertArrayHasKey('failing_checks', $summary);
        $this->assertArrayHasKey('checks', $summary);
        $this->assertIsArray($summary['checks']);
        $this->assertContains($summary['overall'], ['healthy', 'at_risk', 'degraded']);

        $keys = collect($summary['checks'])->pluck('key')->all();
        $this->assertEqualsCanonicalizing(
            ['database', 'redis', 'queue', 'queue_processing', 'mail', 'ticket_intake', 'storage', 'fcm', 'stripe', 'scheduler', 'degraded_mode'],
            $keys
        );
    }

    public function test_mail_check_warns_when_smtp_host_is_missing(): void
    {
        config([
            'queue.default' => 'sync',
            'mail.default' => 'smtp',
            'mail.mailers.smtp.host' => '',
            'mail.from.address' => 'ops@example.com',
        ]);

        $summary = app(SystemHealthService::class)->runChecks();
        $mail = collect($summary['checks'])->firstWhere('key', 'mail');

        $this->assertNotNull($mail);
        $this->assertSame('warning', $mail['status']);
        $this->assertStringContainsString('MAIL_HOST', (string) $mail['message']);
    }

    public function test_queue_check_errors_when_sync_queue_is_used_outside_local_testing(): void
    {
        config([
            'app.env' => 'production',
            'queue.default' => 'sync',
            'mail.default' => 'array',
            'mail.from.address' => 'ops@example.com',
        ]);

        $summary = app(SystemHealthService::class)->runChecks();
        $queue = collect($summary['checks'])->firstWhere('key', 'queue');

        $this->assertNotNull($queue);
        $this->assertSame('error', $queue['status']);
        $this->assertStringContainsString('sync', strtolower((string) $queue['message']));
    }
}
