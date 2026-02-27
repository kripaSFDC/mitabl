<?php

namespace App\Listeners;

use App\Events\CancelOrderRefund;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Queue\InteractsWithQueue;
use App\Http\Controllers\Controller;
use App\Traits\StripeTrait;
use App\Mail\RefundInvoice;

class CancelOrderRefundListener implements ShouldQueue
{
    use InteractsWithQueue,StripeTrait;

    /**
     * Create the event listener.
     *
     * @return void
     */
    public function __construct()
    {
        //
    }

    /**
     * Handle the event.
     *
     * @param  App\Events\CancelOrderRefund  $event
     * @return void
     */
    public function handle(CancelOrderRefund $event)
    {
        $order = $event->order;
        $by = $event->by;

        $cObj = new Controller();
        $orderPendingHrs = $cObj->getPendingHoursInOrderD($order);

        // print_r($orderPendingHrs); die();
        if ($by == 'customer') {
            if ($orderPendingHrs >= 12) {
                if ($order->payment) {
                    $this->refundAmount($order->payment->payment_id,$order->total_price,0);
                    \Mail::to($order->user->email)->send(new RefundInvoice($order->user,$order,1,100));
                }
                
            } elseif ($orderPendingHrs < 12) {
                if ($order->payment) {
                    $this->refundAmount($order->payment->payment_id,$order->total_price,50);
                    $this->transferToVendor($order->Mikitchn,$order->total_price,$order->id,75,'Order Canceled By Customer');
                    \Mail::to($order->user->email)->send(new RefundInvoice($order->user,$order,1,50));
                    \Mail::to($order->Mikitchn->user->email)->send(new RefundInvoice($order->user,$order,0,25));
                }
                
            }
            

        }else{

            if ($order->payment) {

                $this->refundAmount($order->payment->payment_id,$order->total_price,0);
                \Mail::to($order->user->email)->send(new RefundInvoice($order->user,$order,1,100));
                
            }

        }
       
        // print_r($order); 
        // die();
    }
}
