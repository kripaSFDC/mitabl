<?php

namespace App\Observers;

use App\Models\Order;
use App\Models\Mikitchn;
use App\Models\User;
use App\Models\CancelReason;
use App\Mail\Invoice;
use Illuminate\Support\Facades\Notification;
use App\Notifications\PushOrderNotification;
use Auth;
use App\Events\UserMobileNotification;

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

        $user = User::where('id',$user_id)->get();
        $kitchen = Mikitchn::find($order->mikitchn_id)->user;
        if($order->isDirty('status')){
            // email has changed
            $new_status = $order->status; 
            $old_status = $order->getOriginal('status');
            
            switch ($new_status) {
                case 0:

                    // $cancelBy = CancelReason::where('order_id',$order->id)->get()->first();

                    // print_r($cancelBy); die();
                    if (Auth::user()->role_id == 3) {
                        $type = 3;
                        $sMsg = 'your order '.$order->order_id.' was canceled by mifoodie';
                         $user = $kitchen;
                    } else {
                        $type = 4;
                        $sMsg = 'your order '.$order->order_id.' was canceled by micook'; 
                    }

                    break;
                case 1:
                    $type = 5;
                    $sMsg = 'your order '.$order->order_id.' is completed';
                    break;
                case 2:
                    $type = 1;
                    // $sMsg = 'your order '.$order->order_id.' has pending.';
                    $sMsg = '';
                    break;
                case 3:
                    $type = 2;
                    $sMsg = 'your order '.$order->order_id.' is accepted';
                    break;
                
                default:
                    $type = 4;
                    $sMsg = '';
                    break;
            }
            // die('jkfkd');
            if ($new_status == 2) {
                $kMsg = 'new order '.$order->order_id.' added';

                
                
                Notification::send($kitchen ,new PushOrderNotification($order,$kMsg,$type));
                

            } else {

                Notification::send($user ,new PushOrderNotification($order,$sMsg,$type)); 
                
            }
            
            if ($new_status == 1) {
                \Mail::to($order->user->email)->send(new Invoice($order->user,$order,1));
                $kitchenUser = Auth::user();
                // print_r($kitchenUser); die();
                \Mail::to($kitchenUser->email)->send(new Invoice($order->user,$order,0));
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
}
