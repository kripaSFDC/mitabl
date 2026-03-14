<?php

namespace Tests\Unit;

use App\Models\Mikitchn;
use App\Models\StripeAccount;
use App\Models\User;
use App\Services\AccountProfileService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Request;
use Tests\TestCase;

class AccountProfileServiceSwitchRoleTest extends TestCase
{
    use RefreshDatabase;

    public function test_switch_role_rejects_invalid_target_role(): void
    {
        $user = User::factory()->create(['role_id' => 3]);

        $result = app(AccountProfileService::class)->switchRole(
            $user,
            Request::create('/api/v2/account/switch-role', 'POST', ['role_id' => 99])
        );

        $this->assertSame(422, $result['status']);
        $this->assertArrayHasKey('error', $result);
        $this->assertSame(3, (int) $user->fresh()->role_id);
    }

    public function test_switch_role_blocks_micook_when_no_profile_or_onboarding_footprint(): void
    {
        $user = User::factory()->create(['role_id' => 3]);

        $result = app(AccountProfileService::class)->switchRole(
            $user,
            Request::create('/api/v2/account/switch-role', 'POST', ['role_id' => 2])
        );

        $this->assertSame(422, $result['status']);
        $this->assertSame('micook profile is not available for this account.', $result['error']);
        $this->assertSame(3, (int) $user->fresh()->role_id);
    }

    public function test_switch_role_allows_micook_when_vendor_onboarding_exists(): void
    {
        $user = User::factory()->create(['role_id' => 3]);
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
    }

    public function test_switch_role_allows_micook_when_kitchen_profile_exists(): void
    {
        $user = User::factory()->create(['role_id' => 3]);
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
    }

    public function test_switch_role_to_mifoodi_is_always_allowed_for_authenticated_user(): void
    {
        $user = User::factory()->create(['role_id' => 2]);

        $result = app(AccountProfileService::class)->switchRole(
            $user,
            Request::create('/api/v2/account/switch-role', 'POST', ['role_id' => 3])
        );

        $this->assertArrayHasKey('user', $result);
        $this->assertSame(3, (int) $user->fresh()->role_id);
    }
}
