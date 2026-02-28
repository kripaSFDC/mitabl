<?php

namespace Tests\Unit;

use App\Models\AdminActionLog;
use Illuminate\Foundation\Testing\RefreshDatabase;
use LogicException;
use Tests\TestCase;

class PhaseFourAdminActionLogModelTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_action_logs_are_immutable_for_update_and_delete(): void
    {
        $log = AdminActionLog::query()->create([
            'action' => 'phase4.model.test',
            'method' => 'POST',
            'path' => 'admin/test',
            'status_code' => 200,
            'metadata' => ['a' => 1],
            'request_payload' => ['b' => 2],
            'created_at' => now(),
        ]);

        try {
            $log->update(['action' => 'phase4.model.updated']);
            $this->fail('Expected update to be blocked for immutable logs.');
        } catch (LogicException $exception) {
            $this->assertStringContainsString('immutable', strtolower($exception->getMessage()));
        }

        try {
            $log->delete();
            $this->fail('Expected delete to be blocked for immutable logs.');
        } catch (LogicException $exception) {
            $this->assertStringContainsString('immutable', strtolower($exception->getMessage()));
        }
    }
}
