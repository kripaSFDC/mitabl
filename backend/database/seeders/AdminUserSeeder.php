<?php

namespace Database\Seeders;

use App\Models\AdminUser;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;

class AdminUserSeeder extends Seeder
{
    public function run(): void
    {
        if (! app()->environment(['local', 'testing'])) {
            Log::info('AdminUserSeeder skipped outside local/testing environments.');

            return;
        }

        $email = 'admin@example.com';
        $name = 'Platform Admin';
        $password = 'password';

        if (! filter_var($email, FILTER_VALIDATE_EMAIL)) {
            Log::warning('AdminUserSeeder skipped: default email is invalid.', ['email' => $email]);
            return;
        }

        if (app()->environment('production') && in_array(strtolower($password), ['password', 'admin', '12345678'], true)) {
            throw new \RuntimeException('Refusing to seed admin user with a weak default password in production.');
        }

        $admin = AdminUser::firstOrNew(['email' => $email]);
        $admin->name = $name !== '' ? $name : 'Platform Admin';
        $admin->is_active = true;

        if (! $admin->exists || app()->environment(['local', 'testing'])) {
            $admin->password = Hash::make($password);
        }

        $admin->save();

        if (! $admin->hasRole('super_admin')) {
            $admin->assignRole('super_admin');
        }
    }
}
