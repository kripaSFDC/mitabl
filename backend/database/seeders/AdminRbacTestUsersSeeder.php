<?php

namespace Database\Seeders;

use App\Models\AdminUser;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;

class AdminRbacTestUsersSeeder extends Seeder
{
    public function run(): void
    {
        if (! $this->shouldRunSeeder()) {
            return;
        }

        $password = $this->resolvePassword();
        if ($password === null) {
            return;
        }

        $overrideExisting = false;
        $emailDomain = 'example.test';

        $usersByRole = [
            'super_admin' => 'Platform Super Admin',
            'platform_admin' => 'Platform Admin',
            'operations' => 'CRM Operations Admin',
            'customer_service' => 'CRM Customer Service Admin',
            'finance_readonly' => 'CRM Finance Readonly Admin',
        ];

        foreach ($usersByRole as $role => $name) {
            $email = sprintf('%s@%s', str_replace('_', '.', $role), $emailDomain);

            $admin = AdminUser::firstOrNew(['email' => $email]);
            $isNew = ! $admin->exists;

            if ($isNew || $overrideExisting) {
                $admin->name = $name;
                $admin->is_active = true;
                $admin->password = Hash::make($password);
                $admin->save();
            }

            if (! $isNew && ! $overrideExisting) {
                Log::info('AdminRbacTestUsersSeeder skipped existing user.', ['email' => $email, 'role' => $role]);
            }

            if (! $admin->hasRole($role)) {
                $admin->assignRole($role);
            }
        }
    }

    private function shouldRunSeeder(): bool
    {
        if (app()->environment(['local', 'testing'])) {
            return true;
        }

        Log::info('AdminRbacTestUsersSeeder skipped outside local/testing environments.');

        return false;
    }

    private function resolvePassword(): ?string
    {
        if (app()->environment(['local', 'testing'])) {
            return 'password';
        }

        Log::warning('AdminRbacTestUsersSeeder skipped outside local/testing environments.');

        return null;
    }
}
