<?php

namespace App\Observers;

use App\Models\Order;
use App\Models\Mikitchn;
use App\Mail\Invoice;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Notification;
use App\Notifications\PushOrderNotification;
use Carbon\Carbon;
use Throwable;

class OrderObserver
{
    /**
     * Handle the Order "created" event.
     *
     * @param  \App\Models\Order  $order
     * @return void
     */
    public function created(Order $order)
    {
        $order->loadMissing(['user', 'Mikitchn.user']);
        $kitchenUser = $order->Mikitchn?->user ?? optional(Mikitchn::find($order->mikitchn_id))->user;
        if (! $kitchenUser) {
            return;
        }

        $this->safeSendNotification(
            $kitchenUser,
            new PushOrderNotification(
                $order,
                'New order request from '.$this->customerDisplayName($order).'!',
                1
            ),
            'orders.kitchen_notification_failed',
            [
                'order_id' => $order->id,
                'recipient_id' => $kitchenUser->id,
                'status' => $order->status,
                'event' => 'created',
            ]
        );
    }

    /**
     * Handle the Order "updated" event.
     *
     * @param  \App\Models\Order  $order
     * @return void
     */
    public function updated(Order $order)
    {
        if (! $order->wasChanged('status')) {
            return;
        }

        $order->loadMissing(['user', 'cancelreason', 'Mikitchn.user']);

        $newStatus = (int) $order->status;
        $kitchenUser = $order->Mikitchn?->user ?? optional(Mikitchn::find($order->mikitchn_id))->user;
        $foodie = $order->user;

        foreach ($this->statusNotifications($order, $newStatus, $foodie, $kitchenUser) as $notification) {
            $this->safeSendNotification(
                $notification['recipient'],
                new PushOrderNotification($order, $notification['message'], $notification['type']),
                $notification['log_event'],
                [
                    'order_id' => $order->id,
                    'recipient_id' => $notification['recipient']->id,
                    'status' => $newStatus,
                ]
            );
        }

        if ($newStatus === Order::STATUS_COMPLETED) {
            if ($foodie?->email) {
                $this->safeQueueMail($foodie->email, new Invoice($foodie, $order, 1), 'orders.customer_invoice_failed', [
                    'order_id' => $order->id,
                    'recipient' => $foodie->email,
                ]);
            }

            if ($kitchenUser?->email) {
                $this->safeQueueMail($kitchenUser->email, new Invoice($foodie, $order, 0), 'orders.kitchen_invoice_failed', [
                    'order_id' => $order->id,
                    'recipient' => $kitchenUser->email,
                ]);
            }
        }
    }

    /**
     * Handle the Order "updating" event.
     *
     * @param  \App\Models\Order  $order
     * @return void
     */
    public function updating(Order $order)
    {
        //
    }

    /**
     * Handle the Order "deleted" event.
     *
     * @param  \App\Models\Order  $order
     * @return void
     */
    public function deleted(Order $order)
    {
        //
    }

    /**
     * Handle the Order "restored" event.
     *
     * @param  \App\Models\Order  $order
     * @return void
     */
    public function restored(Order $order)
    {
        //
    }

    /**
     * Handle the Order "force deleted" event.
     *
     * @param  \App\Models\Order  $order
     * @return void
     */
    public function forceDeleted(Order $order)
    {
        //
    }

    private function safeSendNotification(mixed $notifiables, object $notification, string $logEvent, array $context = []): void
    {
        try {
            if (method_exists($notification, 'afterCommit')) {
                $notification->afterCommit();
            }

            Notification::send($notifiables, $notification);
        } catch (Throwable $throwable) {
            Log::error($logEvent, $context + [
                'error' => $throwable->getMessage(),
            ]);
        }
    }

    private function safeQueueMail(string $recipient, object $mailable, string $logEvent, array $context = []): void
    {
        try {
            Mail::to($recipient)->queue(method_exists($mailable, 'afterCommit') ? $mailable->afterCommit() : $mailable);
        } catch (Throwable $throwable) {
            Log::error($logEvent, $context + [
                'error' => $throwable->getMessage(),
            ]);
        }
    }

    private function fulfillmentLabel(Order $order): string
    {
        return (int) $order->dine_in === 1 ? 'dine-in' : 'pick-up';
    }

    private function fulfillmentWindow(Order $order): string
    {
        $date = Carbon::parse((string) $order->delivery_date)->format('d M Y');
        $from = Carbon::parse((string) $order->delivery_time_from)->format('H:i');
        $to = Carbon::parse((string) $order->delivery_time_to)->format('H:i');

        return $this->fulfillmentLabel($order).' between '.$date.' '.$from.'-'.$to;
    }

    private function customerDisplayName(Order $order): string
    {
        $firstName = trim((string) $order->user?->first_name);
        $lastName = trim((string) $order->user?->last_name);
        $fullName = trim($firstName.' '.$lastName);

        return $fullName !== '' ? $fullName : 'miFoodi';
    }

    private function pickupOrDineIn(Order $order): string
    {
        return (int) $order->dine_in === 1 ? 'dine-in' : 'pickup';
    }

    private function confirmationTime(Order $order): string
    {
        $date = Carbon::parse((string) $order->delivery_date)->format('d M Y');
        $from = Carbon::parse((string) $order->delivery_time_from)->format('H:i');
        $to = Carbon::parse((string) $order->delivery_time_to)->format('H:i');

        return $date.' '.$from.'-'.$to;
    }

    private function wasCancelledByCustomer(Order $order): bool
    {
        return $order->cancelreason?->by_user === 'customer';
    }

    private function statusNotifications(Order $order, int $newStatus, $foodie, $kitchenUser): array
    {
        return match ($newStatus) {
            Order::STATUS_CONFIRMED => $foodie ? [[
                'recipient' => $foodie,
                'message' => 'Your order is confirmed! Come at '.$this->confirmationTime($order).'.',
                'type' => 2,
                'log_event' => 'orders.user_notification_failed',
            ]] : [],
            Order::STATUS_LEGACY_CANCELLED, Order::STATUS_CANCELLED => $this->wasCancelledByCustomer($order)
                ? ($kitchenUser ? [[
                    'recipient' => $kitchenUser,
                    'message' => 'Order cancelled by customer.',
                    'type' => 3,
                    'log_event' => 'orders.kitchen_notification_failed',
                ]] : [])
                : ($foodie ? [[
                    'recipient' => $foodie,
                    'message' => 'Your order was declined. Full refund initiated.',
                    'type' => 4,
                    'log_event' => 'orders.user_notification_failed',
                ]] : []),
            Order::STATUS_IN_PROGRESS => $foodie ? [[
                'recipient' => $foodie,
                'message' => 'Your meal is ready for '.$this->pickupOrDineIn($order).'.',
                'type' => 2,
                'log_event' => 'orders.user_notification_failed',
            ]] : [],
            Order::STATUS_COMPLETED => array_values(array_filter([
                $foodie ? [
                    'recipient' => $foodie,
                    'message' => 'Thanks for using mitabl! Leave a review.',
                    'type' => 5,
                    'log_event' => 'orders.user_notification_failed',
                ] : null,
                $kitchenUser ? [
                    'recipient' => $kitchenUser,
                    'message' => 'Thanks for using mitabl! Leave a review.',
                    'type' => 5,
                    'log_event' => 'orders.kitchen_notification_failed',
                ] : null,
            ])),
            default => [],
        };
    }
}
