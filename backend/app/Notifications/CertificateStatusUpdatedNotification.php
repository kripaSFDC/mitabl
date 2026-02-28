<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Notification;

class CertificateStatusUpdatedNotification extends Notification implements ShouldQueue
{
    use Queueable;

    public function __construct(
        private readonly string $status,
        private readonly ?string $reason = null,
        private readonly ?int $certificateId = null
    ) {
    }

    public function via(object $notifiable): array
    {
        return ['database'];
    }

    public function toDatabase(object $notifiable): array
    {
        return [
            'type' => 'certificate_status_updated',
            'status' => $this->status,
            'certificate_id' => $this->certificateId,
            'message' => $this->status === 'approved'
                ? 'Your certificate has been approved.'
                : 'Your certificate has been rejected. Please review feedback and resubmit.',
            'rejection_reason' => $this->reason,
        ];
    }
}
