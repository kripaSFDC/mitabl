<?php

namespace Tests\Unit;

use App\Models\PlatformSetting;
use App\Services\SystemHealthService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
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

    public function test_degraded_mode_check_includes_incident_annotation_and_postmortem(): void
    {
        PlatformSetting::query()->create([
            'key' => 'incident.degraded_mode',
            'value' => [
                'enabled' => true,
                'annotation' => 'Payments API instability',
                'postmortem_url' => 'https://status.example.com/postmortems/123',
            ],
            'value_type' => 'json',
            'version' => 1,
        ]);

        config([
            'queue.default' => 'database',
            'mail.default' => 'array',
            'mail.from.address' => 'ops@example.com',
        ]);

        $summary = app(SystemHealthService::class)->runChecks();
        $degradedMode = collect($summary['checks'])->firstWhere('key', 'degraded_mode');

        $this->assertNotNull($degradedMode);
        $this->assertSame('warning', $degradedMode['status']);
        $this->assertStringContainsString('Payments API instability', (string) $degradedMode['message']);
        $this->assertStringContainsString('postmortems/123', (string) $degradedMode['message']);
    }


    public function test_queue_processing_detects_poison_message_retries_from_exception_text(): void
    {
        DB::table('failed_jobs')->insert([
            'uuid' => (string) \Illuminate\Support\Str::uuid(),
            'connection' => 'redis',
            'queue' => 'default',
            'payload' => json_encode(['displayName' => 'ExampleJob', 'maxTries' => 1]),
            'exception' => 'App\Jobs\ExampleJob has been attempted too many times or run too long. The job may have previously timed out.',
            'failed_at' => now(),
        ]);

        config([
            'queue.default' => 'database',
            'mail.default' => 'array',
            'mail.from.address' => 'ops@example.com',
        ]);

        $summary = app(SystemHealthService::class)->runChecks();
        $queueProcessing = collect($summary['checks'])->firstWhere('key', 'queue_processing');

        $this->assertNotNull($queueProcessing);
        $this->assertContains($queueProcessing['status'], ['warning', 'error']);
        $this->assertStringContainsString('poison-message retries', strtolower((string) $queueProcessing['message']));
    }

    public function test_queue_processing_does_not_require_jobs_table_for_redis_queue_driver(): void
    {
        DB::table('failed_jobs')->insert([
            'uuid' => (string) \Illuminate\Support\Str::uuid(),
            'connection' => 'redis',
            'queue' => 'default',
            'payload' => json_encode(['displayName' => 'ExampleJob']),
            'exception' => 'example failure',
            'failed_at' => now(),
        ]);

        config([
            'queue.default' => 'redis',
            'mail.default' => 'array',
            'mail.from.address' => 'ops@example.com',
        ]);

        $summary = app(SystemHealthService::class)->runChecks();
        $queueProcessing = collect($summary['checks'])->firstWhere('key', 'queue_processing');

        $this->assertNotNull($queueProcessing);
        $this->assertStringContainsString('Failed jobs detected (1).', (string) $queueProcessing['message']);
        $this->assertStringNotContainsString('missing table(s): jobs', strtolower((string) $queueProcessing['message']));
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
