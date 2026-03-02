<x-filament-panels::page>
@php
    $overall    = $healthSummary['overall'] ?? 'unknown';
    $checks     = $healthSummary['checks'] ?? [];
    $failing    = (int) ($healthSummary['failing_checks'] ?? 0);

    $overallColor = match ($overall) {
        'healthy'  => ['banner' => 'border-emerald-300 bg-emerald-50 dark:border-emerald-700 dark:bg-emerald-950/40',
                       'dot'    => 'bg-emerald-400',
                       'text'   => 'text-emerald-700 dark:text-emerald-300',
                       'label'  => 'Operational'],
        'degraded' => ['banner' => 'border-yellow-300 bg-yellow-50 dark:border-yellow-700 dark:bg-yellow-950/40',
                       'dot'    => 'bg-yellow-400 animate-pulse',
                       'text'   => 'text-yellow-700 dark:text-yellow-300',
                       'label'  => 'Degraded'],
        default    => ['banner' => 'border-red-300 bg-red-50 dark:border-red-700 dark:bg-red-950/40',
                       'dot'    => 'bg-red-500 animate-pulse',
                       'text'   => 'text-red-700 dark:text-red-300',
                       'label'  => 'Incident'],
    };

    $checkCard = fn(string $s): array => match ($s) {
        'ok'      => ['border' => 'border-l-emerald-400', 'badge' => 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/40 dark:text-emerald-300', 'icon' => '✓'],
        'warning' => ['border' => 'border-l-yellow-400',  'badge' => 'bg-yellow-100 text-yellow-700 dark:bg-yellow-900/40 dark:text-yellow-300',  'icon' => '⚠'],
        default   => ['border' => 'border-l-red-400',     'badge' => 'bg-red-100 text-red-700 dark:bg-red-900/40 dark:text-red-300',               'icon' => '✕'],
    };
@endphp

{{-- Top action bar --}}
<div class="mb-5 flex items-center justify-between">
    <p class="text-xs text-gray-500 dark:text-gray-400">
        Start with failing checks, then warnings. Confirm readiness before bulk queue retries or CRM operations.
    </p>
    <x-filament::button
        wire:click="refreshChecks"
        color="gray"
        size="sm"
        icon="heroicon-o-arrow-path"
    >
        Refresh Checks
    </x-filament::button>
</div>

{{-- Overall status banner --}}
<div class="mb-6 flex items-center gap-4 rounded-xl border px-6 py-4 {{ $overallColor['banner'] }}">
    <span class="inline-block h-3 w-3 rounded-full {{ $overallColor['dot'] }}"></span>
    <div class="flex-1">
        <p class="text-sm font-bold {{ $overallColor['text'] }}">System Status: {{ $overallColor['label'] }}</p>
        <p class="text-xs text-gray-500 dark:text-gray-400 mt-0.5">
            {{ count($checks) }} checks · {{ $failing > 0 ? $failing . ' failing / at-risk' : 'all checks passing' }}
        </p>
    </div>
    @if ($failing > 0)
        <span class="inline-flex items-center rounded-full bg-red-100 px-3 py-1 text-sm font-bold text-red-700 dark:bg-red-900/40 dark:text-red-300">
            {{ $failing }} failing
        </span>
    @else
        <span class="inline-flex items-center rounded-full bg-emerald-100 px-3 py-1 text-sm font-bold text-emerald-700 dark:bg-emerald-900/40 dark:text-emerald-300">
            All clear
        </span>
    @endif
</div>

{{-- Check cards grid --}}
@if (count($checks) > 0)
    <div class="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
        @foreach ($checks as $check)
            @php $card = $checkCard($check['status'] ?? 'error'); @endphp
            <div class="overflow-hidden rounded-xl border border-gray-200 border-l-4 bg-white shadow-sm dark:border-gray-700 dark:bg-gray-900 {{ $card['border'] }}">
                <div class="px-5 py-4">
                    <div class="flex items-start justify-between gap-3">
                        <div class="flex-1 min-w-0">
                            <h3 class="text-sm font-semibold text-gray-900 dark:text-white truncate">
                                {{ $check['label'] ?? 'Check' }}
                            </h3>
                        </div>
                        <span class="flex-shrink-0 inline-flex items-center gap-1 rounded-full px-2.5 py-1 text-[11px] font-bold uppercase tracking-wide {{ $card['badge'] }}">
                            <span>{{ $card['icon'] }}</span>
                            {{ str($check['status'] ?? 'unknown')->replace('_', ' ')->upper() }}
                        </span>
                    </div>
                    @if (!empty($check['message']))
                        <p class="mt-2 text-xs leading-relaxed text-gray-600 dark:text-gray-400">
                            {{ $check['message'] }}
                        </p>
                    @endif
                    @if (!empty($check['value']))
                        <p class="mt-2 text-xs font-mono text-gray-500 dark:text-gray-500">
                            Value: {{ $check['value'] }}
                        </p>
                    @endif
                </div>
            </div>
        @endforeach
    </div>
@else
    <div class="flex flex-col items-center justify-center rounded-xl border border-dashed border-gray-300 py-16 dark:border-gray-600">
        <x-filament::icon icon="heroicon-o-signal-slash" class="h-10 w-10 text-gray-300 dark:text-gray-600 mb-3" />
        <p class="text-sm text-gray-500">No checks available. Run a refresh to load health data.</p>
    </div>
@endif

{{-- Guide footer --}}
<div class="mt-6 rounded-xl border border-gray-200 bg-gray-50 px-5 py-4 dark:border-gray-700 dark:bg-gray-800/60">
    <p class="text-xs font-semibold text-gray-600 dark:text-gray-300 mb-1">Triage Runbook</p>
    <p class="text-xs text-gray-500 dark:text-gray-400">
        1. Resolve <strong>failing</strong> checks first — these indicate service outages or data integrity issues.<br>
        2. Investigate <strong>warnings</strong> before running bulk operations (queue retries, mass CRM actions).<br>
        3. Confirm all checks are <strong>OK</strong> before marking incidents as resolved.
    </p>
</div>
</x-filament-panels::page>
