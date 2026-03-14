<?php

namespace Tests\Unit;

use App\Models\Mikitchn;
use App\Models\StripeAccount;
use App\Models\User;
use App\Services\AccountProfileService;
use App\Services\PaymentService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Request;
use Mockery;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class AccountProfileServiceSwitchRoleTest extends TestCase
{
    use RefreshDatabase;

    private int $vendorSequence = 1;

    protected function setUp(): void
    {
        parent::setUp();

        $paymentService = Mockery::mock(PaymentService::class);
        $paymentService->shouldReceive('createVendor')
            ->andReturnUsing(function () {
                return (object) ['id' => 'acct_vendor_' . $this->vendorSequence++];
            });
        $paymentService->shouldReceive('createCustomer')->andReturn((object) ['id' => 'cus_test_123']);

        $this->app->instance(PaymentService::class, $paymentService);
    }


    private function createUser(int $roleId): User
    {
        return User::query()->create([
            'first_name' => 'Test',
            'last_name' => 'User',
            'email' => 'user' . uniqid('', true) . '@example.test',
            'password' => Hash::make('password123'),
            'phone' => '0400000000',
            'role_id' => $roleId,
            'email_verified' => true,
            'address' => 'test',
        ]);
    }

    public function test_switch_role_rejects_invalid_target_role(): void
    {
        $user = $this->createUser(3);

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
        $user = $this->createUser(3);

        $result = app(AccountProfileService::class)->switchRole(
            $user,
            Request::create('/api/v2/account/switch-role', 'POST', ['role_id' => 2])
        );

        $this->assertArrayHasKey('user', $result);
        $this->assertSame(2, (int) $user->fresh()->role_id);
        $this->assertSame('onboarding_required', $result['role_transition']['state']);
        $this->assertSame(['kitchen_profile', 'certificate'], $result['role_transition']['missing']);

        $this->assertDatabaseHas('stripe_accounts', [
            'user_id' => $user->id,
            'account_type' => 'vendor',
        ]);
    }

    public function test_switch_role_to_existing_micook_still_returns_transition_payload(): void
    {
        $user = $this->createUser(2);

        $result = app(AccountProfileService::class)->switchRole(
            $user,
            Request::create('/api/v2/account/switch-role', 'POST', ['role_id' => 2])
        );

        $this->assertArrayHasKey('user', $result);
        $this->assertSame('onboarding_required', $result['role_transition']['state']);
        $this->assertSame(['vendor_account', 'kitchen_profile', 'certificate'], $result['role_transition']['missing']);
    }

    public function test_switch_role_allows_micook_when_vendor_onboarding_exists(): void
    {
        $user = $this->createUser(3);
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
        $this->assertSame(2, (int) $user->fresh()->role_id);
        $this->assertSame('onboarding_required', $result['role_transition']['state']);
        $this->assertSame(['kitchen_profile', 'certificate'], $result['role_transition']['missing']);
    }

    public function test_switch_role_allows_micook_when_kitchen_profile_exists(): void
    {
        $user = $this->createUser(3);
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
        $this->assertSame(['certificate'], $result['role_transition']['missing']);
    }

    public function test_start_cook_onboarding_promotes_role_and_returns_next_step(): void
    {
        $user = $this->createUser(3);

        $result = app(AccountProfileService::class)->startCookOnboarding($user);

        $this->assertArrayHasKey('user', $result);
        $this->assertSame(2, (int) $user->fresh()->role_id);
        $this->assertTrue($result['role_transition']['onboarding_started']);
        $this->assertSame('onboarding_required', $result['role_transition']['state']);
        $this->assertSame(['kitchen_profile', 'certificate'], $result['role_transition']['missing']);
        $this->assertSame('kitchen_profile', $result['role_transition']['next_required_step']);
    }

    public function test_start_cook_onboarding_does_not_promote_role_when_vendor_provisioning_fails(): void
    {
        $user = $this->createUser(3);

        $paymentService = Mockery::mock(PaymentService::class);
        $paymentService->shouldReceive('createVendor')->andThrow(new \RuntimeException('stripe unavailable'));
        $paymentService->shouldReceive('createCustomer')->andReturn((object) ['id' => 'cus_test_123']);
        $this->app->instance(PaymentService::class, $paymentService);

        $result = app(AccountProfileService::class)->startCookOnboarding($user);

        $this->assertSame(422, $result['status']);
        $this->assertSame('Unable to create Stripe account.', $result['error']);
        $this->assertSame(3, (int) $user->fresh()->role_id);
    }

    public function test_switch_role_to_mifoodi_is_always_allowed_for_authenticated_user(): void
    {
        $user = $this->createUser(2);

        $result = app(AccountProfileService::class)->switchRole(
            $user,
            Request::create('/api/v2/account/switch-role', 'POST', ['role_id' => 3])
        );

        $this->assertArrayHasKey('user', $result);
        $this->assertSame(3, (int) $user->fresh()->role_id);
        $this->assertNull($result['role_transition']);
    }
}
