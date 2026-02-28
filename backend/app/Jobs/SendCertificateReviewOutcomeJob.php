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
        $mailLock = Cache::lock("{$mailKey}:lock", 15);
        $mailLock->block(5, function () use ($mailKey, $recipient, $certificate): void {
            if (Cache::has($mailKey)) {
                return;
            }

            Mail::to($recipient->email)->sendNow(new CertificateApproved($recipient, $certificate));
            Cache::put($mailKey, true, now()->addDays(14));
        });

        $notificationKey = "certificate:approved:db:{$token}";
        $notificationLock = Cache::lock("{$notificationKey}:lock", 15);
        $notificationLock->block(5, function () use ($notificationKey, $recipient, $certificate): void {
            if (Cache::has($notificationKey)) {
                return;
            }

            Notification::sendNow(
                $recipient,
                new CertificateStatusUpdatedNotification('approved', null, $certificate->id)
            );
            Cache::put($notificationKey, true, now()->addDays(14));
        });
    }

    private function sendRejectedNotifications(object $recipient, Certificate $certificate, string $token): void
    {
        $mailKey = "certificate:rejected:mail:{$token}";
        $mailLock = Cache::lock("{$mailKey}:lock", 15);
        $mailLock->block(5, function () use ($mailKey, $recipient, $certificate): void {
            if (Cache::has($mailKey)) {
                return;
            }

            Mail::to($recipient->email)->sendNow(new CertificateRejected($recipient, $certificate));
            Cache::put($mailKey, true, now()->addDays(14));
        });

        $notificationKey = "certificate:rejected:db:{$token}";
        $notificationLock = Cache::lock("{$notificationKey}:lock", 15);
        $notificationLock->block(5, function () use ($notificationKey, $recipient, $certificate): void {
            if (Cache::has($notificationKey)) {
                return;
            }

            Notification::sendNow(
                $recipient,
                new CertificateStatusUpdatedNotification('rejected', $certificate->rejection_reason, $certificate->id)
            );
            Cache::put($notificationKey, true, now()->addDays(14));
        });
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
}
