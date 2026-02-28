<?php

namespace App\Services;

use App\Models\SupportTicket;
use App\Models\SupportTicketEvent;
use App\Models\SupportTicketMessage;
use App\Notifications\SupportTicketEscalatedNotification;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use InvalidArgumentException;

class SupportTicketService
{
    public function __construct(private CrmCommunicationService $communications)
    {
    }

    public function createTicket(array $payload, string $source = 'api'): array
    {
        $normalized = $this->normalizePayload($payload, $source);
        $fingerprint = $this->fingerprint($normalized['requester_email'], $normalized['subject'], $normalized['description']);

        if (! ((bool) ($payload['skip_duplicate_check'] ?? false))) {
            $existing = SupportTicket::query()
                ->where('intake_fingerprint', $fingerprint)
                ->where('created_at', '>=', now()->subMinutes((int) config('support.duplicate_window_minutes', 10)))
                ->first();

            if ($existing) {
                return ['ticket' => $existing, 'duplicate' => true];
            }
        }

        $ticket = DB::transaction(function () use ($normalized, $fingerprint): SupportTicket {
            $ticket = SupportTicket::create([
                'ticket_number' => $this->nextTicketNumber(),
                'user_id' => $normalized['user_id'],
                'requester_name' => $normalized['requester_name'],
                'requester_email' => $normalized['requester_email'],
                'requester_phone' => $normalized['requester_phone'],
                'subject' => $normalized['subject'],
                'description' => $normalized['description'],
                'source' => $normalized['source'],
                'category' => $normalized['category'],
                'priority' => $normalized['priority'],
                'status' => $normalized['status'],
                'assigned_to' => $normalized['assigned_to'],
                'order_id' => $normalized['order_id'],
                'mikitchn_id' => $normalized['mikitchn_id'],
                'first_response_due_at' => $normalized['first_response_due_at'],
                'resolution_due_at' => $normalized['resolution_due_at'],
                'requester_token' => Str::random(48),
                'intake_fingerprint' => $fingerprint,
                'spam_score' => $normalized['spam_score'],
                'spam_detected_at' => $normalized['spam_detected_at'],
                'last_message_at' => now(),
            ]);

            SupportTicketMessage::create([
                'ticket_id' => $ticket->id,
                'sender_type' => $ticket->user_id ? 'user' : 'guest',
                'sender_id' => $ticket->user_id,
                'message' => $normalized['description'],
                'is_internal_note' => false,
            ]);

            $this->recordEvent($ticket, 'ticket_created', $normalized['actor_type'], $normalized['actor_id'], [
                'source' => $normalized['source'],
                'priority' => $normalized['priority'],
                'status' => $normalized['status'],
            ]);

            return $ticket;
        });

        if ($ticket->status !== SupportTicket::STATUS_SPAM) {
            $this->communications->sendTicketAcknowledgement($ticket);
        }

        return ['ticket' => $ticket, 'duplicate' => false];
    }

    public function addReply(SupportTicket $ticket, array $payload, string $senderType, ?int $senderId = null): SupportTicketMessage
    {
        $message = trim((string) ($payload['message'] ?? ''));
        if ($message === '') {
            throw new InvalidArgumentException('Reply message is required.');
        }
        $reopenReason = trim((string) ($payload['reopen_reason'] ?? ''));

        $isInternal = (bool) ($payload['is_internal_note'] ?? false);

        $reply = DB::transaction(function () use ($ticket, $senderType, $senderId, $message, $isInternal, $reopenReason): SupportTicketMessage {
            $locked = SupportTicket::query()->lockForUpdate()->findOrFail($ticket->id);
            if ($locked->isTerminal() && $locked->status !== SupportTicket::STATUS_RESOLVED) {
                throw new InvalidArgumentException('Ticket is closed and cannot be updated.');
            }

            $reply = SupportTicketMessage::create([
                'ticket_id' => $locked->id,
                'sender_type' => $senderType,
                'sender_id' => $senderId,
                'message' => $message,
                'is_internal_note' => $isInternal,
            ]);

            if (! $isInternal && $senderType === 'admin' && $locked->first_responded_at === null) {
                $locked->first_responded_at = now();
            }

            if ($senderType === 'user' || $senderType === 'guest') {
                if ($locked->status === SupportTicket::STATUS_RESOLVED) {
                    if ($reopenReason === '') {
                        throw new InvalidArgumentException('Reopen reason is required to reply on a resolved ticket.');
                    }

                    $windowHours = (int) config('support.reopen_window_hours', 72);
                    if ($locked->resolved_at === null || $locked->resolved_at->lt(now()->subHours($windowHours))) {
                        throw new InvalidArgumentException('Ticket can no longer be reopened. Reopen window has expired.');
                    }

                    $locked->status = SupportTicket::STATUS_OPEN;
                    $locked->reopened_count = (int) $locked->reopened_count + 1;
                    $locked->resolved_at = null;
                    $locked->resolution_summary = null;
                    $locked->resolution_breached_at = null;

                    $this->recordEvent($locked, 'reopened', $senderType, $senderId, [
                        'reason' => $reopenReason,
                    ]);
                } else {
                    $locked->status = SupportTicket::STATUS_OPEN;
                }
            } elseif (! $isInternal && $locked->status === SupportTicket::STATUS_OPEN) {
                $locked->status = SupportTicket::STATUS_PENDING_USER;
            }

            $locked->last_message_at = now();
            $locked->save();

            $this->recordEvent($locked, 'ticket_reply', $senderType, $senderId, [
                'is_internal_note' => $isInternal,
                'message_id' => $reply->id,
            ]);

            return $reply;
        });

        if ($senderType === 'admin' && ! $isInternal) {
            $this->communications->sendTicketReply($ticket->fresh(), $message);
        }

        return $reply;
    }

    public function transitionStatus(SupportTicket $ticket, string $targetStatus, string $reason, ?int $actorAdminId): SupportTicket
    {
        if (! in_array($targetStatus, SupportTicket::statuses(), true)) {
            throw new InvalidArgumentException('Invalid support ticket status.');
        }

        return DB::transaction(function () use ($ticket, $targetStatus, $reason, $actorAdminId): SupportTicket {
            $locked = SupportTicket::query()->lockForUpdate()->findOrFail($ticket->id);
            $current = $locked->status;

            if (! $this->canTransition($current, $targetStatus, $locked)) {
                throw new InvalidArgumentException("Cannot transition from {$current} to {$targetStatus}.");
            }

            if ($current === SupportTicket::STATUS_RESOLVED && $targetStatus === SupportTicket::STATUS_OPEN) {
                $locked->reopened_count = (int) $locked->reopened_count + 1;
                $locked->resolved_at = null;
                $locked->resolution_summary = null;
                $locked->resolution_breached_at = null;
            }

            if ($targetStatus === SupportTicket::STATUS_RESOLVED) {
                $locked->resolved_at = now();
            }

            if ($targetStatus === SupportTicket::STATUS_CLOSED) {
                $locked->closed_at = now();
            }

            if ($targetStatus === SupportTicket::STATUS_SPAM) {
                $locked->spam_score = max((int) $locked->spam_score, 100);
                $locked->spam_detected_at = now();
            }

            $locked->status = $targetStatus;
            $locked->save();

            $this->recordEvent($locked, 'status_changed', 'admin', $actorAdminId, [
                'from' => $current,
                'to' => $targetStatus,
                'reason' => $reason,
            ]);

            return $locked;
        });
    }

    public function assignTicket(SupportTicket $ticket, ?int $assigneeId, string $reason, ?int $actorAdminId): SupportTicket
    {
        return DB::transaction(function () use ($ticket, $assigneeId, $reason, $actorAdminId): SupportTicket {
            $locked = SupportTicket::query()->lockForUpdate()->findOrFail($ticket->id);
            if ($locked->isTerminal()) {
                throw new InvalidArgumentException('Terminal tickets cannot be reassigned.');
            }
            $before = $locked->assigned_to;
            $locked->assigned_to = $assigneeId;
            if ($locked->status === SupportTicket::STATUS_OPEN && $assigneeId !== null) {
                $locked->status = SupportTicket::STATUS_IN_PROGRESS;
            }
            $locked->save();

            $this->recordEvent($locked, 'assigned', 'admin', $actorAdminId, [
                'from' => $before,
                'to' => $assigneeId,
                'reason' => $reason,
            ]);

            return $locked;
        });
    }

    public function resolveTicket(SupportTicket $ticket, string $summary, ?int $actorAdminId): SupportTicket
    {
        return DB::transaction(function () use ($ticket, $summary, $actorAdminId): SupportTicket {
            $locked = SupportTicket::query()->lockForUpdate()->findOrFail($ticket->id);
            if (! in_array($locked->status, [
                SupportTicket::STATUS_OPEN,
                SupportTicket::STATUS_IN_PROGRESS,
                SupportTicket::STATUS_PENDING_USER,
            ], true)) {
                throw new InvalidArgumentException('Only active tickets can be resolved.');
            }
            $locked->status = SupportTicket::STATUS_RESOLVED;
            $locked->resolved_at = now();
            $locked->resolution_summary = $summary;
            $locked->save();

            $this->recordEvent($locked, 'resolved', 'admin', $actorAdminId, [
                'summary' => $summary,
            ]);

            return $locked;
        });
    }

    public function markEscalated(SupportTicket $ticket, string $reason): void
    {
        DB::transaction(function () use ($ticket, $reason): void {
            $locked = SupportTicket::query()->lockForUpdate()->findOrFail($ticket->id);

            $this->recordEvent($locked, 'sla_escalated', 'system', null, [
                'reason' => $reason,
            ]);

            if ($locked->assignee) {
                $locked->assignee->notify((new SupportTicketEscalatedNotification($locked, $reason))->afterCommit());
                $this->communications->sendTicketEscalation($locked, $reason, $locked->assignee);
            }
        });
    }

    public function mergeInto(SupportTicket $source, SupportTicket $target, string $reason, ?int $actorAdminId): void
    {
        if ($source->id === $target->id) {
            throw new InvalidArgumentException('Cannot merge a ticket into itself.');
        }

        DB::transaction(function () use ($source, $target, $reason, $actorAdminId): void {
            $sourceLocked = SupportTicket::query()->lockForUpdate()->findOrFail($source->id);
            $targetLocked = SupportTicket::query()->lockForUpdate()->findOrFail($target->id);

            if ($sourceLocked->isTerminal()) {
                throw new InvalidArgumentException('Terminal tickets cannot be merged.');
            }
            if ($targetLocked->isTerminal()) {
                throw new InvalidArgumentException('Cannot merge into a terminal ticket.');
            }
            if ($sourceLocked->merged_into_ticket_id !== null) {
                throw new InvalidArgumentException('Source ticket is already merged.');
            }

            $sourceLocked->merged_into_ticket_id = $targetLocked->id;
            $sourceLocked->status = SupportTicket::STATUS_CLOSED;
            $sourceLocked->closed_at = now();
            $sourceLocked->save();

            $this->recordEvent($sourceLocked, 'merged', 'admin', $actorAdminId, [
                'target_ticket_id' => $targetLocked->id,
                'reason' => $reason,
            ]);
        });
    }

    public function splitTicket(SupportTicket $ticket, string $subject, string $description, ?int $actorAdminId): SupportTicket
    {
        return DB::transaction(function () use ($ticket, $subject, $description, $actorAdminId): SupportTicket {
            $locked = SupportTicket::query()->lockForUpdate()->findOrFail($ticket->id);
            if ($locked->isTerminal()) {
                throw new InvalidArgumentException('Terminal tickets cannot be split.');
            }
            if ($locked->merged_into_ticket_id !== null) {
                throw new InvalidArgumentException('Merged tickets cannot be split.');
            }

            $split = SupportTicket::create([
                'ticket_number' => $this->nextTicketNumber(),
                'user_id' => $locked->user_id,
                'requester_name' => $locked->requester_name,
                'requester_email' => $locked->requester_email,
                'requester_phone' => $locked->requester_phone,
                'subject' => $subject,
                'description' => $description,
                'source' => $locked->source,
                'category' => $locked->category,
                'priority' => $locked->priority,
                'status' => SupportTicket::STATUS_OPEN,
                'assigned_to' => $locked->assigned_to,
                'order_id' => $locked->order_id,
                'mikitchn_id' => $locked->mikitchn_id,
                'first_response_due_at' => $this->firstResponseDueAt($locked->priority),
                'resolution_due_at' => $this->resolutionDueAt($locked->priority),
                'requester_token' => Str::random(48),
                'split_from_ticket_id' => $locked->id,
                'last_message_at' => now(),
            ]);

            SupportTicketMessage::create([
                'ticket_id' => $split->id,
                'sender_type' => 'admin',
                'sender_id' => $actorAdminId,
                'message' => $description,
                'is_internal_note' => false,
            ]);

            $this->recordEvent($locked, 'split', 'admin', $actorAdminId, [
                'new_ticket_id' => $split->id,
            ]);

            return $split;
        });
    }

    public function firstResponseDueAt(string $priority): \Carbon\Carbon
    {
        return now()->addMinutes($this->slaConfig($priority)['first_response_minutes']);
    }

    public function resolutionDueAt(string $priority): \Carbon\Carbon
    {
        return now()->addMinutes($this->slaConfig($priority)['resolution_minutes']);
    }

    public function detectSpamScore(array $payload): int
    {
        $score = 0;
        $subject = Str::lower((string) ($payload['subject'] ?? ''));
        $description = Str::lower((string) ($payload['description'] ?? ''));

        foreach (['bitcoin', 'crypto', 'casino', 'loan', 'seo', 'viagra'] as $token) {
            if (Str::contains($subject . ' ' . $description, $token)) {
                $score += 30;
            }
        }

        if (strlen($description) < 8) {
            $score += 25;
        }

        if (preg_match('/https?:\/\//i', $description)) {
            $score += 20;
        }

        return min($score, 100);
    }

    private function normalizePayload(array $payload, string $source): array
    {
        $priority = Str::lower((string) ($payload['priority'] ?? SupportTicket::PRIORITY_NORMAL));
        if (! in_array($priority, SupportTicket::priorities(), true)) {
            $priority = SupportTicket::PRIORITY_NORMAL;
        }

        $spamScore = $this->detectSpamScore($payload);
        $status = $spamScore >= 90 ? SupportTicket::STATUS_SPAM : SupportTicket::STATUS_OPEN;

        return [
            'user_id' => Arr::get($payload, 'user_id'),
            'requester_name' => Arr::get($payload, 'requester_name'),
            'requester_email' => Str::lower(trim((string) Arr::get($payload, 'requester_email', ''))),
            'requester_phone' => Arr::get($payload, 'requester_phone'),
            'subject' => trim((string) Arr::get($payload, 'subject', 'General enquiry')),
            'description' => trim((string) Arr::get($payload, 'description', '')),
            'source' => $source,
            'category' => Str::lower((string) Arr::get($payload, 'category', 'general')),
            'priority' => $priority,
            'status' => $status,
            'assigned_to' => Arr::get($payload, 'assigned_to'),
            'order_id' => Arr::get($payload, 'order_id'),
            'mikitchn_id' => Arr::get($payload, 'mikitchn_id'),
            'first_response_due_at' => $this->firstResponseDueAt($priority),
            'resolution_due_at' => $this->resolutionDueAt($priority),
            'spam_score' => $spamScore,
            'spam_detected_at' => $status === SupportTicket::STATUS_SPAM ? now() : null,
            'actor_type' => Arr::get($payload, 'actor_type', 'system'),
            'actor_id' => Arr::get($payload, 'actor_id'),
        ];
    }

    private function fingerprint(string $email, string $subject, string $description): string
    {
        return hash('sha256', Str::lower($email) . '|' . Str::lower($subject) . '|' . Str::lower(trim($description)));
    }

    private function nextTicketNumber(): string
    {
        return 'TCK-' . now()->format('Ymd') . '-' . Str::upper(Str::random(6));
    }

    private function recordEvent(SupportTicket $ticket, string $type, ?string $actorType, ?int $actorId, ?array $metadata = null): void
    {
        SupportTicketEvent::create([
            'ticket_id' => $ticket->id,
            'event_type' => $type,
            'actor_type' => $actorType,
            'actor_id' => $actorId,
            'metadata' => $metadata,
        ]);
    }

    private function canTransition(string $current, string $target, SupportTicket $ticket): bool
    {
        if ($current === $target) {
            return true;
        }

        $allowed = [
            SupportTicket::STATUS_OPEN => [SupportTicket::STATUS_IN_PROGRESS, SupportTicket::STATUS_PENDING_USER, SupportTicket::STATUS_RESOLVED, SupportTicket::STATUS_SPAM],
            SupportTicket::STATUS_IN_PROGRESS => [SupportTicket::STATUS_PENDING_USER, SupportTicket::STATUS_RESOLVED, SupportTicket::STATUS_OPEN, SupportTicket::STATUS_SPAM],
            SupportTicket::STATUS_PENDING_USER => [SupportTicket::STATUS_IN_PROGRESS, SupportTicket::STATUS_RESOLVED, SupportTicket::STATUS_OPEN, SupportTicket::STATUS_SPAM],
            SupportTicket::STATUS_RESOLVED => [SupportTicket::STATUS_CLOSED, SupportTicket::STATUS_OPEN],
            SupportTicket::STATUS_CLOSED => [],
            SupportTicket::STATUS_SPAM => [],
        ];

        if (! in_array($target, $allowed[$current] ?? [], true)) {
            return false;
        }

        if ($current === SupportTicket::STATUS_RESOLVED && $target === SupportTicket::STATUS_OPEN) {
            $windowHours = (int) config('support.reopen_window_hours', 72);
            if ($ticket->resolved_at === null || $ticket->resolved_at->lt(now()->subHours($windowHours))) {
                return false;
            }
        }

        return true;
    }

    private function slaConfig(string $priority): array
    {
        $default = (array) config('support.sla.default', [
            'first_response_minutes' => 60,
            'resolution_minutes' => 24 * 60,
        ]);

        $priorityOverride = (array) config("support.sla.priority_overrides.{$priority}", []);
        return array_merge($default, $priorityOverride);
    }
}
