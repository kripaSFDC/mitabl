<?php

namespace Tests\Feature\Api;

use App\Models\Role;
use App\Models\User;
use App\Models\UserRole;
use App\Services\PaymentService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Mockery;
use Tests\TestCase;

class V2AccountRoleSwitchOnboardingContractTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        Role::query()->insert([
            ['id' => 2, 'role' => 'Restaurant', 'created_at' => now(), 'updated_at' => now()],
            ['id' => 3, 'role' => 'Foodie', 'created_at' => now(), 'updated_at' => now()],
        ]);
    }

    public function test_switch_role_returns_onboarding_payload_when_stripe_vendor_provisioning_fails(): void
    {
        $user = User::factory()->create(['role_id' => 3]);
        UserRole::query()->create(['user_id' => $user->id, 'role_id' => 3, 'status' => UserRole::STATUS_ACTIVE]);

        $paymentService = Mockery::mock(PaymentService::class);
        $paymentService->shouldReceive('createVendor')->andThrow(new \RuntimeException('stripe unavailable'));
        $paymentService->shouldReceive('createCustomer')->andReturn((object) ['id' => 'cus_test_123']);
        $this->app->instance(PaymentService::class, $paymentService);

        $this->actingAs($user, 'api')
            ->postJson('/api/v2/account/switch-role', ['role_id' => 2])
            ->assertOk()
            ->assertJsonPath('data.onboarding_required', true)
            ->assertJsonPath('data.role_transition.state', 'onboarding_required')
            ->assertJsonPath('data.role_transition.missing.0', 'vendor_account')
            ->assertJsonPath('data.role_transition.next_required_step', 'vendor_account')
            ->assertJsonMissingPath('isError');

        $this->assertSame(2, (int) $user->fresh()->role_id);
        $this->assertDatabaseHas('user_roles', [
            'user_id' => $user->id,
            'role_id' => 2,
            'status' => UserRole::STATUS_ONBOARDING,
        ]);
    }

    public function test_vendor_account_onboarding_step_returns_progress_payload_when_stripe_fails(): void
    {
        $user = User::factory()->create(['role_id' => 2]);

        $paymentService = Mockery::mock(PaymentService::class);
        $paymentService->shouldReceive('createVendor')->andThrow(new \RuntimeException('stripe unavailable'));
        $paymentService->shouldReceive('createCustomer')->andReturn((object) ['id' => 'cus_test_123']);
        $this->app->instance(PaymentService::class, $paymentService);

        $this->actingAs($user, 'api')
            ->postJson('/api/v2/account/onboarding/cook/vendor-account')
            ->assertOk()
            ->assertJsonPath('data.provisioned', false)
            ->assertJsonPath('data.provision_error', 'Unable to create Stripe account.')
            ->assertJsonPath('data.onboarding_required', true)
            ->assertJsonPath('data.role_transition.state', 'onboarding_required')
            ->assertJsonPath('data.role_transition.missing.0', 'vendor_account')
            ->assertJsonPath('data.role_transition.next_required_step', 'vendor_account');

        $this->assertDatabaseHas('user_roles', [
            'user_id' => $user->id,
            'role_id' => 2,
            'status' => UserRole::STATUS_ONBOARDING,
        ]);
    }

}
