<x-filament-panels::page>
    <div class="mb-4">
        <x-filament::button wire:click="refreshChecks" color="info">
            Refresh checks
        </x-filament::button>
    </div>

    @php
        $overall = $healthSummary['overall'] ?? 'unknown';
        $checks = $healthSummary['checks'] ?? [];
    @endphp

    <x-filament::section>
        <x-slot name="heading">
            Overall status: {{ str($overall)->replace('_', ' ')->title() }}
        </x-slot>
        <x-slot name="description">
            Failing/at-risk checks: {{ $healthSummary['failing_checks'] ?? 0 }}
        </x-slot>
    </x-filament::section>

    <div class="grid gap-4 md:grid-cols-2">
        @foreach ($checks as $check)
            @php
                $color = match ($check['status'] ?? 'error') {
                    'ok' => 'success',
                    'warning' => 'warning',
                    default => 'danger',
                };
            @endphp
            <x-filament::section>
                <x-slot name="heading">
                    {{ $check['label'] ?? 'Check' }}
                </x-slot>
                <x-slot name="headerEnd">
                    <x-filament::badge :color="$color">
                        {{ str($check['status'] ?? 'unknown')->replace('_', ' ')->title() }}
                    </x-filament::badge>
                </x-slot>
                <p class="text-sm text-gray-700 dark:text-gray-300">
                    {{ $check['message'] ?? '' }}
                </p>
            </x-filament::section>
        @endforeach
    </div>
</x-filament-panels::page>
