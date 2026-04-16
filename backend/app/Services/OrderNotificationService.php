<?php

namespace App\Services;

use App\Http\Controllers\Api\FcmController;
use App\Models\Order;
use App\Models\User;
use App\Notifications\OrderStatusNotification;
use Illuminate\Support\Facades\Log;

class OrderNotificationService
{
    public function notifyTransition(Order $order, int $newStatus, ?string $cancelSubject = null): void
    {
        [$recipient, $title, $body] = $this->resolveNotification($order, $newStatus, $cancelSubject);

        if ($recipient === null) {
            return;
        }

        $deviceToken = trim((string) ($recipient->device_token ?? ''));
        if ($deviceToken !== '') {
            try {
                $fcm = new FcmController();
                $fcm->sendTo(
                    [$deviceToken],
                    $title,
                    $body,
                    null,
                    ['order_id' => $order->id, 'status' => $newStatus]
                );
            } catch (\Throwable $e) {
                Log::warning('FCM push failed for order notification', [
                    'order_id' => $order->id,
                    'status' => $newStatus,
                    'error' => $e->getMessage(),
                ]);
            }
        } else {
            Log::info('Skipping FCM push — recipient has no device_token', [
                'order_id' => $order->id,
                'recipient_id' => $recipient->id,
            ]);
        }

        try {
            $recipient->notify(new OrderStatusNotification($order, $newStatus, $title, $body));
        } catch (\Throwable $e) {
            Log::warning('Database notification failed for order', [
                'order_id' => $order->id,
                'error' => $e->getMessage(),
            ]);
        }
    }

    /**
     * @return array{0: User|null, 1: string, 2: string}
     */
    private function resolveNotification(Order $order, int $newStatus, ?string $cancelSubject): array
    {
        $cook = $order->mikitchn ? User::find($order->mikitchn->user_id) : null;
        $foodie = User::find($order->user_id);
        $kitchenName = $order->mikitchn ? $order->mikitchn->name : 'the kitchen';
        $orderType = $order->dine_in ? 'dine-in' : 'take-away';
        $orderId = $order->id;

        switch ($newStatus) {
            case Order::STATUS_REQUESTED:
                return [
                    $cook,
                    'New Order Received',
                    "You have a new {$orderType} order #{$orderId}.",
                ];

            case Order::STATUS_CONFIRMED:
                return [
                    $foodie,
                    'Order Confirmed',
                    "Your order #{$orderId} has been accepted by {$kitchenName}.",
                ];

            case Order::STATUS_CANCELLED:
                $reason = $cancelSubject ?? 'No reason provided';
                if ($order->user_id === (int) ($order->cancelled_by ?? $order->user_id)) {
                    // Foodie cancelled — notify cook
                    return [
                        $cook,
                        'Order Cancelled',
                        "Order #{$orderId} was cancelled by the customer. Reason: {$reason}.",
                    ];
                }
                // Cook cancelled — notify foodie
                return [
                    $foodie,
                    'Order Cancelled',
                    "Your order #{$orderId} was cancelled by {$kitchenName}. Reason: {$reason}.",
                ];

            case Order::STATUS_IN_PROGRESS:
                return [
                    $foodie,
                    'Order In Progress',
                    "Your order #{$orderId} is now being prepared.",
                ];

            case Order::STATUS_READY:
                $pickupType = $order->dine_in ? 'dine-in' : 'pickup';
                return [
                    $foodie,
                    'Order Ready',
                    "Your order #{$orderId} is ready for {$pickupType}!",
                ];

            case Order::STATUS_COMPLETED:
                return [
                    $foodie,
                    'Order Completed',
                    "Your order #{$orderId} is complete. Leave a review!",
                ];

            default:
                return [null, '', ''];
        }
    }
}
