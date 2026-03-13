<?php

namespace App\Jobs;

use App\Mail\CertificateApproved;
use App\Mail\CertificateRejected;
use App\Models\Certificate;
use App\Notifications\CertificateStatusUpdatedNotification;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Notification;
use Throwable;

class SendCertificateReviewOutcomeJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 5;

    public int $backoff = 10;

    public function __construct(
        public int $certificateId
    ) {
        $this->onQueue('default');
    }

    public function handle(): void
    {
        $certificate = Certificate::query()->with(['mikitchn.user'])->find($this->certificateId);
        if (! $certificate) {
            return;
        }

        $recipient = optional($certificate->mikitchn)->user;
        if (! $recipient || ! $recipient->email) {
            return;
        }

        $status = (int) $certificate->status;
        if (! in_array($status, [1, 2], true)) {
            return;
        }

        $token = $this->decisionToken($certificate);

        if ($status === 1) {
            $this->sendApprovedNotifications($recipient, $certificate, $token);

            return;
        }

        $this->sendRejectedNotifications($recipient, $certificate, $token);
    }

    private function sendApprovedNotifications(object $recipient, Certificate $certificate, string $token): void
    {
        $mailKey = "certificate:approved:mail:{$token}";
        $this->safeLockedDelivery("{$mailKey}:lock", function () use ($mailKey, $recipient, $certificate): void {
            if (Cache::has($mailKey)) {
                return;
            }

            Mail::to($recipient->email)->sendNow(new CertificateApproved($recipient, $certificate));
            Cache::put($mailKey, true, now()->addDays(14));
        }, 'certificates.approved_mail_failed', [
            'certificate_id' => $certificate->id,
            'recipient' => $recipient->email,
        ]);

        $notificationKey = "certificate:approved:db:{$token}";
        $this->safeLockedDelivery("{$notificationKey}:lock", function () use ($notificationKey, $recipient, $certificate): void {
            if (Cache::has($notificationKey)) {
                return;
            }

            Notification::sendNow(
                $recipient,
                new CertificateStatusUpdatedNotification('approved', null, $certificate->id)
            );
            Cache::put($notificationKey, true, now()->addDays(14));
        }, 'certificates.approved_notification_failed', [
            'certificate_id' => $certificate->id,
            'recipient_id' => $recipient->id ?? null,
        ]);
    }

    private function sendRejectedNotifications(object $recipient, Certificate $certificate, string $token): void
    {
        $mailKey = "certificate:rejected:mail:{$token}";
        $this->safeLockedDelivery("{$mailKey}:lock", function () use ($mailKey, $recipient, $certificate): void {
            if (Cache::has($mailKey)) {
                return;
            }

            Mail::to($recipient->email)->sendNow(new CertificateRejected($recipient, $certificate));
            Cache::put($mailKey, true, now()->addDays(14));
        }, 'certificates.rejected_mail_failed', [
            'certificate_id' => $certificate->id,
            'recipient' => $recipient->email,
        ]);

        $notificationKey = "certificate:rejected:db:{$token}";
        $this->safeLockedDelivery("{$notificationKey}:lock", function () use ($notificationKey, $recipient, $certificate): void {
            if (Cache::has($notificationKey)) {
                return;
            }

            Notification::sendNow(
                $recipient,
                new CertificateStatusUpdatedNotification('rejected', $certificate->rejection_reason, $certificate->id)
            );
            Cache::put($notificationKey, true, now()->addDays(14));
        }, 'certificates.rejected_notification_failed', [
            'certificate_id' => $certificate->id,
            'recipient_id' => $recipient->id ?? null,
        ]);
    }

    private function decisionToken(Certificate $certificate): string
    {
        return implode(':', [
            $certificate->id,
            (int) $certificate->status,
            (string) optional($certificate->reviewed_at)->toISOString(),
        ]);
    }

    public function failed(Throwable $exception): void
    {
        report($exception);
    }

    private function safeLockedDelivery(string $lockKey, callable $callback, string $logEvent, array $context = []): void
    {
        try {
            Cache::lock($lockKey, 15)->block(5, $callback);
        } catch (Throwable $throwable) {
            Log::error($logEvent, $context + [
                'error' => $throwable->getMessage(),
            ]);
        }
    }
}
