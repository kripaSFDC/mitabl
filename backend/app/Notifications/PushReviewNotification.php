<?php

namespace App\Notifications;

use App\Models\User;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Notification;

class PushReviewNotification extends Notification
{
    use Queueable;

    protected $user;
    protected $msg;
    protected $review;
    protected $type;

    public function __construct(User $user, $message, $review, $type)
    {
        $this->review = $review;
        $this->type = $type;
        $this->user = $user;
        $this->msg = $message;
    }

    public function via($notifiable)
    {
        return ['database'];
    }

    public function toDatabase()
    {
        return [
            'type' => $this->type,
            'order_id' => $this->review->order_id,
            'message' => $this->msg,
        ];
    }

    public function toArray($notifiable)
    {
        return [];
    }
}
