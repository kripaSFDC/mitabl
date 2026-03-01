<x-filament-panels::page>
    <x-filament::section class="mb-4">
        <x-slot name="heading">Integration monitoring guide</x-slot>
        <x-slot name="description">
            Review failed outbound events first, then validate retry counts and response snapshots. Use this as the
            primary page for third-party delivery troubleshooting.
        </x-slot>
    </x-filament::section>

    <div class="mb-4">
        <x-filament::button wire:click="refresh" color="info">
            Refresh
        </x-filament::button>
    </div>

    <x-filament::section>
        <x-slot name="heading">Outbound Integration Logs</x-slot>
        <x-slot name="description">Webhook/API outbound events with response snapshots and retry attempts.</x-slot>

        <div class="overflow-x-auto">
            <table class="w-full divide-y divide-gray-200 text-sm dark:divide-gray-700">
                <thead>
                    <tr class="text-left">
                        <th class="px-3 py-2">ID</th>
                        <th class="px-3 py-2">Channel</th>
                        <th class="px-3 py-2">Recipient</th>
                        <th class="px-3 py-2">Status</th>
                        <th class="px-3 py-2">Response</th>
                        <th class="px-3 py-2">Retries</th>
                        <th class="px-3 py-2">Error snapshot</th>
                        <th class="px-3 py-2">Created</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-gray-100 dark:divide-gray-800">
                    @forelse ($logs as $log)
                        <tr>
                            <td class="px-3 py-2">{{ $log['id'] }}</td>
                            <td class="px-3 py-2">{{ $log['channel'] }}</td>
                            <td class="px-3 py-2">{{ $log['recipient'] }}</td>
                            <td class="px-3 py-2">{{ $log['status'] }}</td>
                            <td class="px-3 py-2">{{ $log['response_status'] ?? '-' }}</td>
                            <td class="px-3 py-2">{{ $log['retry_attempts'] }}</td>
                            <td class="px-3 py-2">{{ str($log['error_body'])->limit(150) }}</td>
                            <td class="px-3 py-2">{{ $log['created_at'] }}</td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="8" class="px-3 py-4 text-center text-gray-600 dark:text-gray-300">
                                No integration logs available.
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </x-filament::section>
</x-filament-panels::page>
