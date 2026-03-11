<?php

namespace Tests\Feature\Api;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class MikitchnCertificateContractTest extends TestCase
{
    use RefreshDatabase;

    public function test_edit_kitchen_does_not_create_blank_certificate_records(): void
    {
        DB::table('roles')->insert([
            ['id' => 2, 'role' => 'Restaurant', 'created_at' => now(), 'updated_at' => now()],
            ['id' => 3, 'role' => 'Foodie', 'created_at' => now(), 'updated_at' => now()],
        ]);

        $user = User::query()->create([
            'first_name' => 'Cook',
            'last_name' => 'Profile',
            'email' => 'cook-certificate@example.test',
            'password' => Hash::make('password123'),
            'role_id' => 2,
            'phone' => '1234567890',
            'address' => 'Kitchen Street',
            'email_verified' => 1,
        ]);

        $kitchenId = DB::table('mikitchns')->insertGetId([
            'user_id' => $user->id,
            'name' => 'Existing Kitchen',
            'address' => 'Kitchen Street',
            'no_of_seats' => 10,
            'timings' => '{"days":[{"day":"Mon","isOn":true,"timing":{"start_time":"09:00","end_time":"17:00"}}]}',
            'phone' => '1234567890',
            'dine_in' => 1,
            'take_away' => 0,
            'description' => 'Existing profile',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $token = auth()->login($user);

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->post('/api/v2/mikitchn/editkitchen', [
                'name' => 'Existing Kitchen',
                'address' => 'Kitchen Street',
                'no_of_seats' => 12,
                'timings' => '{"days":[{"day":"Mon","isOn":true,"timing":{"start_time":"09:00","end_time":"17:00"}}]}',
                'phone' => '1234567890',
                'dine_in' => 1,
                'take_away' => 0,
                'description' => 'Updated profile',
                'abn' => '',
                'certificate_no' => '',
            ]);

        $response->assertStatus(200);
        $this->assertDatabaseMissing('certificates', [
            'mikitchn_id' => $kitchenId,
        ]);
    }
}
