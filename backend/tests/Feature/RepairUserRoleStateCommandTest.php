<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\UserRole;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class RepairUserRoleStateCommandTest extends TestCase
{
    use RefreshDatabase;

    public function test_command_backfills_missing_memberships_from_users_table(): void
    {
        $user = $this->createUser(3, 'repair-backfill@example.test');

        $this->assertDatabaseMissing('user_roles', [
            'user_id' => $user->id,
            'role_id' => 3,
        ]);

        $this->artisan('roles:repair-state')
            ->assertExitCode(0);

        $this->assertDatabaseHas('user_roles', [
            'user_id' => $user->id,
            'role_id' => 3,
            'status' => UserRole::STATUS_ACTIVE,
        ]);
    }

    public function test_command_repairs_onboarding_memberships_when_checklist_is_complete(): void
    {
        $user = $this->createUser(2, 'repair-onboarding@example.test');

        DB::table('user_roles')->insert([
            'user_id' => $user->id,
            'role_id' => 2,
            'status' => UserRole::STATUS_ONBOARDING,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        DB::table('user_role_onboarding_checklists')->insert([
            'user_id' => $user->id,
            'role_id' => 2,
            'vendor_account_completed' => 1,
            'kitchen_profile_completed' => 1,
            'certificate_completed' => 1,
            'payout_setup_completed' => 1,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $this->artisan('roles:repair-state')
            ->assertExitCode(0);

        $this->assertDatabaseHas('user_roles', [
            'user_id' => $user->id,
            'role_id' => 2,
            'status' => UserRole::STATUS_ACTIVE,
        ]);
    }

    public function test_command_dry_run_does_not_mutate_memberships_or_statuses(): void
    {
        $user = $this->createUser(2, 'repair-dry-run@example.test');

        DB::table('user_roles')->insert([
            'user_id' => $user->id,
            'role_id' => 2,
            'status' => UserRole::STATUS_ONBOARDING,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        DB::table('user_role_onboarding_checklists')->insert([
            'user_id' => $user->id,
            'role_id' => 2,
            'vendor_account_completed' => 1,
            'kitchen_profile_completed' => 1,
            'certificate_completed' => 1,
            'payout_setup_completed' => 1,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $this->artisan('roles:repair-state', ['--dry-run' => true])
            ->assertExitCode(0);

        $this->assertDatabaseHas('user_roles', [
            'user_id' => $user->id,
            'role_id' => 2,
            'status' => UserRole::STATUS_ONBOARDING,
        ]);
    }


    public function test_command_preserves_existing_disabled_memberships(): void
    {
        $user = $this->createUser(3, 'repair-preserve-disabled@example.test');

        DB::table('user_roles')->insert([
            'user_id' => $user->id,
            'role_id' => 3,
            'status' => UserRole::STATUS_DISABLED,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $this->artisan('roles:repair-state')
            ->assertExitCode(0);

        $this->assertDatabaseHas('user_roles', [
            'user_id' => $user->id,
            'role_id' => 3,
            'status' => UserRole::STATUS_DISABLED,
        ]);
    }

    private function createUser(int $roleId, string $email): User
    {
        DB::table('roles')->updateOrInsert(['id' => 2], ['role' => 'Restaurant', 'created_at' => now(), 'updated_at' => now()]);
        DB::table('roles')->updateOrInsert(['id' => 3], ['role' => 'Foodie', 'created_at' => now(), 'updated_at' => now()]);

        return User::query()->create([
            'first_name' => 'Test',
            'last_name' => 'User',
            'email' => $email,
            'password' => Hash::make('password123'),
            'role_id' => $roleId,
            'phone' => '5555555555',
            'address' => 'Test Street',
            'email_verified' => 1,
        ]);
    }
}
