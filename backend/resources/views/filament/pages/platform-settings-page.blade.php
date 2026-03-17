<x-filament-panels::page>

<div class="mb-6 rounded-xl border border-blue-200 bg-blue-50 px-5 py-4 dark:border-blue-800 dark:bg-blue-950/30">
    <div class="flex gap-3">
        <x-filament::icon icon="heroicon-o-information-circle" class="mt-0.5 h-5 w-5 flex-shrink-0 text-blue-500" />
        <div class="space-y-1 text-sm text-blue-700 dark:text-blue-300">
            <p class="font-semibold">How to use this page</p>
            <p>Group settings by domain (auth, payments, queue, integrations) and document every change reason for auditability.
               High-risk keys follow a <strong>validate -&gt; approve/activate</strong> workflow requiring a second admin.</p>
        </div>
    </div>
</div>

<div class="mb-6 overflow-hidden rounded-xl border border-gray-200 bg-white shadow-sm dark:border-gray-700 dark:bg-gray-900">
    <div class="border-b border-gray-200 bg-gray-50 px-5 py-3 dark:border-gray-700 dark:bg-gray-800">
        <div class="flex items-center justify-between">
            <div>
                <h2 class="flex items-center gap-2 text-sm font-semibold text-gray-900 dark:text-white">
                    <x-filament::icon icon="heroicon-o-shield-exclamation" class="h-4 w-4 text-amber-500" />
                    High-Risk Change Approvals
                    @if (count($pendingApprovals) > 0)
                        <span class="inline-flex items-center rounded-full bg-amber-100 px-2 py-0.5 text-xs font-bold text-amber-700 dark:bg-amber-900/40 dark:text-amber-300">
                            {{ count($pendingApprovals) }} pending
                        </span>
                    @endif
                </h2>
                <p class="mt-0.5 text-xs text-gray-500 dark:text-gray-400">Validated requests require a second admin to approve and activate them in one step</p>
            </div>
        </div>
    </div>

    @if (count($pendingApprovals) > 0)
        <div class="overflow-x-auto">
            <table class="w-full text-sm" role="grid">
                <thead>
                    <tr class="border-b border-gray-100 bg-gray-50/80 text-left dark:border-gray-700 dark:bg-gray-800/60">
                        <th class="px-5 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500">#</th>
                        <th class="px-5 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500">Setting Key</th>
                        <th class="px-5 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500">Status</th>
                        <th class="px-5 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500">Change Reason</th>
                        <th class="px-5 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500">Validated At</th>
                        <th class="px-5 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500">Actions</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-gray-100 dark:divide-gray-800">
                    @foreach ($pendingApprovals as $request)
                        @php
                            $statusBadge = match ($request['status']) {
                                'pending' => 'bg-gray-100 text-gray-600 dark:bg-gray-700 dark:text-gray-300',
                                'validated' => 'bg-blue-100 text-blue-700 dark:bg-blue-900/40 dark:text-blue-300',
                                'approved' => 'bg-amber-100 text-amber-700 dark:bg-amber-900/40 dark:text-amber-300',
                                'activated' => 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/40 dark:text-emerald-300',
                                default => 'bg-gray-100 text-gray-600 dark:bg-gray-700 dark:text-gray-300',
                            };
                        @endphp
                        <tr class="bg-white transition-colors hover:bg-gray-50/80 dark:bg-gray-900 dark:hover:bg-gray-800/50">
                            <td class="px-5 py-3 font-mono text-xs text-gray-400">{{ $request['id'] }}</td>
                            <td class="px-5 py-3">
                                <code class="rounded bg-gray-100 px-1.5 py-0.5 text-xs font-mono text-gray-700 dark:bg-gray-800 dark:text-gray-300">{{ $request['setting_key'] }}</code>
                            </td>
                            <td class="px-5 py-3">
                                <span class="inline-flex rounded-full px-2.5 py-0.5 text-[11px] font-bold uppercase {{ $statusBadge }}">
                                    {{ $request['status'] }}
                                </span>
                            </td>
                            <td class="max-w-xs px-5 py-3 text-gray-600 dark:text-gray-300">
                                <span title="{{ $request['reason'] }}">{{ str($request['reason'])->limit(80) }}</span>
                            </td>
                            <td class="whitespace-nowrap px-5 py-3 text-xs text-gray-500 dark:text-gray-400">
                                {{ $request['validated_at'] ?? '-' }}
                            </td>
                            <td class="px-5 py-3">
                                <div class="flex items-center gap-2">
                                    @if ($request['status'] === 'validated')
                                        <x-filament::button
                                            size="xs"
                                            color="warning"
                                            wire:click="approveRequest({{ $request['id'] }})"
                                            icon="heroicon-o-check"
                                        >
                                            Approve / Activate
                                        </x-filament::button>
                                    @endif
                                    @if ($request['status'] === 'approved')
                                        <x-filament::button
                                            size="xs"
                                            color="success"
                                            wire:click="activateRequest({{ $request['id'] }})"
                                            icon="heroicon-o-bolt"
                                        >
                                            Activate
                                        </x-filament::button>
                                    @endif
                                    @if (! in_array($request['status'], ['validated', 'approved']))
                                        <span class="text-xs italic text-gray-400 dark:text-gray-500">No actions</span>
                                    @endif
                                </div>
                            </td>
                        </tr>
                    @endforeach
                </tbody>
            </table>
        </div>
    @else
        <div class="flex flex-col items-center justify-center py-10">
            <x-filament::icon icon="heroicon-o-check-circle" class="mb-2 h-8 w-8 text-emerald-400" />
            <p class="text-sm text-gray-500 dark:text-gray-400">No pending high-risk approvals</p>
        </div>
    @endif
</div>

<div class="overflow-hidden rounded-xl border border-gray-200 bg-white shadow-sm dark:border-gray-700 dark:bg-gray-900">
    <div class="border-b border-gray-200 bg-gray-50 px-5 py-3 dark:border-gray-700 dark:bg-gray-800">
        <h2 class="flex items-center gap-2 text-sm font-semibold text-gray-900 dark:text-white">
            <x-filament::icon icon="heroicon-o-cog-6-tooth" class="h-4 w-4 text-gray-500" />
            Runtime Configuration
        </h2>
        <p class="mt-0.5 text-xs text-gray-500 dark:text-gray-400">
            Manage runtime toggles and operational settings. Changes to high-risk keys require a change reason and admin password.
        </p>
    </div>

    <div class="px-5 py-5">
        <form wire:submit="save">
            {{ $this->form }}

            <div class="mt-6 flex items-center justify-between rounded-lg border border-gray-200 bg-gray-50 px-5 py-4 dark:border-gray-700 dark:bg-gray-800">
                <p class="text-xs text-gray-500 dark:text-gray-400">
                    High-risk keys (auth, payment, queue, cache, incident) require a change reason and admin password.
                </p>
                <x-filament::button
                    type="submit"
                    icon="heroicon-o-check"
                    color="primary"
                >
                    Save Settings
                </x-filament::button>
            </div>
        </form>
    </div>
</div>

</x-filament-panels::page>
