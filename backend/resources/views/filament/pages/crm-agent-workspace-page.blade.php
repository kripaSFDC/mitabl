<x-filament-panels::page>
@php
    $priorityBadge = fn(string $p): string => match($p) {
        'urgent' => 'bg-red-100 text-red-700 dark:bg-red-900/40 dark:text-red-300 ring-1 ring-red-200 dark:ring-red-700',
        'high'   => 'bg-orange-100 text-orange-700 dark:bg-orange-900/40 dark:text-orange-300 ring-1 ring-orange-200 dark:ring-orange-700',
        'normal' => 'bg-blue-100 text-blue-700 dark:bg-blue-900/40 dark:text-blue-300 ring-1 ring-blue-200 dark:ring-blue-700',
        default  => 'bg-gray-100 text-gray-600 dark:bg-gray-700 dark:text-gray-300 ring-1 ring-gray-200 dark:ring-gray-600',
    };
    $priorityDot = fn(string $p): string => match($p) {
        'urgent' => 'bg-red-500',
        'high'   => 'bg-orange-400',
        'normal' => 'bg-blue-400',
        default  => 'bg-gray-400',
    };
    $statusBadge = fn(string $s): string => match($s) {
        'open'         => 'bg-sky-100 text-sky-700 dark:bg-sky-900/40 dark:text-sky-300',
        'in_progress'  => 'bg-yellow-100 text-yellow-700 dark:bg-yellow-900/40 dark:text-yellow-300',
        'pending_user' => 'bg-gray-100 text-gray-600 dark:bg-gray-700 dark:text-gray-300',
        'resolved'     => 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/40 dark:text-emerald-300',
        default        => 'bg-gray-100 text-gray-600 dark:bg-gray-700 dark:text-gray-300',
    };
@endphp

{{-- ── Top toolbar ─────────────────────────────────────────────────────── --}}
<div class="mb-4 flex items-center justify-between">
    <div class="flex items-center gap-3">
        <span class="inline-flex items-center gap-1.5 rounded-full bg-primary-50 px-3 py-1 text-xs font-semibold text-primary-700 ring-1 ring-primary-200 dark:bg-primary-900/30 dark:text-primary-300 dark:ring-primary-700">
            <span class="inline-block h-2 w-2 rounded-full bg-primary-500 animate-pulse"></span>
            Live triage — {{ count($queue) }} ticket{{ count($queue) !== 1 ? 's' : '' }} in queue
        </span>
    </div>
    <x-filament::button
        color="gray"
        size="sm"
        wire:click="refreshWorkspace"
        accesskey="r"
        aria-label="Refresh CRM workspace"
        icon="heroicon-o-arrow-path"
    >
        Refresh <span class="ml-1 text-xs text-gray-400">(Alt+R)</span>
    </x-filament::button>
</div>

{{-- ── 3-column workspace ────────────────────────────────────────────────── --}}
<div class="grid grid-cols-1 gap-4 xl:grid-cols-12" role="main" aria-label="CRM triage workspace">

    {{-- ── Column 1: Queue ──────────────────────────────────────────────── --}}
    <div class="xl:col-span-3" role="region" aria-label="Ticket queue">
        <div class="overflow-hidden rounded-xl border border-gray-200 bg-white shadow-sm dark:border-gray-700 dark:bg-gray-900">
            <div class="border-b border-gray-200 bg-gray-50 px-4 py-3 dark:border-gray-700 dark:bg-gray-800">
                <h2 class="text-sm font-semibold text-gray-900 dark:text-white">Triage Queue</h2>
                <p class="mt-0.5 text-xs text-gray-500 dark:text-gray-400">Sorted by priority · SLA deadline</p>
            </div>
            <div class="max-h-[calc(100vh-220px)] overflow-y-auto divide-y divide-gray-100 dark:divide-gray-800" tabindex="0" aria-label="Ticket queue list">
                @forelse ($queue as $ticket)
                    <button
                        wire:click="selectTicket({{ $ticket['id'] }})"
                        class="group w-full px-4 py-3 text-left transition-colors duration-100 focus:outline-none focus-visible:ring-2 focus-visible:ring-primary-500
                            {{ $selectedTicketId === $ticket['id']
                                ? 'bg-primary-50 dark:bg-primary-900/25'
                                : 'hover:bg-gray-50 dark:hover:bg-gray-800/60' }}"
                        aria-current="{{ $selectedTicketId === $ticket['id'] ? 'true' : 'false' }}"
                    >
                        <div class="flex items-start justify-between gap-2">
                            <div class="flex min-w-0 flex-col">
                                <div class="flex items-center gap-1.5">
                                    <span class="inline-block h-1.5 w-1.5 flex-shrink-0 rounded-full {{ $priorityDot($ticket['priority']) }}"></span>
                                    <span class="truncate text-xs font-mono font-semibold text-gray-700 dark:text-gray-200">{{ $ticket['ticket_number'] }}</span>
                                </div>
                                <p class="mt-1 text-xs leading-snug text-gray-700 dark:text-gray-300 line-clamp-2">{{ $ticket['subject'] }}</p>
                            </div>
                        </div>
                        <div class="mt-2 flex items-center gap-1.5 flex-wrap">
                            <span class="inline-flex items-center rounded-full px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wide {{ $priorityBadge($ticket['priority']) }}">
                                {{ $ticket['priority'] }}
                            </span>
                            <span class="inline-flex items-center rounded-full bg-gray-100 px-2 py-0.5 text-[10px] text-gray-600 dark:bg-gray-800 dark:text-gray-400">
                                {{ str($ticket['status'])->replace('_', ' ')->title() }}
                            </span>
                        </div>
                    </button>
                @empty
                    <div class="flex flex-col items-center justify-center py-12 text-center">
                        <x-filament::icon icon="heroicon-o-check-circle" class="h-8 w-8 text-emerald-400 mb-2" />
                        <p class="text-sm font-medium text-gray-600 dark:text-gray-300">Queue is clear</p>
                        <p class="mt-0.5 text-xs text-gray-400">No tickets awaiting triage</p>
                    </div>
                @endforelse
            </div>
        </div>
    </div>

    {{-- ── Column 2: Timeline + Composer ────────────────────────────────── --}}
    <div class="xl:col-span-6" role="region" aria-label="Ticket timeline and reply composer">
        <div class="flex flex-col overflow-hidden rounded-xl border border-gray-200 bg-white shadow-sm dark:border-gray-700 dark:bg-gray-900">

            @if ($selectedTicket)
                {{-- Ticket header ribbon --}}
                <div class="border-b border-gray-200 bg-gray-50 px-5 py-3 dark:border-gray-700 dark:bg-gray-800">
                    <div class="flex flex-wrap items-start justify-between gap-2">
                        <div>
                            <div class="flex items-center gap-2">
                                <span class="font-mono text-xs font-bold text-gray-500 dark:text-gray-400">{{ $selectedTicket['ticket_number'] }}</span>
                                <span class="text-sm font-semibold text-gray-900 dark:text-white">{{ $selectedTicket['subject'] }}</span>
                            </div>
                            <div class="mt-1 flex flex-wrap items-center gap-1.5 text-xs text-gray-500 dark:text-gray-400">
                                <span class="inline-flex items-center rounded-full px-2 py-0.5 text-[10px] font-semibold uppercase {{ $statusBadge($selectedTicket['status']) }}">
                                    {{ str($selectedTicket['status'])->replace('_', ' ')->title() }}
                                </span>
                                <span class="inline-flex items-center rounded-full px-2 py-0.5 text-[10px] font-semibold uppercase {{ $priorityBadge($selectedTicket['priority']) }}">
                                    {{ $selectedTicket['priority'] }}
                                </span>
                                <span class="text-gray-400">·</span>
                                <span>{{ str($selectedTicket['category'])->replace('_', ' ')->title() }}</span>
                                @if ($selectedTicket['assignee'])
                                    <span class="text-gray-400">·</span>
                                    <span class="inline-flex items-center gap-1">
                                        <x-filament::icon icon="heroicon-o-user-circle" class="h-3 w-3" />
                                        {{ $selectedTicket['assignee'] }}
                                    </span>
                                @else
                                    <span class="text-amber-500 dark:text-amber-400">⚠ Unassigned</span>
                                @endif
                            </div>
                        </div>
                        <span class="text-xs text-gray-400 dark:text-gray-500">Updated {{ $selectedTicket['updated_at'] }}</span>
                    </div>
                </div>

                {{-- Conversation timeline --}}
                <ol class="flex-1 max-h-72 overflow-y-auto space-y-1 px-4 py-3" aria-label="Conversation timeline">
                    @forelse ($timeline as $entry)
                        @php
                            $isCustomer  = $entry['sender'] === 'user' || $entry['sender'] === 'customer';
                            $isInternal  = (bool) $entry['internal'];
                            $bubbleBg    = $isInternal
                                ? 'bg-amber-50 border-amber-200 dark:bg-amber-900/20 dark:border-amber-700'
                                : ($isCustomer
                                    ? 'bg-blue-50 border-blue-200 dark:bg-blue-900/20 dark:border-blue-700'
                                    : 'bg-emerald-50 border-emerald-200 dark:bg-emerald-900/20 dark:border-emerald-700');
                            $senderLabel = $isInternal ? '🔒 Internal Note' : ($isCustomer ? '👤 Customer' : '🎧 Agent');
                            $senderColor = $isInternal ? 'text-amber-600 dark:text-amber-400' : ($isCustomer ? 'text-blue-600 dark:text-blue-400' : 'text-emerald-600 dark:text-emerald-400');
                        @endphp
                        <li class="rounded-lg border p-3 text-sm {{ $bubbleBg }}" tabindex="0">
                            <div class="mb-1.5 flex items-center justify-between">
                                <span class="text-[10px] font-bold uppercase tracking-wide {{ $senderColor }}">{{ $senderLabel }}</span>
                                <span class="text-[10px] text-gray-400 dark:text-gray-500">{{ $entry['created_at'] }}</span>
                            </div>
                            <p class="text-gray-800 dark:text-gray-200 whitespace-pre-wrap leading-relaxed">{{ $entry['message'] }}</p>
                        </li>
                    @empty
                        <li class="flex flex-col items-center justify-center py-8 text-center text-sm text-gray-400">
                            <x-filament::icon icon="heroicon-o-chat-bubble-left-right" class="h-7 w-7 mb-2 text-gray-300" />
                            No messages yet
                        </li>
                    @endforelse
                </ol>

                {{-- Reply composer --}}
                <div class="border-t border-gray-200 dark:border-gray-700 p-4 space-y-3">
                    {{-- Macro row --}}
                    <div class="flex items-end gap-2">
                        <div class="flex-1">
                            <label class="mb-1 block text-xs font-medium text-gray-600 dark:text-gray-400" for="macro-select">
                                Insert response macro
                            </label>
                            <select
                                id="macro-select"
                                wire:model="macroTemplateId"
                                class="block w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm text-gray-700 shadow-sm transition focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-200"
                                aria-label="Select a macro template"
                            >
                                <option value="">— Select macro —</option>
                                @foreach ($recommendedMacros as $macro)
                                    <option value="{{ $macro['id'] }}">
                                        {{ $macro['name'] }}
                                        @if ($macro['score'] > 0) ★{{ $macro['score'] }} @endif
                                    </option>
                                @endforeach
                            </select>
                        </div>
                        <x-filament::button
                            color="gray"
                            size="sm"
                            wire:click="applyMacro"
                            accesskey="m"
                            aria-label="Insert selected macro into reply"
                        >
                            Insert
                        </x-filament::button>
                    </div>

                    {{-- Reply textarea --}}
                    <div>
                        <label class="mb-1 block text-xs font-medium text-gray-600 dark:text-gray-400" for="reply-message">
                            Reply to customer
                        </label>
                        <textarea
                            id="reply-message"
                            wire:model="replyMessage"
                            rows="5"
                            placeholder="Type your reply here…"
                            class="block w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm text-gray-800 shadow-sm placeholder-gray-400 transition focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-200 dark:placeholder-gray-500"
                            aria-label="Ticket reply text"
                        ></textarea>
                        <p class="mt-1 text-right text-[10px] text-gray-400">{{ strlen($replyMessage) }} chars</p>
                    </div>

                    <div class="flex items-center justify-end gap-2">
                        <x-filament::button
                            color="success"
                            wire:click="sendReply"
                            icon="heroicon-o-paper-airplane"
                            accesskey="s"
                            aria-label="Send reply to customer"
                        >
                            Send Reply
                        </x-filament::button>
                    </div>
                </div>
            @else
                {{-- Empty state --}}
                <div class="flex flex-col items-center justify-center py-24 text-center px-6">
                    <x-filament::icon icon="heroicon-o-inbox-stack" class="h-12 w-12 text-gray-300 dark:text-gray-600 mb-3" />
                    <h3 class="text-sm font-semibold text-gray-600 dark:text-gray-300">No ticket selected</h3>
                    <p class="mt-1 text-xs text-gray-400">Choose a ticket from the queue to begin triage</p>
                </div>
            @endif
        </div>
    </div>

    {{-- ── Column 3: Context panel ──────────────────────────────────────── --}}
    <div class="xl:col-span-3 space-y-4" role="complementary" aria-label="Ticket context">

        @if ($selectedTicket)
        {{-- Ticket metadata --}}
        <div class="overflow-hidden rounded-xl border border-gray-200 bg-white shadow-sm dark:border-gray-700 dark:bg-gray-900">
            <div class="border-b border-gray-200 bg-gray-50 px-4 py-3 dark:border-gray-700 dark:bg-gray-800">
                <h2 class="text-xs font-semibold uppercase tracking-wide text-gray-500 dark:text-gray-400">Ticket Metadata</h2>
            </div>
            <dl class="divide-y divide-gray-100 dark:divide-gray-800 text-xs">
                <div class="flex items-center justify-between px-4 py-2.5">
                    <dt class="text-gray-500 dark:text-gray-400">Requester</dt>
                    <dd class="font-medium text-gray-800 dark:text-gray-200 truncate max-w-[60%] text-right">{{ $selectedTicket['requester_email'] ?? '—' }}</dd>
                </div>
                <div class="flex items-center justify-between px-4 py-2.5">
                    <dt class="text-gray-500 dark:text-gray-400">Category</dt>
                    <dd class="font-medium text-gray-800 dark:text-gray-200">{{ str($selectedTicket['category'] ?? '—')->replace('_', ' ')->title() }}</dd>
                </div>
                <div class="flex items-center justify-between px-4 py-2.5">
                    <dt class="text-gray-500 dark:text-gray-400">Priority</dt>
                    <dd>
                        <span class="inline-flex rounded-full px-2 py-0.5 text-[10px] font-bold uppercase {{ $priorityBadge($selectedTicket['priority'] ?? 'low') }}">
                            {{ $selectedTicket['priority'] ?? '—' }}
                        </span>
                    </dd>
                </div>
                <div class="flex items-center justify-between px-4 py-2.5">
                    <dt class="text-gray-500 dark:text-gray-400">Status</dt>
                    <dd>
                        <span class="inline-flex rounded-full px-2 py-0.5 text-[10px] font-semibold {{ $statusBadge($selectedTicket['status'] ?? '') }}">
                            {{ str($selectedTicket['status'] ?? '—')->replace('_', ' ')->title() }}
                        </span>
                    </dd>
                </div>
                <div class="flex items-center justify-between px-4 py-2.5">
                    <dt class="text-gray-500 dark:text-gray-400">Assignee</dt>
                    <dd class="font-medium text-gray-800 dark:text-gray-200">{{ $selectedTicket['assignee'] ?? 'Unassigned' }}</dd>
                </div>
                <div class="flex items-center justify-between px-4 py-2.5">
                    <dt class="text-gray-500 dark:text-gray-400">Updated</dt>
                    <dd class="text-gray-500 dark:text-gray-400">{{ $selectedTicket['updated_at'] ?? '—' }}</dd>
                </div>
            </dl>
        </div>
        @endif

        {{-- Related / similar tickets --}}
        <div class="overflow-hidden rounded-xl border border-gray-200 bg-white shadow-sm dark:border-gray-700 dark:bg-gray-900">
            <div class="border-b border-gray-200 bg-gray-50 px-4 py-3 dark:border-gray-700 dark:bg-gray-800">
                <h2 class="text-xs font-semibold uppercase tracking-wide text-gray-500 dark:text-gray-400">Similar Tickets</h2>
                <p class="mt-0.5 text-[10px] text-gray-400">Historical resolution hints</p>
            </div>
            <div class="divide-y divide-gray-100 dark:divide-gray-800">
                @forelse ($relatedTickets as $related)
                    <div class="px-4 py-3">
                        <div class="flex items-center justify-between gap-2">
                            <span class="font-mono text-xs font-semibold text-gray-700 dark:text-gray-200">{{ $related['ticket_number'] }}</span>
                            <span class="inline-flex items-center rounded-full bg-blue-100 px-2 py-0.5 text-[10px] font-bold text-blue-700 dark:bg-blue-900/40 dark:text-blue-300">
                                {{ $related['similarity'] }}%
                            </span>
                        </div>
                        <p class="mt-1 text-xs text-gray-600 dark:text-gray-300 line-clamp-2">{{ $related['subject'] }}</p>
                        <div class="mt-1.5 flex items-center gap-1.5">
                            <span class="inline-flex rounded-full px-2 py-0.5 text-[10px] {{ $statusBadge($related['status']) }}">
                                {{ str($related['status'])->replace('_', ' ')->title() }}
                            </span>
                        </div>
                        @if (!empty($related['resolution_summary']))
                            <p class="mt-1.5 text-[11px] italic text-gray-500 dark:text-gray-400 line-clamp-2">
                                ↳ {{ $related['resolution_summary'] }}
                            </p>
                        @endif
                    </div>
                @empty
                    <div class="flex flex-col items-center justify-center py-8 text-center">
                        <p class="text-xs text-gray-400">No similar tickets found</p>
                    </div>
                @endforelse
            </div>
        </div>
    </div>

</div>
</x-filament-panels::page>
