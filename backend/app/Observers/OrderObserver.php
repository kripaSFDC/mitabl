<?php

namespace App\Observers;

use App\Models\Order;
use App\Models\Mikitchn;
use App\Models\User;
use App\Models\CancelReason;
use App\Mail\Invoice;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Notification;
use App\Notifications\PushOrderNotification;
use Carbon\Carbon;
use Throwable;
use Auth;

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
        $kitchenUser = optional(Mikitchn::find($order->mikitchn_id))->user;
        if (! $kitchenUser) {
            return;
        }

        $this->safeSendNotification(
            $kitchenUser,
            new PushOrderNotification(
                $order,
                'New '.$this->fulfillmentLabel($order).' order '.$order->order_id.' requested for '.$this->fulfillmentWindow($order).'.',
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
        
        // if($order->isDirty('status')){
        //     // email has changed
        //     $new_status = $order->status; 
        //     $old_status = $order->getOriginal('status'); 
        // }
    }

    /**
     * Handle the Order "updating" event.
     *
     * @param  \App\Models\Order  $order
     * @return void
     */
    public function updating(Order $order)
    {
        $user_id = $order->user_id;

        $user = User::where('id', $user_id)->get();
        $kitchenUser = optional(Mikitchn::find($order->mikitchn_id))->user;
        $actor = Auth::user();
        $actorRoleId = (int) optional($actor)->role_id;
        if($order->isDirty('status')){
            // email has changed
            $new_status = $order->status; 
            $old_status = $order->getOriginal('status');
            
            switch ($new_status) {
                case Order::STATUS_LEGACY_CANCELLED:
                case Order::STATUS_CANCELLED:
                    if ($actorRoleId === 3) {
                        $type = 3;
                        $sMsg = 'Order '.$order->order_id.' was cancelled by miFoodi.';
                        $user = $kitchenUser ? collect([$kitchenUser]) : collect();
                    } else {
                        $type = 4;
                        $sMsg = 'Your order '.$order->order_id.' was cancelled by miCook.';
                    }

                    break;
                case Order::STATUS_COMPLETED:
                    $type = 5;
                    $sMsg = 'Your order '.$order->order_id.' is completed.';
                    break;
                case Order::STATUS_REQUESTED:
                    $type = 1;
                    $sMsg = '';
                    break;
                case Order::STATUS_CONFIRMED:
                    $type = 2;
                    $sMsg = 'Your order '.$order->order_id.' is confirmed for '.$this->fulfillmentWindow($order).'.';
                    break;
                case Order::STATUS_IN_PROGRESS:
                    $type = 2;
                    $sMsg = 'Your order '.$order->order_id.' is now in progress for '.$this->fulfillmentWindow($order).'.';
                    break;
                
                default:
                    $type = 4;
                    $sMsg = '';
                    break;
            }
            // die('jkfkd');
            if ((int) $new_status === Order::STATUS_REQUESTED) {
                $kMsg = 'New '.$this->fulfillmentLabel($order).' order '.$order->order_id.' requested for '.$this->fulfillmentWindow($order).'.';

                
                
                if ($kitchenUser) {
                    $this->safeSendNotification($kitchenUser, new PushOrderNotification($order, $kMsg, $type), 'orders.kitchen_notification_failed', [
                        'order_id' => $order->id,
                        'recipient_id' => $kitchenUser->id,
                        'status' => $new_status,
                    ]);
                }
                

            } else {

                if ($user instanceof \Illuminate\Support\Collection && $user->isNotEmpty()) {
                    $this->safeSendNotification($user, new PushOrderNotification($order, $sMsg, $type), 'orders.user_notification_failed', [
                        'order_id' => $order->id,
                        'status' => $new_status,
                    ]);
                }
                
            }
            
            if ((int) $new_status === Order::STATUS_COMPLETED) {
                if ($order->user?->email) {
                    $this->safeQueueMail($order->user->email, new Invoice($order->user, $order, 1), 'orders.customer_invoice_failed', [
                        'order_id' => $order->id,
                        'recipient' => $order->user->email,
                    ]);
                }

                if ($kitchenUser?->email) {
                    $this->safeQueueMail($kitchenUser->email, new Invoice($order->user, $order, 0), 'orders.kitchen_invoice_failed', [
                        'order_id' => $order->id,
                        'recipient' => $kitchenUser->email,
                    ]);
                }
            }
             
        }

        
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
}
