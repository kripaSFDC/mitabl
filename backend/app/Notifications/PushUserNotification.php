<?php

namespace App\Notifications;

use App\Models\User;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Notification;

class PushUserNotification extends Notification implements ShouldQueue
{
    use Queueable;

    protected $user;
    protected $msg;
    protected $type;

    public function __construct(User $user, $message, $type)
    {
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
            'message' => $this->msg,
        ];
    }

    public function toArray($notifiable)
    {
        return [];
    }
}
