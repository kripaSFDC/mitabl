<?php

namespace App\Notifications;

use App\Models\Order;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Notification;

class PushOrderNotification extends Notification implements ShouldQueue
{
    use Queueable;

    protected $order;
    protected $msg;
    protected $type;

    public function __construct(Order $order, $message, $type)
    {
        $this->type = $type;
        $this->order = $order;
        $this->msg = $message;
    }

    public function via($notifiable)
    {
        return ['database'];
    }

    public function toDatabase($notifiable = null): array
    {
        return [
            'type' => $this->type,
            'order_id' => $this->order->id,
            'message' => $this->msg,
        ];
    }

    public function toArray($notifiable)
    {
        return [];
    }
}
