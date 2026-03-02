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
        $email = 'admin@example.com';
        $name = 'Platform Admin';
        $password = 'password';

        if (app()->environment('production')) {
            $email = (string) env('ADMIN_BOOTSTRAP_EMAIL', '');
            $name = (string) env('ADMIN_BOOTSTRAP_NAME', 'Platform Admin');
            $password = (string) env('ADMIN_BOOTSTRAP_PASSWORD', '');

            if ($email === '' || $password === '') {
                Log::info('AdminUserSeeder skipped in production: missing ADMIN_BOOTSTRAP_EMAIL or ADMIN_BOOTSTRAP_PASSWORD.');
                return;
            }
        } elseif (! app()->environment(['local', 'testing'])) {
            Log::info('AdminUserSeeder skipped outside local/testing/production environments.');
            return;
        }

        if (! filter_var($email, FILTER_VALIDATE_EMAIL)) {
            Log::warning('AdminUserSeeder skipped: default email is invalid.', ['email' => $email]);
            return;
        }

        if (app()->environment('production') && ! $this->isStrongPassword($password)) {
            throw new \RuntimeException('Refusing to seed admin user with weak ADMIN_BOOTSTRAP_PASSWORD in production.');
        }

        $admin = AdminUser::firstOrNew(['email' => $email]);
        $admin->name = $name !== '' ? $name : 'Platform Admin';
        $admin->is_active = true;

        if (! $admin->exists) {
            $admin->password = Hash::make($password);
        }

        $admin->save();

        if (! $admin->hasRole('super_admin')) {
            $admin->assignRole('super_admin');
        }
    }

    private function isStrongPassword(string $password): bool
    {
        return strlen($password) >= 12
            && preg_match('/[A-Z]/', $password) === 1
            && preg_match('/[a-z]/', $password) === 1
            && preg_match('/[0-9]/', $password) === 1;
    }
}
