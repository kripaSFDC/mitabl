<x-filament-panels::page>
    <div class="mb-4 flex flex-wrap gap-2">
        <x-filament::button wire:click="refresh" color="info">
            Refresh
        </x-filament::button>
        @if ($canManageQueue)
            <x-filament::button wire:click="retryAll" color="warning">
                Retry all
            </x-filament::button>
        @endif
    </div>

    <div class="mb-4 grid gap-3 md:grid-cols-5">
        <x-filament::section>
            <x-slot name="heading">Queue depth</x-slot>
            <p class="text-xl font-semibold">{{ $queueMetrics['pending_jobs'] ?? 0 }}</p>
        </x-filament::section>
        <x-filament::section>
            <x-slot name="heading">Failed jobs</x-slot>
            <p class="text-xl font-semibold">{{ $queueMetrics['failed_jobs'] ?? 0 }}</p>
        </x-filament::section>
        <x-filament::section>
            <x-slot name="heading">Oldest age (min)</x-slot>
            <p class="text-xl font-semibold">{{ $queueMetrics['oldest_pending_age_minutes'] ?? '-' }}</p>
        </x-filament::section>
        <x-filament::section>
            <x-slot name="heading">Poison retries</x-slot>
            <p class="text-xl font-semibold">{{ $queueMetrics['poison_jobs'] ?? 0 }}</p>
        </x-filament::section>
        <x-filament::section>
            <x-slot name="heading">Dead-letter risk</x-slot>
            <x-filament::badge :color="($queueMetrics['dead_letter_risk'] ?? false) ? 'danger' : 'success'">
                {{ ($queueMetrics['dead_letter_risk'] ?? false) ? 'High' : 'Normal' }}
            </x-filament::badge>
        </x-filament::section>
    </div>

    <x-filament::section>
        <x-slot name="heading">
            Failed Jobs (Latest 100)
        </x-slot>
        <x-slot name="description">
            Retry, requeue, or discard failed queue jobs.
        </x-slot>

        <div class="overflow-x-auto">
            <table class="w-full divide-y divide-gray-200 text-sm dark:divide-gray-700">
                <thead>
                    <tr class="text-left">
                        <th class="px-3 py-2">ID</th>
                        <th class="px-3 py-2">Connection</th>
                        <th class="px-3 py-2">Queue</th>
                        <th class="px-3 py-2">Attempts</th>
                        <th class="px-3 py-2">Failed At</th>
                        <th class="px-3 py-2">Exception</th>
                        <th class="px-3 py-2">Actions</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-gray-100 dark:divide-gray-800">
                    @forelse ($failedJobs as $job)
                        <tr>
                            <td class="px-3 py-2">{{ $job['id'] }}</td>
                            <td class="px-3 py-2">{{ $job['connection'] }}</td>
                            <td class="px-3 py-2">{{ $job['queue'] }}</td>
                            <td class="px-3 py-2">{{ $job['attempts'] }}</td>
                            <td class="px-3 py-2">{{ $job['failed_at'] }}</td>
                            <td class="px-3 py-2">{{ $job['exception'] }}</td>
                            <td class="px-3 py-2">
                                @if ($canManageQueue)
                                    <div class="flex gap-2">
                                        <x-filament::button size="xs" color="warning" wire:click="retryJob({{ $job['id'] }})">
                                            Retry
                                        </x-filament::button>
                                        <x-filament::button size="xs" color="info" wire:click="requeueJob({{ $job['id'] }})">
                                            Requeue
                                        </x-filament::button>
                                        <x-filament::button size="xs" color="danger" wire:click="discardJob({{ $job['id'] }})">
                                            Discard
                                        </x-filament::button>
                                    </div>
                                @else
                                    <span class="text-xs text-gray-500 dark:text-gray-400">View only</span>
                                @endif
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="7" class="px-3 py-4 text-center text-gray-600 dark:text-gray-300">
                                No failed jobs found.
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </x-filament::section>
</x-filament-panels::page>
