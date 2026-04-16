<?php

namespace App\Notifications;

use App\Models\Order;
use Illuminate\Notifications\Notification;

class OrderStatusNotification extends Notification
{
    public function __construct(
        private Order $order,
        private int $status,
        private string $title,
        private string $body
    ) {}

    public function via(mixed $notifiable): array
    {
        return ['database'];
    }

    public function toArray(mixed $notifiable): array
    {
        return [
            'order_id' => $this->order->id,
            'status' => $this->status,
            'title' => $this->title,
            'body' => $this->body,
            'kitchen_name' => $this->order->mikitchn ? $this->order->mikitchn->name : null,
        ];
    }
}
