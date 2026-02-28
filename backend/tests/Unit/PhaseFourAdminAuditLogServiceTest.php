<?php

namespace Tests\Unit;

use App\Models\AdminActionLog;
use App\Models\AdminUser;
use App\Services\AdminAuditLogService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class PhaseFourAdminAuditLogServiceTest extends TestCase
{
    use RefreshDatabase;

    public function test_log_persists_redacted_and_sanitized_payload(): void
    {
        $admin = $this->createAdmin();
        $this->actingAs($admin, 'admin');

        request()->headers->set('X-Request-Id', 'not-a-uuid');

        $resource = fopen('php://memory', 'r');

        app(AdminAuditLogService::class)->log(
            'phase4.audit.test',
            request(),
            ['source' => 'unit'],
            [
                'password' => 'top-secret',
                'token' => 'abc',
                'nested' => [
                    'authorization' => 'Bearer value',
                    'normal' => str_repeat('a', 600),
                ],
                'obj' => (object) ['k' => 'v'],
                'res' => $resource,
            ],
            201
        );

        if (is_resource($resource)) {
            fclose($resource);
        }

        /** @var AdminActionLog $log */
        $log = AdminActionLog::query()->latest('id')->firstOrFail();

        $this->assertSame($admin->id, $log->admin_user_id);
        $this->assertSame('phase4.audit.test', $log->action);
        $this->assertSame(201, $log->status_code);
        $this->assertSame('[redacted]', data_get($log->request_payload, 'password'));
        $this->assertSame('[redacted]', data_get($log->request_payload, 'token'));
        $this->assertSame('[redacted]', data_get($log->request_payload, 'nested.authorization'));
        $this->assertStringContainsString('...[truncated]', (string) data_get($log->request_payload, 'nested.normal'));
        $this->assertStringContainsString('[object:', (string) data_get($log->request_payload, 'obj'));
        $this->assertSame('[resource]', data_get($log->request_payload, 'res'));
        $this->assertSame('unit', data_get($log->metadata, 'source'));
        $this->assertNull($log->correlation_id);
    }

    private function createAdmin(): AdminUser
    {
        return AdminUser::query()->create([
            'name' => 'Phase4 Admin',
            'email' => 'phase4-admin-' . uniqid() . '@example.com',
            'password' => Hash::make('password'),
            'is_active' => true,
        ]);
    }
}
