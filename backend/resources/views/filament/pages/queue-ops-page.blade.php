<x-filament-panels::page>

@php
    $failedCount   = (int) ($queueMetrics['failed_jobs']   ?? 0);
    $pendingCount  = (int) ($queueMetrics['pending_jobs']  ?? 0);
    $poisonCount   = (int) ($queueMetrics['poison_jobs']   ?? 0);
    $dlRisk        = (bool) ($queueMetrics['dead_letter_risk'] ?? false);
    $oldestAge     = $queueMetrics['oldest_pending_age_minutes'] ?? null;
@endphp

{{-- ── Guidance callout --}}
<div class="mb-5 rounded-xl border border-amber-200 bg-amber-50 px-5 py-3 dark:border-amber-800 dark:bg-amber-950/30">
    <div class="flex gap-3 text-sm text-amber-700 dark:text-amber-300">
        <x-filament::icon icon="heroicon-o-exclamation-triangle" class="h-5 w-5 flex-shrink-0 mt-0.5" />
        <div>
            <strong>Operations guide:</strong>
            Retry single jobs first, then use bulk retry only after validating root cause.
            Discard only known poison payloads that cannot be safely replayed.
        </div>
    </div>
</div>

{{-- ── Top action bar --}}
<div class="mb-5 flex items-center justify-between">
    <h2 class="text-sm font-semibold text-gray-700 dark:text-gray-200">Queue Health &amp; Failed Jobs</h2>
    <div class="flex items-center gap-2">
        <x-filament::button
            wire:click="refresh"
            color="gray"
            size="sm"
            icon="heroicon-o-arrow-path"
        >
            Refresh
        </x-filament::button>
        @if ($canManageQueue)
            <x-filament::button
                wire:click="retryAll"
                color="warning"
                size="sm"
                icon="heroicon-o-arrow-uturn-left"
            >
                Retry All Failed
            </x-filament::button>
        @endif
    </div>
</div>

{{-- ── Metric tiles ──────────────────────────────────────────────────── --}}
<div class="mb-6 grid grid-cols-2 gap-4 sm:grid-cols-3 xl:grid-cols-5">
    @php
        $metrics = [
            [
                'label'  => 'Queue Depth',
                'value'  => $pendingCount,
                'sub'    => 'pending jobs',
                'color'  => $pendingCount > 100 ? 'red' : ($pendingCount > 20 ? 'yellow' : 'emerald'),
            ],
            [
                'label'  => 'Failed Jobs',
                'value'  => $failedCount,
                'sub'    => 'need attention',
                'color'  => $failedCount > 0 ? 'red' : 'emerald',
            ],
            [
                'label'  => 'Oldest Pending',
                'value'  => $oldestAge !== null ? $oldestAge . ' min' : '—',
                'sub'    => 'age of oldest job',
                'color'  => is_numeric($oldestAge) && $oldestAge > 60 ? 'red' : ($oldestAge !== null ? 'yellow' : 'gray'),
            ],
            [
                'label'  => 'Poison Retries',
                'value'  => $poisonCount,
                'sub'    => 'repeat failures',
                'color'  => $poisonCount > 0 ? 'orange' : 'emerald',
            ],
            [
                'label'  => 'Dead-letter Risk',
                'value'  => $dlRisk ? 'HIGH' : 'Normal',
                'sub'    => $dlRisk ? 'action required' : 'within tolerance',
                'color'  => $dlRisk ? 'red' : 'emerald',
            ],
        ];

        $metricColors = [
            'emerald' => ['tile' => 'border-emerald-200 bg-emerald-50 dark:border-emerald-800 dark:bg-emerald-950/30',
                          'val'  => 'text-emerald-700 dark:text-emerald-300'],
            'yellow'  => ['tile' => 'border-yellow-200 bg-yellow-50 dark:border-yellow-800 dark:bg-yellow-950/30',
                          'val'  => 'text-yellow-700 dark:text-yellow-300'],
            'orange'  => ['tile' => 'border-orange-200 bg-orange-50 dark:border-orange-800 dark:bg-orange-950/30',
                          'val'  => 'text-orange-700 dark:text-orange-300'],
            'red'     => ['tile' => 'border-red-200 bg-red-50 dark:border-red-800 dark:bg-red-950/30',
                          'val'  => 'text-red-700 dark:text-red-300'],
            'gray'    => ['tile' => 'border-gray-200 bg-gray-50 dark:border-gray-700 dark:bg-gray-800/40',
                          'val'  => 'text-gray-600 dark:text-gray-300'],
        ];
    @endphp

    @foreach ($metrics as $m)
        @php $mc = $metricColors[$m['color']]; @endphp
        <div class="rounded-xl border px-5 py-4 shadow-sm {{ $mc['tile'] }}">
            <p class="text-[10px] font-semibold uppercase tracking-wide text-gray-500 dark:text-gray-400">{{ $m['label'] }}</p>
            <p class="mt-1 text-2xl font-bold truncate {{ $mc['val'] }}">{{ $m['value'] }}</p>
            <p class="mt-0.5 text-[10px] text-gray-400">{{ $m['sub'] }}</p>
        </div>
    @endforeach
</div>

{{-- ── Failed jobs table ─────────────────────────────────────────────── --}}
<div class="overflow-hidden rounded-xl border border-gray-200 bg-white shadow-sm dark:border-gray-700 dark:bg-gray-900">
    <div class="border-b border-gray-200 bg-gray-50 px-5 py-3 dark:border-gray-700 dark:bg-gray-800">
        <h2 class="flex items-center gap-2 text-sm font-semibold text-gray-900 dark:text-white">
            <x-filament::icon icon="heroicon-o-x-circle" class="h-4 w-4 {{ $failedCount > 0 ? 'text-red-500' : 'text-gray-400' }}" />
            Failed Jobs
            @if ($failedCount > 0)
                <span class="inline-flex items-center rounded-full bg-red-100 px-2 py-0.5 text-xs font-bold text-red-700 dark:bg-red-900/40 dark:text-red-300">
                    {{ $failedCount }}
                </span>
            @endif
        </h2>
        <p class="mt-0.5 text-xs text-gray-500 dark:text-gray-400">Latest 100 failed queue jobs · Retry, requeue, or discard</p>
    </div>

    @if (count($failedJobs) > 0)
        <div class="overflow-x-auto">
            <table class="w-full text-sm" role="grid">
                <thead>
                    <tr class="border-b border-gray-100 bg-gray-50/80 dark:border-gray-700 dark:bg-gray-800/60 text-left">
                        <th class="px-5 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500">ID</th>
                        <th class="px-5 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500">Queue</th>
                        <th class="px-5 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500">Connection</th>
                        <th class="px-5 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500">Attempts</th>
                        <th class="px-5 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500">Failed At</th>
                        <th class="px-5 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500">Exception</th>
                        @if ($canManageQueue)
                            <th class="px-5 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500">Actions</th>
                        @endif
                    </tr>
                </thead>
                <tbody class="divide-y divide-gray-100 dark:divide-gray-800">
                    @foreach ($failedJobs as $job)
                        @php
                            $attemptsColor = (int) ($job['attempts'] ?? 0) >= 3
                                ? 'text-red-600 font-bold dark:text-red-400'
                                : 'text-gray-700 dark:text-gray-300';
                        @endphp
                        <tr class="bg-white hover:bg-gray-50/80 dark:bg-gray-900 dark:hover:bg-gray-800/50 transition-colors">
                            <td class="px-5 py-3 font-mono text-xs text-gray-500">{{ $job['id'] }}</td>
                            <td class="px-5 py-3">
                                <span class="inline-flex rounded-full bg-gray-100 px-2 py-0.5 text-xs font-medium text-gray-700 dark:bg-gray-800 dark:text-gray-300">
                                    {{ $job['queue'] }}
                                </span>
                            </td>
                            <td class="px-5 py-3 text-xs text-gray-500">{{ $job['connection'] }}</td>
                            <td class="px-5 py-3 text-xs {{ $attemptsColor }}">{{ $job['attempts'] }}</td>
                            <td class="px-5 py-3 text-xs text-gray-500 whitespace-nowrap">{{ $job['failed_at'] }}</td>
                            <td class="px-5 py-3 max-w-xs">
                                <details class="cursor-pointer">
                                    <summary class="text-xs text-gray-600 dark:text-gray-300 truncate w-72">
                                        {{ str($job['exception'])->limit(80) }}
                                    </summary>
                                    <pre class="mt-2 max-h-32 overflow-y-auto rounded bg-gray-100 p-2 text-[10px] text-gray-700 dark:bg-gray-800 dark:text-gray-300 whitespace-pre-wrap break-all">{{ $job['exception'] }}</pre>
                                </details>
                            </td>
                            @if ($canManageQueue)
                                <td class="px-5 py-3">
                                    <div class="flex items-center gap-1.5">
                                        <x-filament::button size="xs" color="warning" wire:click="retryJob({{ $job['id'] }})" icon="heroicon-o-arrow-uturn-left">
                                            Retry
                                        </x-filament::button>
                                        <x-filament::button size="xs" color="info" wire:click="requeueJob({{ $job['id'] }})" icon="heroicon-o-queue-list">
                                            Requeue
                                        </x-filament::button>
                                        <x-filament::button size="xs" color="danger" wire:click="discardJob({{ $job['id'] }})" icon="heroicon-o-trash">
                                            Discard
                                        </x-filament::button>
                                    </div>
                                </td>
                            @endif
                        </tr>
                    @endforeach
                </tbody>
            </table>
        </div>
    @else
        <div class="flex flex-col items-center justify-center py-14">
            <x-filament::icon icon="heroicon-o-check-circle" class="h-10 w-10 text-emerald-400 mb-3" />
            <p class="text-sm font-medium text-gray-600 dark:text-gray-300">No failed jobs</p>
            <p class="mt-0.5 text-xs text-gray-400">Queue workers are healthy</p>
        </div>
    @endif

    @if (!$canManageQueue)
        <div class="border-t border-gray-100 bg-gray-50 px-5 py-2.5 dark:border-gray-700 dark:bg-gray-800/40">
            <p class="text-xs text-gray-400 dark:text-gray-500">
                View-only mode — you do not have permission to manage queue jobs.
            </p>
        </div>
    @endif
</div>

</x-filament-panels::page>
