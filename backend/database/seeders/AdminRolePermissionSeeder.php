<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\Models\Role;
use Spatie\Permission\PermissionRegistrar;

class AdminRolePermissionSeeder extends Seeder
{
    public function run(): void
    {
        app(PermissionRegistrar::class)->forgetCachedPermissions();

        $permissions = [
            'dashboard.view',
            'certificates.view',
            'certificates.review',
            'users.view',
            'users.edit',
            'users.suspend',
            'kitchens.view',
            'kitchens.edit',
            'orders.view',
            'orders.override_status',
            'orders.refund',
            'support_tickets.view',
            'support_tickets.create',
            'support_tickets.assign',
            'support_tickets.respond',
            'support_tickets.resolve',
            'pre_registrations.view',
            'pre_registrations.edit',
            'promo_codes.view',
            'promo_codes.edit',
            'payments.view',
            'platform_settings.view',
            'platform_settings.edit',
            'policies.view',
            'policies.edit',
            'policy_changes.publish',
            'queue_ops.view',
            'queue_ops.manage',
            'health.view',
            'audit_logs.view',
            'iam.manage',
        ];

        foreach ($permissions as $permissionName) {
            Permission::firstOrCreate([
                'name' => $permissionName,
                'guard_name' => 'admin',
            ]);
        }

        $roleMap = [
            'super_admin' => $permissions,
            'platform_admin' => [
                'dashboard.view',
                'platform_settings.view',
                'platform_settings.edit',
                'policies.view',
                'policies.edit',
                'policy_changes.publish',
                'queue_ops.view',
                'queue_ops.manage',
                'health.view',
                'audit_logs.view',
            ],
            'operations' => [
                'dashboard.view',
                'certificates.view',
                'certificates.review',
                'users.view',
                'kitchens.view',
                'kitchens.edit',
                'orders.view',
                'pre_registrations.view',
                'pre_registrations.edit',
                'promo_codes.view',
                'promo_codes.edit',
                'support_tickets.view',
                'support_tickets.assign',
                'support_tickets.respond',
                'support_tickets.resolve',
            ],
            'customer_service' => [
                'dashboard.view',
                'users.view',
                'orders.view',
                'support_tickets.view',
                'support_tickets.create',
                'support_tickets.assign',
                'support_tickets.respond',
                'support_tickets.resolve',
                'pre_registrations.view',
                'pre_registrations.edit',
            ],
            'finance_readonly' => [
                'dashboard.view',
                'payments.view',
                'orders.view',
                'audit_logs.view',
            ],
        ];

        foreach ($roleMap as $roleName => $assignedPermissions) {
            $role = Role::firstOrCreate([
                'name' => $roleName,
                'guard_name' => 'admin',
            ]);

            $role->syncPermissions($assignedPermissions);
        }
    }
}
