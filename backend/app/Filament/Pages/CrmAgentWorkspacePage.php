<?php

namespace App\Filament\Pages;

use App\Models\SupportTicket;
use App\Models\Template;
use App\Services\AdminAuditLogService;
use App\Services\SupportTicketService;
use Filament\Facades\Filament;
use Filament\Notifications\Notification;
use Filament\Pages\Page;

class CrmAgentWorkspacePage extends Page
{
    protected static ?string $navigationIcon = 'heroicon-o-rectangle-group';

    protected static ?string $navigationGroup = 'Customer Support';

    protected static ?int $navigationSort = 5;

    protected static ?string $title = 'CRM Agent Workspace';

    protected static string $view = 'filament.pages.crm-agent-workspace-page';

    public array $queue = [];
    public ?int $selectedTicketId = null;
    public ?array $selectedTicket = null;
    public array $timeline = [];
    public array $recommendedMacros = [];
    public array $relatedTickets = [];
    public string $replyMessage = '';
    public ?int $macroTemplateId = null;

    public function mount(): void
    {
        $this->loadQueue();

        if ($this->selectedTicketId === null && count($this->queue) > 0) {
            $this->selectTicket((int) $this->queue[0]['id']);
        }
    }

    public function refreshWorkspace(): void
    {
        $this->loadQueue();
        if ($this->selectedTicketId) {
            $this->selectTicket($this->selectedTicketId);
        }
    }

    public function selectTicket(int $ticketId): void
    {
        $ticket = SupportTicket::query()
            ->with(['assignee', 'messages', 'events'])
            ->find($ticketId);

        if (! $ticket) {
            return;
        }

        $this->selectedTicketId = $ticket->id;
        $this->selectedTicket = [
            'id' => $ticket->id,
            'ticket_number' => $ticket->ticket_number,
            'subject' => $ticket->subject,
            'status' => $ticket->status,
            'priority' => $ticket->priority,
            'category' => $ticket->category,
            'requester_email' => $ticket->requester_email,
            'assignee' => $ticket->assignee?->name,
            'updated_at' => optional($ticket->updated_at)?->toDateTimeString(),
        ];

        $this->timeline = $ticket->messages->sortBy('created_at')->map(fn ($message): array => [
            'sender' => (string) $message->sender_type,
            'message' => (string) $message->message,
            'internal' => (bool) $message->is_internal_note,
            'created_at' => optional($message->created_at)?->toDateTimeString(),
        ])->values()->all();

        $this->recommendedMacros = $this->buildMacroRecommendations($ticket);
        $this->relatedTickets = $this->buildRelatedTickets($ticket);
    }

    public function applyMacro(): void
    {
        if (! $this->macroTemplateId) {
            return;
        }

        $template = Template::query()->where('active', true)->find($this->macroTemplateId);
        if (! $template) {
            return;
        }

        $body = $template->body;
        $macroText = is_array($body)
            ? (string) ($body['message'] ?? $body['content'] ?? json_encode($body))
            : (string) $body;

        $this->replyMessage = trim($this->replyMessage . "\n\n" . $macroText);
    }

    public function sendReply(): void
    {
        if (! $this->selectedTicketId) {
            return;
        }

        $ticket = SupportTicket::query()->find($this->selectedTicketId);
        if (! $ticket) {
            return;
        }

        try {
            app(SupportTicketService::class)->addReply(
                $ticket,
                ['message' => $this->replyMessage],
                'admin',
                Filament::auth()->id(),
                $ticket->updated_at?->toISOString(),
            );

            app(AdminAuditLogService::class)->log('crm_workspace.reply', request(), [
                'ticket_id' => $ticket->id,
                'macro_template_id' => $this->macroTemplateId,
            ]);

            $this->replyMessage = '';
            Notification::make()->title('Reply sent.')->success()->send();
            $this->refreshWorkspace();
        } catch (\Throwable $throwable) {
            Notification::make()->title('Reply failed: ' . $throwable->getMessage())->danger()->send();
        }
    }

    private function loadQueue(): void
    {
        $this->queue = SupportTicket::query()
            ->whereNull('merged_into_ticket_id')
            ->whereIn('status', [
                SupportTicket::STATUS_OPEN,
                SupportTicket::STATUS_IN_PROGRESS,
                SupportTicket::STATUS_PENDING_USER,
                SupportTicket::STATUS_RESOLVED,
            ])
            ->orderByRaw("case when priority = 'urgent' then 0 when priority = 'high' then 1 when priority = 'normal' then 2 else 3 end")
            ->orderBy('updated_at')
            ->limit(50)
            ->get(['id', 'ticket_number', 'subject', 'status', 'priority'])
            ->map(fn (SupportTicket $ticket): array => [
                'id' => $ticket->id,
                'ticket_number' => $ticket->ticket_number,
                'subject' => $ticket->subject,
                'status' => $ticket->status,
                'priority' => $ticket->priority,
            ])
            ->all();
    }

    private function buildMacroRecommendations(SupportTicket $ticket): array
    {
        $categoryHints = [
            SupportTicket::CATEGORY_PAYMENT => ['payment', 'refund', 'charge'],
            SupportTicket::CATEGORY_ORDER_DISPUTE => ['order', 'delivery', 'late'],
            SupportTicket::CATEGORY_ACCOUNT => ['account', 'login', 'profile'],
            SupportTicket::CATEGORY_GENERAL => ['general', 'thanks', 'follow up'],
            SupportTicket::CATEGORY_OTHER => ['other'],
        ];

        $hints = $categoryHints[$ticket->category] ?? ['support'];

        return Template::query()
            ->where('active', true)
            ->where(function ($query): void {
                $query->where('channel', 'support')
                    ->orWhere('channel', 'support_ticket')
                    ->orWhereNull('channel');
            })
            ->limit(40)
            ->get()
            ->map(function (Template $template) use ($hints): array {
                $haystack = strtolower(implode(' ', [
                    $template->name,
                    $template->subject,
                    is_array($template->body) ? json_encode($template->body) : (string) $template->body,
                ]));

                $score = 0;
                foreach ($hints as $hint) {
                    if (str_contains($haystack, $hint)) {
                        $score++;
                    }
                }

                return [
                    'id' => $template->id,
                    'name' => $template->name,
                    'score' => $score,
                ];
            })
            ->sortByDesc('score')
            ->take(5)
            ->values()
            ->all();
    }

    private function buildRelatedTickets(SupportTicket $ticket): array
    {
        $candidates = SupportTicket::query()
            ->where('id', '!=', $ticket->id)
            ->whereNull('merged_into_ticket_id')
            ->where(function ($query) use ($ticket): void {
                $query->where('requester_email', $ticket->requester_email)
                    ->orWhere('category', $ticket->category);
            })
            ->latest('updated_at')
            ->limit(25)
            ->get(['id', 'ticket_number', 'subject', 'status', 'resolution_summary', 'updated_at']);

        return $candidates->map(function (SupportTicket $candidate) use ($ticket): array {
            similar_text(strtolower($ticket->subject), strtolower($candidate->subject), $percent);

            return [
                'id' => $candidate->id,
                'ticket_number' => $candidate->ticket_number,
                'subject' => $candidate->subject,
                'status' => $candidate->status,
                'resolution_summary' => (string) $candidate->resolution_summary,
                'similarity' => round($percent, 1),
            ];
        })->sortByDesc('similarity')->take(6)->values()->all();
    }

    public static function canAccess(): bool
    {
        return (bool) Filament::auth()->user()?->can('support_ticket.view');
    }
}
