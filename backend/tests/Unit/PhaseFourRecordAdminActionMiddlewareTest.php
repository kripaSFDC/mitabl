<?php

namespace Tests\Unit;

use App\Http\Middleware\RecordAdminAction;
use App\Models\AdminActionLog;
use App\Models\AdminUser;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Route;
use Tests\TestCase;

class PhaseFourRecordAdminActionMiddlewareTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        Route::middleware(['web', RecordAdminAction::class])
            ->post('/_phase4/middleware/success', function () {
                return response()->json(['ok' => true], 201);
            })
            ->name('phase4.middleware.success');

        Route::middleware(['web', RecordAdminAction::class])
            ->post('/_phase4/middleware/error', function () {
                abort(422, 'phase4 test error');
            })
            ->name('phase4.middleware.error');

        Route::middleware(['web', RecordAdminAction::class])
            ->get('/_phase4/middleware/read', function () {
                return response()->json(['ok' => true], 200);
            })
            ->name('phase4.middleware.read');
    }

    public function test_middleware_logs_state_changing_success_requests(): void
    {
        $admin = $this->createAdmin();

        $this->actingAs($admin, 'admin')
            ->post('/_phase4/middleware/success', [
                'sensitive' => 'x',
            ])
            ->assertStatus(201);

        $this->assertDatabaseHas('admin_action_logs', [
            'admin_user_id' => $admin->id,
            'action' => 'phase4.middleware.success',
            'method' => 'POST',
            'status_code' => 201,
        ]);
    }

    public function test_middleware_logs_state_changing_error_requests(): void
    {
        $admin = $this->createAdmin();

        $this->actingAs($admin, 'admin')
            ->post('/_phase4/middleware/error', [
                'key' => 'value',
            ])
            ->assertStatus(422);

        $this->assertDatabaseHas('admin_action_logs', [
            'admin_user_id' => $admin->id,
            'action' => 'phase4.middleware.error',
            'method' => 'POST',
            'status_code' => 422,
        ]);

        $log = AdminActionLog::query()
            ->where('action', 'phase4.middleware.error')
            ->latest('id')
            ->firstOrFail();

        $this->assertStringContainsString('phase4 test error', (string) data_get($log->metadata, 'error'));
    }

    public function test_middleware_does_not_log_safe_get_requests(): void
    {
        $admin = $this->createAdmin();

        $this->actingAs($admin, 'admin')
            ->get('/_phase4/middleware/read')
            ->assertOk();

        $this->assertDatabaseMissing('admin_action_logs', [
            'action' => 'phase4.middleware.read',
            'method' => 'GET',
        ]);
    }

    private function createAdmin(): AdminUser
    {
        return AdminUser::query()->create([
            'name' => 'Middleware Admin',
            'email' => 'middleware-admin-' . uniqid() . '@example.com',
            'password' => Hash::make('password'),
            'is_active' => true,
        ]);
    }
}
