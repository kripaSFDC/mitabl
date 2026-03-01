<x-filament-panels::page>
    <x-filament::section class="mb-4">
        <x-slot name="heading">How to use this page</x-slot>
        <x-slot name="description">
            Group settings by domain (auth, payments, queue, integrations), document every risky change,
            and provide a reason for auditability. High-risk keys require step-up authentication.
        </x-slot>
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
