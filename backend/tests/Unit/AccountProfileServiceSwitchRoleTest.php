<?php

namespace Tests\Unit;

use App\Models\Certificate;
use App\Models\Mikitchn;
use App\Models\Role;
use App\Models\StripeAccount;
use App\Models\User;
use App\Models\UserRole;
use App\Services\AccountProfileService;
use App\Services\PaymentService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Request;
use Mockery;
use Tests\TestCase;

class AccountProfileServiceSwitchRoleTest extends TestCase
{
    use RefreshDatabase;

    private int $vendorSequence = 1;

    protected function setUp(): void
    {
        parent::setUp();

        Role::query()->insert([
            ['id' => 2, 'role' => 'Restaurant', 'created_at' => now(), 'updated_at' => now()],
            ['id' => 3, 'role' => 'Foodie', 'created_at' => now(), 'updated_at' => now()],
        ]);

        $paymentService = Mockery::mock(PaymentService::class);
        $paymentService->shouldReceive('createVendor')
            ->andReturnUsing(function () {
                return (object) ['id' => 'acct_vendor_' . $this->vendorSequence++];
            });
        $paymentService->shouldReceive('createCustomer')->andReturn((object) ['id' => 'cus_test_123']);

        $this->app->instance(PaymentService::class, $paymentService);
    }

    public function test_switch_role_rejects_invalid_target_role(): void
    {
        $user = User::factory()->create(['role_id' => 3]);
        UserRole::query()->create(['user_id' => $user->id, 'role_id' => 3, 'status' => UserRole::STATUS_ACTIVE]);

        $result = app(AccountProfileService::class)->switchRole(
            $user,
            Request::create('/api/v2/account/switch-role', 'POST', ['role_id' => 99])
        );

        $this->assertSame(422, $result['status']);
        $this->assertArrayHasKey('error', $result);
        $this->assertSame(3, (int) $user->fresh()->role_id);
    }

    public function test_switch_role_to_micook_returns_transition_state_for_first_time_conversion(): void
    {
        $user = User::factory()->create(['role_id' => 3]);
        UserRole::query()->create(['user_id' => $user->id, 'role_id' => 3, 'status' => UserRole::STATUS_ACTIVE]);

        $result = app(AccountProfileService::class)->switchRole(
            $user,
            Request::create('/api/v2/account/switch-role', 'POST', ['role_id' => 2])
        );

        $this->assertArrayHasKey('user', $result);
        $this->assertSame(2, (int) $user->fresh()->role_id);
        $this->assertTrue($result['onboarding_required']);
        $this->assertSame('onboarding_required', $result['role_transition']['state']);
        $this->assertSame(['vendor_account', 'kitchen_profile', 'certificate', 'payout_setup'], $result['role_transition']['missing']);
        $this->assertSame('vendor_account', $result['role_transition']['next_required_step']);
        $this->assertDatabaseMissing('stripe_accounts', [
            'user_id' => $user->id,
            'account_type' => 'vendor',
        ]);
    }

    public function test_switch_role_to_existing_micook_still_returns_transition_payload(): void
    {
        $user = User::factory()->create(['role_id' => 2]);

        $result = app(AccountProfileService::class)->switchRole(
            $user,
            Request::create('/api/v2/account/switch-role', 'POST', ['role_id' => 2])
        );

        $this->assertArrayHasKey('user', $result);
        $this->assertTrue($result['onboarding_required']);
        $this->assertSame('onboarding_required', $result['role_transition']['state']);
        $this->assertSame(['vendor_account', 'kitchen_profile', 'certificate', 'payout_setup'], $result['role_transition']['missing']);
        $this->assertSame('vendor_account', $result['role_transition']['next_required_step']);
    }

    public function test_switch_role_to_micook_uses_fresh_relations_after_vendor_provisioning(): void
    {
        $user = User::factory()->create(['role_id' => 3]);
        UserRole::query()->create(['user_id' => $user->id, 'role_id' => 3, 'status' => UserRole::STATUS_ACTIVE]);
        $user->load('vendor');

        $result = app(AccountProfileService::class)->switchRole(
            $user,
            Request::create('/api/v2/account/switch-role', 'POST', ['role_id' => 2])
        );

        $this->assertSame('onboarding_required', $result['role_transition']['state']);
        $this->assertSame(['vendor_account', 'kitchen_profile', 'certificate', 'payout_setup'], $result['role_transition']['missing']);
        $this->assertSame('vendor_account', $result['role_transition']['next_required_step']);
    }

    public function test_cook_to_foodie_switch_works_with_existing_memberships(): void
    {
        $user = User::factory()->create(['role_id' => 2]);
        UserRole::query()->create(['user_id' => $user->id, 'role_id' => 2, 'status' => UserRole::STATUS_ACTIVE]);
        UserRole::query()->create(['user_id' => $user->id, 'role_id' => 3, 'status' => UserRole::STATUS_ACTIVE]);

        $result = app(AccountProfileService::class)->switchRole(
            $user,
            Request::create('/api/v2/account/switch-role', 'POST', ['role_id' => 3])
        );

        $this->assertArrayHasKey('user', $result);
        $this->assertFalse($result['onboarding_required']);
        $this->assertSame('ready', $result['role_transition']['state']);
        $this->assertSame([], $result['role_transition']['missing']);
        $this->assertNull($result['role_transition']['next_required_step']);
        $this->assertSame(3, (int) $user->fresh()->role_id);
    }

    public function test_foodie_to_cook_switch_returns_onboarding_when_membership_is_onboarding(): void
    {
        $user = User::factory()->create(['role_id' => 3]);
        UserRole::query()->create(['user_id' => $user->id, 'role_id' => 3, 'status' => UserRole::STATUS_ACTIVE]);
        UserRole::query()->create(['user_id' => $user->id, 'role_id' => 2, 'status' => UserRole::STATUS_ONBOARDING]);

        $result = app(AccountProfileService::class)->switchRole(
            $user,
            Request::create('/api/v2/account/switch-role', 'POST', ['role_id' => 2])
        );

        $this->assertArrayHasKey('user', $result);
        $this->assertTrue($result['onboarding_required']);
        $this->assertSame(2, (int) $user->fresh()->role_id);
    }

    public function test_switch_role_marks_first_time_vendor_activation_as_onboarding(): void
    {
        $user = User::factory()->create(['role_id' => 3]);
        UserRole::query()->create(['user_id' => $user->id, 'role_id' => 3, 'status' => UserRole::STATUS_ACTIVE]);

        $stripeAccount = new StripeAccount();
        $stripeAccount->user_id = $user->id;
        $stripeAccount->account_type = 'vendor';
        $stripeAccount->account_id = 'acct_vendor_123';
        $stripeAccount->save();

        $result = app(AccountProfileService::class)->switchRole(
            $user,
            Request::create('/api/v2/account/switch-role', 'POST', ['role_id' => 2])
        );

        $this->assertArrayHasKey('user', $result);
        $this->assertTrue($result['onboarding_required']);
        $this->assertSame(2, (int) $user->fresh()->role_id);
        $this->assertSame('onboarding_required', $result['role_transition']['state']);
        $this->assertSame(['kitchen_profile', 'certificate'], $result['role_transition']['missing']);
        $this->assertSame('kitchen_profile', $result['role_transition']['next_required_step']);
        $this->assertDatabaseHas('user_roles', [
            'user_id' => $user->id,
            'role_id' => 2,
            'status' => UserRole::STATUS_ONBOARDING,
        ]);
    }

    public function test_switch_role_allows_micook_when_kitchen_profile_exists(): void
    {
        $user = User::factory()->create(['role_id' => 3]);
        UserRole::query()->create(['user_id' => $user->id, 'role_id' => 3, 'status' => UserRole::STATUS_ACTIVE]);
        Mikitchn::query()->create([
            'user_id' => $user->id,
            'name' => 'Kitchen Test',
            'address' => '123 Test Street',
            'phone' => '0400000000',
            'no_of_seats' => 4,
            'status' => '0',
        ]);

        $result = app(AccountProfileService::class)->switchRole(
            $user,
            Request::create('/api/v2/account/switch-role', 'POST', ['role_id' => 2])
        );

        $this->assertArrayHasKey('user', $result);
        $this->assertSame(2, (int) $user->fresh()->role_id);
        $this->assertSame('onboarding_required', $result['role_transition']['state']);
        $this->assertSame(['vendor_account', 'certificate', 'payout_setup'], $result['role_transition']['missing']);
        $this->assertSame('vendor_account', $result['role_transition']['next_required_step']);
    }

    public function test_start_cook_onboarding_promotes_role_and_returns_next_step(): void
    {
        $user = User::factory()->create(['role_id' => 3]);

        $result = app(AccountProfileService::class)->startCookOnboarding($user);

        $this->assertArrayHasKey('user', $result);
        $this->assertSame(2, (int) $user->fresh()->role_id);
        $this->assertTrue($result['onboarding_required']);
        $this->assertTrue($result['role_transition']['onboarding_started']);
        $this->assertSame('onboarding_required', $result['role_transition']['state']);
        $this->assertSame(['vendor_account', 'kitchen_profile', 'certificate', 'payout_setup'], $result['role_transition']['missing']);
        $this->assertSame('vendor_account', $result['role_transition']['next_required_step']);
    }

    public function test_switch_role_to_micook_creates_foodie_membership_for_cook_first_accounts(): void
    {
        $user = User::factory()->create(['role_id' => 3]);
        UserRole::query()->create(['user_id' => $user->id, 'role_id' => 3, 'status' => UserRole::STATUS_ACTIVE]);

        app(AccountProfileService::class)->switchRole(
            $user,
            Request::create('/api/v2/account/switch-role', 'POST', ['role_id' => 2])
        );

        $this->assertDatabaseHas('user_roles', [
            'user_id' => $user->id,
            'role_id' => 3,
            'status' => UserRole::STATUS_ACTIVE,
        ]);
    }

    public function test_switch_role_to_micook_persists_onboarding_checklist_state(): void
    {
        $user = User::factory()->create(['role_id' => 3]);
        UserRole::query()->create(['user_id' => $user->id, 'role_id' => 3, 'status' => UserRole::STATUS_ACTIVE]);

        app(AccountProfileService::class)->switchRole(
            $user,
            Request::create('/api/v2/account/switch-role', 'POST', ['role_id' => 2])
        );

        $this->assertDatabaseHas('user_role_onboarding_checklists', [
            'user_id' => $user->id,
            'role_id' => 2,
            'vendor_account_completed' => 0,
            'kitchen_profile_completed' => 0,
            'certificate_completed' => 0,
        ]);
    }

    public function test_start_cook_onboarding_promotes_role_even_when_vendor_provisioning_would_fail_later(): void
    {
        $user = User::factory()->create(['role_id' => 3]);

        $result = app(AccountProfileService::class)->startCookOnboarding($user);

        $this->assertArrayHasKey('user', $result);
        $this->assertSame(2, (int) $user->fresh()->role_id);
        $this->assertTrue($result['onboarding_required']);
        $this->assertSame(['vendor_account', 'kitchen_profile', 'certificate', 'payout_setup'], $result['role_transition']['missing']);
        $this->assertSame('vendor_account', $result['role_transition']['next_required_step']);
    }


    public function test_switch_role_to_micook_returns_onboarding_payload_when_vendor_provisioning_fails(): void
    {
        $user = User::factory()->create(['role_id' => 3]);
        UserRole::query()->create(['user_id' => $user->id, 'role_id' => 3, 'status' => UserRole::STATUS_ACTIVE]);

        $paymentService = Mockery::mock(PaymentService::class);
        $paymentService->shouldReceive('createVendor')->andThrow(new \RuntimeException('stripe unavailable'));
        $paymentService->shouldReceive('createCustomer')->andReturn((object) ['id' => 'cus_test_123']);
        $this->app->instance(PaymentService::class, $paymentService);

        $result = app(AccountProfileService::class)->switchRole(
            $user,
            Request::create('/api/v2/account/switch-role', 'POST', ['role_id' => 2])
        );

        $this->assertArrayNotHasKey('error', $result);
        $this->assertSame(2, (int) $user->fresh()->role_id);
        $this->assertTrue($result['onboarding_required']);
        $this->assertSame('onboarding_required', $result['role_transition']['state']);
        $this->assertSame(['vendor_account', 'kitchen_profile', 'certificate', 'payout_setup'], $result['role_transition']['missing']);
        $this->assertSame('vendor_account', $result['role_transition']['next_required_step']);
    }

    public function test_complete_cook_vendor_account_step_reports_failure_without_hard_error(): void
    {
        $user = User::factory()->create(['role_id' => 2]);

        $paymentService = Mockery::mock(PaymentService::class);
        $paymentService->shouldReceive('createVendor')->andThrow(new \RuntimeException('stripe unavailable'));
        $paymentService->shouldReceive('createCustomer')->andReturn((object) ['id' => 'cus_test_123']);
        $this->app->instance(PaymentService::class, $paymentService);

        $result = app(AccountProfileService::class)->completeCookVendorAccountStep($user);

        $this->assertFalse($result['provisioned']);
        $this->assertSame('Unable to create Stripe account.', $result['provision_error']);
        $this->assertTrue($result['onboarding_required']);
        $this->assertSame(['vendor_account', 'kitchen_profile', 'certificate', 'payout_setup'], $result['role_transition']['missing']);
    }

    public function test_switch_role_rejects_disabled_membership(): void
    {
        $user = User::factory()->create(['role_id' => 3]);
        UserRole::query()->create(['user_id' => $user->id, 'role_id' => 3, 'status' => UserRole::STATUS_ACTIVE]);
        UserRole::query()->create(['user_id' => $user->id, 'role_id' => 2, 'status' => UserRole::STATUS_DISABLED]);

        $result = app(AccountProfileService::class)->switchRole(
            $user,
            Request::create('/api/v2/account/switch-role', 'POST', ['role_id' => 2])
        );

        $this->assertSame(422, $result['status']);
        $this->assertSame('Requested role is disabled for this account.', $result['error']);
        $this->assertSame(3, (int) $user->fresh()->role_id);
        $this->assertNull($result['role_transition']);
    }
}
