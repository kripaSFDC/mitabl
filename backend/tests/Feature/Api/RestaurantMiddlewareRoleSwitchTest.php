<?php

namespace Tests\Feature\Api;

use App\Models\Role;
use App\Models\User;
use App\Models\UserRole;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class RestaurantMiddlewareRoleSwitchTest extends TestCase
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

    public function test_restaurant_routes_allow_foodie_with_onboarding_cook_membership_to_create_kitchen(): void
    {
        $user = User::factory()->create(['role_id' => 3]);
        UserRole::query()->create(['user_id' => $user->id, 'role_id' => 2, 'status' => UserRole::STATUS_ONBOARDING]);
        UserRole::query()->create(['user_id' => $user->id, 'role_id' => 3, 'status' => UserRole::STATUS_ACTIVE]);

        $this->actingAs($user, 'api')
            ->postJson('/api/v2/mikitchn/store', [])
            ->assertStatus(422)
            ->assertJsonPath('isError', 'The name field is required.');

        $this->assertSame(2, (int) $user->fresh()->role_id);
    }

    public function test_restaurant_routes_allow_foodie_with_onboarding_cook_membership_to_update_kitchen(): void
    {
        $user = User::factory()->create(['role_id' => 3]);
        UserRole::query()->create(['user_id' => $user->id, 'role_id' => 2, 'status' => UserRole::STATUS_ONBOARDING]);
        UserRole::query()->create(['user_id' => $user->id, 'role_id' => 3, 'status' => UserRole::STATUS_ACTIVE]);

        $this->actingAs($user, 'api')
            ->postJson('/api/v2/mikitchn/editkitchen', [])
            ->assertStatus(404)
            ->assertJsonPath('isError', 'Kitchen not found for this user.');
    }

    public function test_restaurant_routes_block_onboarding_cook_membership_from_non_onboarding_endpoints(): void
    {
        $user = User::factory()->create(['role_id' => 3]);
        UserRole::query()->create(['user_id' => $user->id, 'role_id' => 2, 'status' => UserRole::STATUS_ONBOARDING]);

        $this->actingAs($user, 'api')
            ->getJson('/api/v2/getdashboarddata')
            ->assertStatus(403)
            ->assertJsonPath('isError', 'Complete your kitchen profile first. Create your kitchen before managing restaurant operations.');
    }


    public function test_restaurant_food_routes_allow_onboarding_cook_and_return_kitchen_profile_guidance(): void
    {
        $user = User::factory()->create(['role_id' => 3]);
        UserRole::query()->create(['user_id' => $user->id, 'role_id' => 2, 'status' => UserRole::STATUS_ONBOARDING]);
        UserRole::query()->create(['user_id' => $user->id, 'role_id' => 3, 'status' => UserRole::STATUS_ACTIVE]);

        $this->actingAs($user, 'api')
            ->postJson('/api/v2/food/add', [])
            ->assertStatus(422)
            ->assertJsonPath('isError', 'Kitchen profile is required before managing menu items.');
    }

    public function test_restaurant_routes_block_foodie_without_cook_membership(): void
    {
        $user = User::factory()->create(['role_id' => 3]);
        UserRole::query()->create(['user_id' => $user->id, 'role_id' => 3, 'status' => UserRole::STATUS_ACTIVE]);

        $this->actingAs($user, 'api')
            ->postJson('/api/v2/mikitchn/store', [])
            ->assertStatus(403)
            ->assertJsonPath('isError', 'Your account is unauthorized for this request. Login with Restaurant account.');
    }
}
