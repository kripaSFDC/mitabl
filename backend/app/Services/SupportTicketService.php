<?php

namespace App\Services;

use App\Models\AdminUser;
use App\Models\SupportTicket;
use App\Models\SupportTicketEvent;
use App\Models\SupportTicketMessage;
use App\Notifications\SupportTicketEscalatedNotification;
use Carbon\Carbon;
use Carbon\CarbonInterface;
use Illuminate\Contracts\Cache\LockTimeoutException;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use InvalidArgumentException;

class SupportTicketService
{
    public function __construct(
        private CrmCommunicationService $communications,
        private SupportAttachmentPolicyService $attachmentPolicy
    )
    {
    }

    public function createTicket(array $payload, string $source = 'api'): array
    {
        $normalized = $this->normalizePayload($payload, $source);
        if ($normalized['requester_email'] === '') {
            throw new InvalidArgumentException('Requester email is required.');
        }
        if (! filter_var($normalized['requester_email'], FILTER_VALIDATE_EMAIL)) {
            throw new InvalidArgumentException('Requester email is invalid.');
        }
        if ($normalized['description'] === '') {
            throw new InvalidArgumentException('Ticket description is required.');
        }
        $fingerprint = $this->fingerprint($normalized['requester_email'], $normalized['subject']);
        $dedupeFingerprint = $this->dedupeFingerprint(
            $normalized['requester_email'],
            $normalized['subject'],
            $normalized['description']
        );
        $lockKey = 'support-ticket:create:' . $dedupeFingerprint;
        $lockTtlSeconds = (int) config('support.duplicate_lock_ttl_seconds', 12);
        $lockWaitSeconds = (int) config('support.duplicate_lock_wait_seconds', 3);
        $lock = Cache::lock($lockKey, max(1, $lockTtlSeconds));

        try {
            return $lock->block(max(1, $lockWaitSeconds), function () use ($payload, $normalized, $fingerprint): array {
                if (! ((bool) ($payload['skip_duplicate_check'] ?? false))) {
                    $existing = $this->findRecentDuplicateTicket($normalized['requester_email'], $normalized['subject'], $normalized['description']);
                    if ($existing) {
                        return ['ticket' => $existing, 'duplicate' => true];
                    }
                }

                $ticket = DB::transaction(function () use ($normalized, $fingerprint, $payload): SupportTicket {
                    $ticket = SupportTicket::create([
                        'ticket_number' => 'TKT-PENDING-' . Str::upper(Str::random(8)),
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

                    $ticket->ticket_number = $this->formatTicketNumber((int) $ticket->id);
                    $ticket->save();

                    $message = SupportTicketMessage::create([
                        'ticket_id' => $ticket->id,
                        'sender_type' => 'user',
                        'sender_id' => $ticket->user_id,
                        'message' => $normalized['description'],
                        'is_internal_note' => false,
                    ]);

                    $this->attachmentPolicy->storeForMessage(
                        $ticket,
                        $message,
                        $this->extractUploadedFiles($payload['attachments'] ?? []),
                        $normalized['actor_type'],
                        $normalized['actor_id']
                    );

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
            });
        } catch (LockTimeoutException) {
            $existing = $this->findRecentDuplicateTicket($normalized['requester_email'], $normalized['subject'], $normalized['description']);
            if ($existing) {
                return ['ticket' => $existing, 'duplicate' => true];
            }

            throw new InvalidArgumentException('A similar message is already being processed. Please retry in a few seconds.');
        }
    }

    public function addReply(SupportTicket $ticket, array $payload, string $senderType, ?int $senderId = null, ?string $expectedUpdatedAt = null): SupportTicketMessage
    {
        $message = trim((string) ($payload['message'] ?? ''));
        if ($message === '') {
            throw new InvalidArgumentException('Reply message is required.');
        }
        $reopenReason = trim((string) ($payload['reopen_reason'] ?? ''));

        $isInternal = (bool) ($payload['is_internal_note'] ?? false);

        $reply = DB::transaction(function () use ($ticket, $senderType, $senderId, $message, $isInternal, $reopenReason, $expectedUpdatedAt, $payload): SupportTicketMessage {
            $locked = SupportTicket::query()->lockForUpdate()->findOrFail($ticket->id);
            $this->guardAgainstCollision($locked, $expectedUpdatedAt);
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

            $this->attachmentPolicy->storeForMessage(
                $locked,
                $reply,
                $this->extractUploadedFiles($payload['attachments'] ?? []),
                $senderType,
                $senderId
            );

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

    public function transitionStatus(SupportTicket $ticket, string $targetStatus, string $reason, ?int $actorAdminId, ?string $expectedUpdatedAt = null): SupportTicket
    {
        if (! in_array($targetStatus, SupportTicket::statuses(), true)) {
            throw new InvalidArgumentException('Invalid support ticket status.');
        }

        $reason = trim($reason);

        return DB::transaction(function () use ($ticket, $targetStatus, $reason, $actorAdminId, $expectedUpdatedAt): SupportTicket {
            $locked = SupportTicket::query()->lockForUpdate()->findOrFail($ticket->id);
            $this->guardAgainstCollision($locked, $expectedUpdatedAt);
            $current = $locked->status;

            if (! $this->canTransition($current, $targetStatus, $locked)) {
                throw new InvalidArgumentException("Cannot transition from {$current} to {$targetStatus}.");
            }

            if ($targetStatus === SupportTicket::STATUS_RESOLVED) {
                throw new InvalidArgumentException('Use resolve action and provide a resolution summary.');
            }

            if ($targetStatus === SupportTicket::STATUS_CLOSED && trim((string) $locked->resolution_summary) === '') {
                throw new InvalidArgumentException('A resolution summary is required before closing a ticket.');
            }

            if ($current === SupportTicket::STATUS_RESOLVED && $targetStatus === SupportTicket::STATUS_OPEN) {
                if ($reason === '') {
                    throw new InvalidArgumentException('Reopen reason is required.');
                }

                $locked->reopened_count = (int) $locked->reopened_count + 1;
                $locked->resolved_at = null;
                $locked->resolution_summary = null;
                $locked->resolution_breached_at = null;
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

    public function assignTicket(SupportTicket $ticket, ?int $assigneeId, string $reason, ?int $actorAdminId, ?string $expectedUpdatedAt = null): SupportTicket
    {
        $reason = trim($reason);
        if ($reason === '') {
            throw new InvalidArgumentException('Assignment reason is required.');
        }

        return DB::transaction(function () use ($ticket, $assigneeId, $reason, $actorAdminId, $expectedUpdatedAt): SupportTicket {
            $locked = SupportTicket::query()->lockForUpdate()->findOrFail($ticket->id);
            $this->guardAgainstCollision($locked, $expectedUpdatedAt);
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

    public function resolveTicket(SupportTicket $ticket, string $summary, ?int $actorAdminId, ?string $expectedUpdatedAt = null): SupportTicket
    {
        return DB::transaction(function () use ($ticket, $summary, $actorAdminId, $expectedUpdatedAt): SupportTicket {
            $locked = SupportTicket::query()->lockForUpdate()->findOrFail($ticket->id);
            $this->guardAgainstCollision($locked, $expectedUpdatedAt);
            if (! in_array($locked->status, [
                SupportTicket::STATUS_OPEN,
                SupportTicket::STATUS_IN_PROGRESS,
                SupportTicket::STATUS_PENDING_USER,
            ], true)) {
                throw new InvalidArgumentException('Only active tickets can be resolved.');
            }
            $summary = trim($summary);
            if ($summary === '') {
                throw new InvalidArgumentException('Resolution summary is required.');
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
            }

            // Always route escalation mail; service will fall back to configured operations mailbox.
            $this->communications->sendTicketEscalation($locked, $reason, $locked->assignee);
        });
    }

    public function mergeInto(
        SupportTicket $source,
        SupportTicket $target,
        string $reason,
        ?int $actorAdminId,
        ?string $expectedSourceUpdatedAt = null,
        ?string $expectedTargetUpdatedAt = null
    ): void
    {
        if ($source->id === $target->id) {
            throw new InvalidArgumentException('Cannot merge a ticket into itself.');
        }

        DB::transaction(function () use ($source, $target, $reason, $actorAdminId, $expectedSourceUpdatedAt, $expectedTargetUpdatedAt): void {
            $sourceLocked = SupportTicket::query()->lockForUpdate()->findOrFail($source->id);
            $targetLocked = SupportTicket::query()->lockForUpdate()->findOrFail($target->id);
            $this->guardAgainstCollision($sourceLocked, $expectedSourceUpdatedAt);
            $this->guardAgainstCollision($targetLocked, $expectedTargetUpdatedAt);

            if ($sourceLocked->isTerminal()) {
                throw new InvalidArgumentException('Terminal tickets cannot be merged.');
            }
            if ($targetLocked->isTerminal()) {
                throw new InvalidArgumentException('Cannot merge into a terminal ticket.');
            }
            if ($sourceLocked->merged_into_ticket_id !== null) {
                throw new InvalidArgumentException('Source ticket is already merged.');
            }

            $sourceLocked->messages()->update(['ticket_id' => $targetLocked->id]);
            $sourceLocked->attachments()->update(['ticket_id' => $targetLocked->id]);

            $sourceLocked->merged_into_ticket_id = $targetLocked->id;
            $sourceLocked->status = SupportTicket::STATUS_CLOSED;
            $sourceLocked->closed_at = now();
            $sourceLocked->save();

            $this->recordEvent($sourceLocked, 'merged', 'admin', $actorAdminId, [
                'target_ticket_id' => $targetLocked->id,
                'reason' => $reason,
            ]);
            $this->recordEvent($targetLocked, 'merge_received', 'admin', $actorAdminId, [
                'source_ticket_id' => $sourceLocked->id,
                'reason' => $reason,
            ]);
        });
    }

    public function splitTicket(
        SupportTicket $ticket,
        string $subject,
        string $description,
        ?int $actorAdminId,
        ?string $expectedUpdatedAt = null
    ): SupportTicket
    {
        return DB::transaction(function () use ($ticket, $subject, $description, $actorAdminId, $expectedUpdatedAt): SupportTicket {
            $locked = SupportTicket::query()->lockForUpdate()->findOrFail($ticket->id);
            $this->guardAgainstCollision($locked, $expectedUpdatedAt);
            if ($locked->isTerminal()) {
                throw new InvalidArgumentException('Terminal tickets cannot be split.');
            }
            if ($locked->merged_into_ticket_id !== null) {
                throw new InvalidArgumentException('Merged tickets cannot be split.');
            }

            $split = SupportTicket::create([
                'ticket_number' => 'TKT-PENDING-' . Str::upper(Str::random(8)),
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

            $split->ticket_number = $this->formatTicketNumber((int) $split->id);
            $split->save();

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

    public function updateClassification(
        SupportTicket $ticket,
        ?string $priority,
        ?string $category,
        string $reason,
        ?int $actorAdminId,
        ?string $expectedUpdatedAt = null
    ): SupportTicket {
        return DB::transaction(function () use ($ticket, $priority, $category, $reason, $actorAdminId, $expectedUpdatedAt): SupportTicket {
            $locked = SupportTicket::query()->lockForUpdate()->findOrFail($ticket->id);
            $this->guardAgainstCollision($locked, $expectedUpdatedAt);
            if ($locked->isTerminal()) {
                throw new InvalidArgumentException('Terminal tickets cannot be reclassified.');
            }

            $newPriority = $this->normalizePriority($priority ?? $locked->priority);
            $newCategory = $this->normalizeCategory($category ?? $locked->category);

            $before = [
                'priority' => $locked->priority,
                'category' => $locked->category,
            ];

            $locked->priority = $newPriority;
            $locked->category = $newCategory;

            if ($locked->first_responded_at === null) {
                $locked->first_response_due_at = $this->firstResponseDueAt($newPriority);
            }
            if ($locked->resolved_at === null) {
                $locked->resolution_due_at = $this->resolutionDueAt($newPriority);
            }

            $locked->save();

            $this->recordEvent($locked, 'classification_changed', 'admin', $actorAdminId, [
                'from' => $before,
                'to' => [
                    'priority' => $newPriority,
                    'category' => $newCategory,
                ],
                'reason' => $reason,
            ]);

            return $locked;
        });
    }

    private function normalizePayload(array $payload, string $source): array
    {
        $priority = $this->normalizePriority((string) ($payload['priority'] ?? SupportTicket::PRIORITY_NORMAL));
        $category = $this->normalizeCategory((string) Arr::get($payload, 'category', SupportTicket::CATEGORY_GENERAL));
        $assignedTo = $this->resolveAutoAssignee($category, $priority, Arr::get($payload, 'assigned_to'));

        $spamScore = $this->detectSpamScore($payload);
        $status = $spamScore >= 90
            ? SupportTicket::STATUS_SPAM
            : ($assignedTo !== null ? SupportTicket::STATUS_IN_PROGRESS : SupportTicket::STATUS_OPEN);

        return [
            'user_id' => Arr::get($payload, 'user_id'),
            'requester_name' => Arr::get($payload, 'requester_name'),
            'requester_email' => Str::lower(trim((string) Arr::get($payload, 'requester_email', ''))),
            'requester_phone' => $this->normalizePhone(Arr::get($payload, 'requester_phone')),
            'subject' => trim((string) Arr::get($payload, 'subject', 'General enquiry')),
            'description' => trim((string) Arr::get($payload, 'description', '')),
            'source' => $this->normalizeSource($source, $payload),
            'category' => $category,
            'priority' => $priority,
            'status' => $status,
            'assigned_to' => $assignedTo,
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


    private function resolveAutoAssignee(string $category, string $priority, mixed $explicitAssignee): ?int
    {
        if ($explicitAssignee !== null && $explicitAssignee !== '') {
            return (int) $explicitAssignee;
        }

        $candidate = config("support.routing.rules.priority.{$priority}")
            ?? config("support.routing.rules.category.{$category}")
            ?? config('support.routing.default_assignee_id');

        if ($candidate === null || $candidate === '') {
            return null;
        }

        $assigneeId = (int) $candidate;
        if ($assigneeId <= 0) {
            return null;
        }

        $isActive = AdminUser::query()
            ->whereKey($assigneeId)
            ->where('is_active', true)
            ->exists();

        return $isActive ? $assigneeId : null;
    }

    private function fingerprint(string $email, string $subject): string
    {
        return hash('sha256', Str::lower($email) . '|' . Str::lower(trim($subject)));
    }

    private function dedupeFingerprint(string $email, string $subject, string $description): string
    {
        return hash(
            'sha256',
            Str::lower(trim($email))
            . '|'
            . Str::lower(trim($subject))
            . '|'
            . Str::lower(trim($description))
        );
    }

    private function findRecentDuplicateTicket(string $email, string $subject, string $description): ?SupportTicket
    {
        $duplicateWindowMinutes = (int) config('support.duplicate_window_minutes', 10);
        $subjectFingerprint = Str::lower(trim($subject));
        $descriptionFingerprint = Str::lower(trim($description));

        return SupportTicket::query()
            ->where('requester_email', Str::lower(trim($email)))
            ->where('created_at', '>=', now()->subMinutes($duplicateWindowMinutes))
            ->whereNull('merged_into_ticket_id')
            ->whereRaw('LOWER(TRIM(subject)) = ?', [$subjectFingerprint])
            ->whereRaw('LOWER(TRIM(description)) = ?', [$descriptionFingerprint])
            ->latest('id')
            ->first();
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

    private function normalizePriority(string $priority): string
    {
        $normalized = Str::lower(trim($priority));
        if (! in_array($normalized, SupportTicket::priorities(), true)) {
            return SupportTicket::PRIORITY_NORMAL;
        }

        return $normalized;
    }

    private function normalizeCategory(string $category): string
    {
        $normalized = Str::lower(trim($category));
        $map = [
            'order' => SupportTicket::CATEGORY_ORDER_DISPUTE,
            'order_dispute' => SupportTicket::CATEGORY_ORDER_DISPUTE,
            'payment' => SupportTicket::CATEGORY_PAYMENT,
            'account' => SupportTicket::CATEGORY_ACCOUNT,
            'general' => SupportTicket::CATEGORY_GENERAL,
            'kitchen' => SupportTicket::CATEGORY_OTHER,
            'certificate' => SupportTicket::CATEGORY_OTHER,
            'other' => SupportTicket::CATEGORY_OTHER,
        ];

        $mapped = $map[$normalized] ?? SupportTicket::CATEGORY_GENERAL;
        if (! in_array($mapped, SupportTicket::categories(), true)) {
            return SupportTicket::CATEGORY_GENERAL;
        }

        return $mapped;
    }

    private function normalizeSource(string $source, array $payload = []): string
    {
        $normalized = Str::lower(trim($source));
        $map = [
            'api' => SupportTicket::SOURCE_WEBSITE,
            'admin_panel' => SupportTicket::SOURCE_ADMIN,
            SupportTicket::SOURCE_WEBSITE => SupportTicket::SOURCE_WEBSITE,
            SupportTicket::SOURCE_MOBILE_APP => SupportTicket::SOURCE_MOBILE_APP,
            SupportTicket::SOURCE_ADMIN => SupportTicket::SOURCE_ADMIN,
        ];

        if ($normalized === 'public_api') {
            $authenticatedChannel = Str::lower(trim((string) Arr::get($payload, 'authenticated_channel', '')));
            if (in_array($authenticatedChannel, [SupportTicket::SOURCE_WEBSITE, SupportTicket::SOURCE_MOBILE_APP], true)) {
                return $authenticatedChannel;
            }

            $authenticatedGuard = Str::lower(trim((string) Arr::get($payload, 'authenticated_guard', '')));
            if ($authenticatedGuard === 'admin') {
                return SupportTicket::SOURCE_ADMIN;
            }
            if ($authenticatedGuard === 'api') {
                return SupportTicket::SOURCE_MOBILE_APP;
            }

            throw new InvalidArgumentException('Support ticket source "public_api" is ambiguous. Provide an explicit source or authenticated channel context.');
        }

        return $map[$normalized] ?? SupportTicket::SOURCE_WEBSITE;
    }

    private function normalizePhone(mixed $value): ?string
    {
        if (! is_string($value) && ! is_numeric($value)) {
            return null;
        }

        $raw = trim((string) $value);
        if ($raw === '') {
            return null;
        }

        $hasPlus = str_starts_with($raw, '+');
        $digits = preg_replace('/\D+/', '', $raw) ?? '';
        if ($digits === '') {
            return null;
        }

        return $hasPlus ? '+' . $digits : $digits;
    }

    private function guardAgainstCollision(SupportTicket $locked, ?string $expectedUpdatedAt): void
    {
        if ($expectedUpdatedAt === null || $expectedUpdatedAt === '') {
            return;
        }

        try {
            $expected = Carbon::parse($expectedUpdatedAt);
        } catch (\Throwable) {
            throw new InvalidArgumentException('Invalid ticket version received.');
        }

        if ($locked->updated_at instanceof CarbonInterface && $locked->updated_at->gt($expected)) {
            throw new InvalidArgumentException('Ticket was updated by another agent. Refresh and retry.');
        }
    }

    private function formatTicketNumber(int $ticketId): string
    {
        return 'TKT-' . str_pad((string) $ticketId, 6, '0', STR_PAD_LEFT);
    }

    private function isSimilarSubject(string $existingSubject, string $incomingSubject): bool
    {
        $left = $this->normalizeSubject($existingSubject);
        $right = $this->normalizeSubject($incomingSubject);
        if ($left === '' || $right === '') {
            return false;
        }

        similar_text($left, $right, $percent);
        return $percent >= 85.0;
    }

    private function normalizeSubject(string $subject): string
    {
        $subject = Str::lower(trim($subject));
        $subject = (string) preg_replace('/\s+/', ' ', $subject);
        return (string) preg_replace('/[^a-z0-9 ]/', '', $subject);
    }

    private function extractUploadedFiles(mixed $attachments): array
    {
        if (! is_array($attachments)) {
            return [];
        }

        return array_values(array_filter($attachments, static fn ($file): bool => $file instanceof \Illuminate\Http\UploadedFile || is_string($file)));
    }
}
