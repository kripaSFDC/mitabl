<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Mail;
use Tests\TestCase;

class MifoodieAdminCrudRegressionTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_model_allows_admin_directory_status_fields_to_persist(): void
    {
        Mail::fake();

        $user = User::query()->create([
            'role_id' => 3,
            'first_name' => 'Mi',
            'last_name' => 'Foodie',
            'email' => 'mifoodie@example.test',
            'password' => bcrypt('password123'),
            'phone' => '1234567890',
            'address' => 'Test address',
        ]);

        $user->fill([
            'email_verified' => true,
            'suspended' => true,
            'suspension_reason' => 'Admin review',
        ])->save();

        $user->refresh();

        $this->assertTrue((bool) $user->email_verified);
        $this->assertTrue((bool) $user->suspended);
        $this->assertSame('Admin review', $user->suspension_reason);
    }
}
