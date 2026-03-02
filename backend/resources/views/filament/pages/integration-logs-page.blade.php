<x-filament-panels::page>

@php
    $statusBadge = fn(string $s): string => match (strtolower($s)) {
        'sent', 'delivered', 'success' => 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/40 dark:text-emerald-300',
        'failed', 'error'              => 'bg-red-100 text-red-700 dark:bg-red-900/40 dark:text-red-300',
        'queued', 'pending'            => 'bg-blue-100 text-blue-700 dark:bg-blue-900/40 dark:text-blue-300',
        'retrying'                     => 'bg-amber-100 text-amber-700 dark:bg-amber-900/40 dark:text-amber-300',
        default                        => 'bg-gray-100 text-gray-600 dark:bg-gray-700 dark:text-gray-300',
    };

    $failedLogs = collect($logs)->filter(fn($l) => in_array(strtolower($l['status']), ['failed', 'error']))->count();
@endphp

{{-- ── Header ──────────────────────────────────────────────────────────── --}}
<div class="mb-5 flex items-center justify-between">
    <div>
        <p class="text-sm text-gray-500 dark:text-gray-400">
            Outbound webhook and API events with response snapshots and retry history.
        </p>
        @if ($failedLogs > 0)
            <span class="mt-1 inline-flex items-center gap-1 rounded-full bg-red-100 px-2.5 py-0.5 text-xs font-bold text-red-700 dark:bg-red-900/40 dark:text-red-300">
                ⚠ {{ $failedLogs }} failed event{{ $failedLogs !== 1 ? 's' : '' }} requiring attention
            </span>
        @endif
    </div>
    <x-filament::button
        wire:click="refresh"
        color="gray"
        size="sm"
        icon="heroicon-o-arrow-path"
    >
        Refresh
    </x-filament::button>
</div>

{{-- ── Summary tiles ────────────────────────────────────────────────────── --}}
@php
    $statuses = collect($logs)->groupBy(fn($l) => strtolower($l['status']));
    $summaryTiles = [
        ['label' => 'Total',   'count' => count($logs),    'color' => 'gray'],
        ['label' => 'Failed',  'count' => collect($logs)->filter(fn($l) => in_array($l['status'], ['failed','error']))->count(),   'color' => 'red'],
        ['label' => 'Sent',    'count' => collect($logs)->filter(fn($l) => in_array($l['status'], ['sent','delivered','success']))->count(), 'color' => 'emerald'],
        ['label' => 'Pending', 'count' => collect($logs)->filter(fn($l) => in_array($l['status'], ['queued','pending','retrying']))->count(), 'color' => 'blue'],
    ];
    $summaryColors = [
        'gray'    => ['tile' => 'bg-gray-50 border-gray-200 dark:bg-gray-800/40 dark:border-gray-700', 'val' => 'text-gray-700 dark:text-gray-200'],
        'red'     => ['tile' => 'bg-red-50 border-red-200 dark:bg-red-950/30 dark:border-red-800', 'val' => 'text-red-700 dark:text-red-300'],
        'emerald' => ['tile' => 'bg-emerald-50 border-emerald-200 dark:bg-emerald-950/30 dark:border-emerald-800', 'val' => 'text-emerald-700 dark:text-emerald-300'],
        'blue'    => ['tile' => 'bg-blue-50 border-blue-200 dark:bg-blue-950/30 dark:border-blue-800', 'val' => 'text-blue-700 dark:text-blue-300'],
    ];
@endphp
<div class="mb-6 grid grid-cols-2 gap-3 sm:grid-cols-4">
    @foreach ($summaryTiles as $t)
        @php $sc = $summaryColors[$t['color']]; @endphp
        <div class="rounded-xl border px-5 py-4 shadow-sm {{ $sc['tile'] }}">
            <p class="text-[10px] font-semibold uppercase tracking-wide text-gray-500 dark:text-gray-400">{{ $t['label'] }}</p>
            <p class="mt-1 text-2xl font-bold {{ $sc['val'] }}">{{ $t['count'] }}</p>
        </div>
    @endforeach
</div>

{{-- ── Logs table ───────────────────────────────────────────────────────── --}}
<div class="overflow-hidden rounded-xl border border-gray-200 bg-white shadow-sm dark:border-gray-700 dark:bg-gray-900">
    <div class="border-b border-gray-200 bg-gray-50 px-5 py-3 dark:border-gray-700 dark:bg-gray-800">
        <h2 class="text-sm font-semibold text-gray-900 dark:text-white">Outbound Integration Events</h2>
        <p class="mt-0.5 text-xs text-gray-500 dark:text-gray-400">Latest 200 events — replay available for failed support channel logs</p>
    </div>

    @if (count($logs) > 0)
        <div class="overflow-x-auto">
            <table class="w-full text-sm" role="grid">
                <thead>
                    <tr class="border-b border-gray-100 bg-gray-50/80 dark:border-gray-700 dark:bg-gray-800/60 text-left">
                        <th class="px-5 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500">ID</th>
                        <th class="px-5 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500">Channel</th>
                        <th class="px-5 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500">Template</th>
                        <th class="px-5 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500">Recipient</th>
                        <th class="px-5 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500">Status</th>
                        <th class="px-5 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500">HTTP</th>
                        <th class="px-5 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500">Retries</th>
                        <th class="px-5 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500">Error</th>
                        <th class="px-5 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500">Created</th>
                        @if ($canManage)
                            <th class="px-5 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500">Actions</th>
                        @endif
                    </tr>
                </thead>
                <tbody class="divide-y divide-gray-100 dark:divide-gray-800">
                    @foreach ($logs as $log)
                        @php
                            $isFailed = in_array(strtolower($log['status']), ['failed', 'error']);
                            $rowHighlight = $isFailed
                                ? 'bg-red-50/40 dark:bg-red-950/10 hover:bg-red-50 dark:hover:bg-red-950/20'
                                : 'bg-white dark:bg-gray-900 hover:bg-gray-50/80 dark:hover:bg-gray-800/50';
                        @endphp
                        <tr class="{{ $rowHighlight }} transition-colors">
                            <td class="px-5 py-3 font-mono text-xs text-gray-400">{{ $log['id'] }}</td>
                            <td class="px-5 py-3">
                                <span class="inline-flex rounded-full bg-gray-100 px-2 py-0.5 text-xs font-medium text-gray-700 dark:bg-gray-800 dark:text-gray-200">
                                    {{ $log['channel'] }}
                                </span>
                            </td>
                            <td class="px-5 py-3 text-xs text-gray-500 dark:text-gray-400 max-w-[120px] truncate">
                                <span title="{{ $log['template'] ?? '—' }}">{{ $log['template'] ?? '—' }}</span>
                            </td>
                            <td class="px-5 py-3 text-xs text-gray-600 dark:text-gray-300 max-w-[150px] truncate">
                                <span title="{{ $log['recipient'] }}">{{ $log['recipient'] }}</span>
                            </td>
                            <td class="px-5 py-3">
                                <span class="inline-flex rounded-full px-2.5 py-0.5 text-[11px] font-bold uppercase {{ $statusBadge($log['status']) }}">
                                    {{ $log['status'] }}
                                </span>
                            </td>
                            <td class="px-5 py-3 text-xs font-mono {{ ($log['response_status'] ?? 0) >= 400 ? 'text-red-600 dark:text-red-400 font-bold' : 'text-gray-500 dark:text-gray-400' }}">
                                {{ $log['response_status'] ?? '—' }}
                            </td>
                            <td class="px-5 py-3 text-xs {{ (int)($log['retry_attempts'] ?? 0) > 0 ? 'text-amber-600 dark:text-amber-400 font-semibold' : 'text-gray-400' }}">
                                {{ $log['retry_attempts'] ?? 0 }}
                            </td>
                            <td class="px-5 py-3 max-w-[200px]">
                                @if (!empty($log['error_body']))
                                    <details class="cursor-pointer">
                                        <summary class="text-xs text-red-600 dark:text-red-400 truncate w-48">
                                            {{ str($log['error_body'])->limit(60) }}
                                        </summary>
                                        <pre class="mt-2 max-h-24 overflow-y-auto rounded bg-red-50 p-2 text-[10px] text-red-700 dark:bg-red-950/30 dark:text-red-300 whitespace-pre-wrap break-all">{{ $log['error_body'] }}</pre>
                                    </details>
                                @else
                                    <span class="text-xs text-gray-300 dark:text-gray-600">—</span>
                                @endif
                            </td>
                            <td class="px-5 py-3 text-xs text-gray-500 dark:text-gray-400 whitespace-nowrap">{{ $log['created_at'] }}</td>
                            @if ($canManage)
                                <td class="px-5 py-3">
                                    @if ($isFailed)
                                        <x-filament::button
                                            size="xs"
                                            color="warning"
                                            wire:click="replayFailed({{ $log['id'] }})"
                                            icon="heroicon-o-arrow-uturn-left"
                                        >
                                            Replay
                                        </x-filament::button>
                                    @else
                                        <span class="text-xs text-gray-300 dark:text-gray-600">—</span>
                                    @endif
                                </td>
                            @endif
                        </tr>
                    @endforeach
                </tbody>
            </table>
        </div>
    @else
        <div class="flex flex-col items-center justify-center py-14">
            <x-filament::icon icon="heroicon-o-circle-stack" class="h-10 w-10 text-gray-300 dark:text-gray-600 mb-3" />
            <p class="text-sm font-medium text-gray-500 dark:text-gray-400">No integration logs available</p>
        </div>
    @endif
</div>

</x-filament-panels::page>
