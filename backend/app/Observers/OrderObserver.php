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
        // $kitchen_id = $order->mikitchn_id;
        // $kitchen = Mikitchn::find($kitchen_id)->user;
        // $kMsg = 'new order '.$order->order_id.' added.';
        // Notification::send($kitchen ,new PushOrderNotification($order,$kMsg));
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

                    // $cancelBy = CancelReason::where('order_id',$order->id)->get()->first();

                    // print_r($cancelBy); die();
                    if ($actorRoleId === 3) {
                        $type = 3;
                        $sMsg = 'your order '.$order->order_id.' was canceled by mifoodie';
                         $user = $kitchenUser ? collect([$kitchenUser]) : collect();
                    } else {
                        $type = 4;
                        $sMsg = 'your order '.$order->order_id.' was canceled by micook'; 
                    }

                    break;
                case Order::STATUS_COMPLETED:
                    $type = 5;
                    $sMsg = 'your order '.$order->order_id.' is completed';
                    break;
                case Order::STATUS_REQUESTED:
                    $type = 1;
                    // $sMsg = 'your order '.$order->order_id.' has pending.';
                    $sMsg = '';
                    break;
                case Order::STATUS_CONFIRMED:
                    $type = 2;
                    $sMsg = 'your order '.$order->order_id.' is accepted';
                    break;
                
                default:
                    $type = 4;
                    $sMsg = '';
                    break;
            }
            // die('jkfkd');
            if ((int) $new_status === Order::STATUS_REQUESTED) {
                $kMsg = 'new order '.$order->order_id.' added';

                
                
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
}
