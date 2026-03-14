<?php

namespace Tests\Unit;

use App\Models\Mikitchn;
use App\Models\StripeAccount;
use App\Models\User;
use App\Models\UserRole;
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
        UserRole::query()->create(['user_id' => $user->id, 'role_id' => 3, 'status' => UserRole::STATUS_ACTIVE]);

        $result = app(AccountProfileService::class)->switchRole(
            $user,
            Request::create('/api/v2/account/switch-role', 'POST', ['role_id' => 99])
        );

        $this->assertSame(422, $result['status']);
        $this->assertArrayHasKey('error', $result);
        $this->assertSame(3, (int) $user->fresh()->role_id);
    }

    public function test_switch_role_blocks_micook_when_no_profile_or_membership(): void
    {
        $user = User::factory()->create(['role_id' => 3]);
        UserRole::query()->create(['user_id' => $user->id, 'role_id' => 3, 'status' => UserRole::STATUS_ACTIVE]);

        $result = app(AccountProfileService::class)->switchRole(
            $user,
            Request::create('/api/v2/account/switch-role', 'POST', ['role_id' => 2])
        );

        $this->assertSame(422, $result['status']);
        $this->assertSame('micook profile is not available for this account.', $result['error']);
        $this->assertSame(3, (int) $user->fresh()->role_id);
    }

    public function test_cook_to_foodi_switch_works_with_existing_memberships(): void
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

    public function test_switch_role_allows_micook_when_vendor_onboarding_exists_and_backfills_membership(): void
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
        $this->assertSame(2, (int) $user->fresh()->role_id);
        $this->assertDatabaseHas('user_roles', [
            'user_id' => $user->id,
            'role_id' => 2,
            'status' => UserRole::STATUS_ACTIVE,
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
    }
}
