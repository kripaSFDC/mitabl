<x-filament-panels::page>
    <x-filament::section class="mb-4">
        <x-slot name="heading">How to use this page</x-slot>
        <x-slot name="description">
            Group settings by domain (auth, payments, queue, integrations), document every risky change,
            and provide a reason for auditability. High-risk keys now follow validate → approve → activate.
        </x-slot>
    </x-filament::section>

    <x-filament::section class="mb-4">
        <x-slot name="heading">High-risk approval workflow</x-slot>
        <x-slot name="description">Validated requests require a second admin approval before activation.</x-slot>

        <div class="overflow-x-auto">
            <table class="w-full divide-y divide-gray-200 text-sm dark:divide-gray-700">
                <thead>
                    <tr class="text-left">
                        <th class="px-3 py-2">ID</th>
                        <th class="px-3 py-2">Setting key</th>
                        <th class="px-3 py-2">Status</th>
                        <th class="px-3 py-2">Reason</th>
                        <th class="px-3 py-2">Validated</th>
                        <th class="px-3 py-2">Actions</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-gray-100 dark:divide-gray-800">
                    @forelse ($pendingApprovals as $request)
                        <tr>
                            <td class="px-3 py-2">{{ $request['id'] }}</td>
                            <td class="px-3 py-2">{{ $request['setting_key'] }}</td>
                            <td class="px-3 py-2">{{ strtoupper($request['status']) }}</td>
                            <td class="px-3 py-2">{{ str($request['reason'])->limit(80) }}</td>
                            <td class="px-3 py-2">{{ $request['validated_at'] }}</td>
                            <td class="px-3 py-2">
                                <div class="flex gap-2">
                                    @if ($request['status'] === 'validated')
                                        <x-filament::button size="xs" color="warning" wire:click="approveRequest({{ $request['id'] }})">Approve</x-filament::button>
                                    @endif
                                    @if ($request['status'] === 'approved')
                                        <x-filament::button size="xs" color="success" wire:click="activateRequest({{ $request['id'] }})">Activate</x-filament::button>
                                    @endif
                                </div>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="6" class="px-3 py-3 text-center text-gray-500">No pending high-risk approvals.</td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </x-filament::section>

    <form wire:submit="save">
        {{ $this->form }}

        <div class="mt-6">
            <x-filament::button type="submit">
                Save settings
            </x-filament::button>
        </div>
    </form>
</x-filament-panels::page>
