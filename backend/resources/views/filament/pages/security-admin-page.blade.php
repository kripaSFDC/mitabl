<x-filament-panels::page>
    <x-filament::section class="mb-4">
        <x-slot name="heading">Security controls overview</x-slot>
        <x-slot name="description">
            Use this page for periodic access reviews. Dormant accounts should be deactivated or re-certified
            according to the IAM and secret-rotation runbooks.
        </x-slot>
    </x-filament::section>
    <div class="grid gap-4 md:grid-cols-2">
        <x-filament::section>
            <x-slot name="heading">
                Session Policy
            </x-slot>
            <div class="space-y-2 text-sm">
                <p><strong>Session lifetime (minutes):</strong> {{ $sessionPolicy['lifetime_minutes'] ?? 0 }}</p>
                <p><strong>Expire on close:</strong> {{ ($sessionPolicy['expire_on_close'] ?? false) ? 'Yes' : 'No' }}</p>
                <p><strong>Sensitive-action re-auth (minutes):</strong> {{ $sessionPolicy['step_up_reauth_minutes'] ?? 15 }}</p>
                <p><strong>Dormant threshold (days):</strong> {{ $sessionPolicy['dormant_threshold_days'] ?? 30 }}</p>
            </div>
        </x-filament::section>

        <x-filament::section>
            <x-slot name="heading">
                Access Review Snapshot
            </x-slot>
            <div class="space-y-2 text-sm">
                <p><strong>Total admins:</strong> {{ $accessReview['admins_total'] ?? 0 }}</p>
                <p><strong>Active admins:</strong> {{ $accessReview['admins_active'] ?? 0 }}</p>
                <p><strong>IAM manager candidates:</strong> {{ $accessReview['iam_manager_candidates'] ?? 0 }}</p>
                <p><strong>Dormant active admins:</strong> {{ $accessReview['dormant_active_admins'] ?? 0 }}</p>
                <p><strong>Defined admin roles:</strong> {{ $accessReview['defined_roles'] ?? 0 }}</p>
                <p>
                    <strong>Secret rotation runbook:</strong>
                    <code>{{ $accessReview['rotation_runbook'] ?? 'docs/secrets-management.md' }}</code>
                </p>
            </div>
        </x-filament::section>
    </div>

    <x-filament::section class="mt-4">
        <x-slot name="heading">
            Dormant Admins
        </x-slot>
        <x-slot name="description">
            Active admin identities with no login or stale login beyond threshold.
        </x-slot>

        <div class="overflow-x-auto">
            <table class="w-full divide-y divide-gray-200 text-sm dark:divide-gray-700">
                <thead>
                    <tr class="text-left">
                        <th class="px-3 py-2">ID</th>
                        <th class="px-3 py-2">Name</th>
                        <th class="px-3 py-2">Email</th>
                        <th class="px-3 py-2">Last Login</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-gray-100 dark:divide-gray-800">
                    @forelse ($dormantAdmins as $admin)
                        <tr>
                            <td class="px-3 py-2">{{ $admin['id'] }}</td>
                            <td class="px-3 py-2">{{ $admin['name'] }}</td>
                            <td class="px-3 py-2">{{ $admin['email'] }}</td>
                            <td class="px-3 py-2">{{ $admin['last_login_at'] ?? 'Never' }}</td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="4" class="px-3 py-4 text-center text-gray-600 dark:text-gray-300">
                                No dormant active admins found.
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </x-filament::section>
</x-filament-panels::page>
