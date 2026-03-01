<x-filament-panels::page>
    <div class="mb-4 flex gap-2">
        <x-filament::button color="info" wire:click="refreshWorkspace" accesskey="r" aria-label="Refresh CRM workspace">
            Refresh
        </x-filament::button>
    </div>

    <div class="grid grid-cols-1 gap-4 xl:grid-cols-12" role="main" aria-label="CRM triage workspace">
        <x-filament::section class="xl:col-span-3" role="region" aria-label="Ticket queue">
            <x-slot name="heading">Queue</x-slot>
            <x-slot name="description">Use Alt/Option + R to refresh. Select a ticket to open its timeline.</x-slot>

            <div class="space-y-2" tabindex="0" aria-label="Ticket queue list">
                @forelse ($queue as $ticket)
                    <button
                        wire:click="selectTicket({{ $ticket['id'] }})"
                        class="w-full rounded-md border p-2 text-left text-sm {{ $selectedTicketId === $ticket['id'] ? 'border-primary-500 bg-primary-50 dark:bg-primary-900/30' : 'border-gray-200 dark:border-gray-700' }}"
                        aria-current="{{ $selectedTicketId === $ticket['id'] ? 'true' : 'false' }}"
                    >
                        <div class="font-semibold">{{ $ticket['ticket_number'] }}</div>
                        <div>{{ str($ticket['subject'])->limit(56) }}</div>
                        <div class="mt-1 text-xs text-gray-600 dark:text-gray-300">
                            {{ str($ticket['status'])->replace('_', ' ')->title() }} · {{ ucfirst($ticket['priority']) }}
                        </div>
                    </button>
                @empty
                    <p class="text-sm text-gray-500">No tickets in queue.</p>
                @endforelse
            </div>
        </x-filament::section>

        <x-filament::section class="xl:col-span-6" role="region" aria-label="Ticket timeline and reply composer">
            <x-slot name="heading">Timeline</x-slot>
            <x-slot name="description">Conversation history and reply composer with macro insertion.</x-slot>

            @if ($selectedTicket)
                <div class="mb-3 rounded-md border border-gray-200 p-3 dark:border-gray-700">
                    <div class="font-semibold">{{ $selectedTicket['ticket_number'] }} · {{ $selectedTicket['subject'] }}</div>
                    <div class="text-xs text-gray-600 dark:text-gray-300">
                        {{ str($selectedTicket['status'])->replace('_', ' ')->title() }} · {{ ucfirst($selectedTicket['priority']) }} · {{ $selectedTicket['category'] }}
                    </div>
                </div>

                <ol class="mb-4 max-h-72 space-y-2 overflow-y-auto" aria-label="Conversation timeline">
                    @forelse ($timeline as $entry)
                        <li class="rounded-md border border-gray-200 p-3 text-sm dark:border-gray-700" tabindex="0">
                            <div class="mb-1 text-xs font-semibold text-gray-600 dark:text-gray-300">
                                {{ strtoupper($entry['sender']) }} @if ($entry['internal']) (internal note) @endif · {{ $entry['created_at'] }}
                            </div>
                            <div>{{ $entry['message'] }}</div>
                        </li>
                    @empty
                        <li class="text-sm text-gray-500">No timeline messages yet.</li>
                    @endforelse
                </ol>

                <div class="space-y-2">
                    <label class="text-sm font-medium" for="macro-select">Recommended macros</label>
                    <select id="macro-select" wire:model="macroTemplateId" class="fi-input block w-full" aria-label="Select a macro template">
                        <option value="">Select macro</option>
                        @foreach ($recommendedMacros as $macro)
                            <option value="{{ $macro['id'] }}">{{ $macro['name'] }} (score {{ $macro['score'] }})</option>
                        @endforeach
                    </select>

                    <x-filament::button color="gray" wire:click="applyMacro" accesskey="m" aria-label="Insert selected macro into reply">
                        Insert macro
                    </x-filament::button>

                    <label class="text-sm font-medium" for="reply-message">Reply</label>
                    <textarea id="reply-message" wire:model="replyMessage" rows="5" class="fi-input block w-full" aria-label="Ticket reply text"></textarea>

                    <x-filament::button color="success" wire:click="sendReply" accesskey="s" aria-label="Send reply to customer">
                        Send reply
                    </x-filament::button>
                </div>
            @else
                <p class="text-sm text-gray-500">Select a ticket to start triage.</p>
            @endif
        </x-filament::section>

        <x-filament::section class="xl:col-span-3" role="complementary" aria-label="Ticket context and similar resolutions">
            <x-slot name="heading">Context</x-slot>
            <x-slot name="description">Related tickets and historical resolution hints.</x-slot>

            <div class="space-y-2" tabindex="0" aria-label="Related tickets list">
                @forelse ($relatedTickets as $related)
                    <div class="rounded-md border border-gray-200 p-2 text-sm dark:border-gray-700">
                        <div class="font-semibold">{{ $related['ticket_number'] }} ({{ $related['similarity'] }}%)</div>
                        <div>{{ str($related['subject'])->limit(54) }}</div>
                        <div class="text-xs text-gray-600 dark:text-gray-300">
                            {{ str($related['status'])->replace('_', ' ')->title() }}
                        </div>
                        @if ($related['resolution_summary'] !== '')
                            <div class="mt-1 text-xs">Resolution: {{ str($related['resolution_summary'])->limit(120) }}</div>
                        @endif
                    </div>
                @empty
                    <p class="text-sm text-gray-500">No similar tickets found.</p>
                @endforelse
            </div>
        </x-filament::section>
    </div>
</x-filament-panels::page>
