<?php

namespace App\Listeners;

use App\Events\CancelOrderRefund;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Queue\InteractsWithQueue;
use App\Http\Controllers\Controller;
use App\Mail\RefundInvoice;
use App\Services\PaymentService;

class CancelOrderRefundListener implements ShouldQueue
{
    use InteractsWithQueue;
    private PaymentService $paymentService;

    /**
     * Create the event listener.
     *
     * @return void
     */
    public function __construct(PaymentService $paymentService)
    {
        $this->paymentService = $paymentService;
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
                    $this->paymentService->safely(fn () => $this->paymentService->refundAmount(
                        $order->payment->payment_id,
                        (float) $order->total_price,
                        0,
                        'order_refund_' . $order->id . '_customer_full'
                    ));
                    \Mail::to($order->user->email)->send(new RefundInvoice($order->user,$order,1,100));
                }
                
            } elseif ($orderPendingHrs < 12) {
                if ($order->payment) {
                    $this->paymentService->safely(fn () => $this->paymentService->refundAmount(
                        $order->payment->payment_id,
                        (float) $order->total_price,
                        50,
                        'order_refund_' . $order->id . '_customer_partial'
                    ));
                    $this->paymentService->safely(fn () => $this->paymentService->transferToVendor(
                        $order->Mikitchn,
                        (float) $order->total_price,
                        (int) $order->id,
                        75,
                        'Order Canceled By Customer',
                        'order_transfer_' . $order->id . '_customer_partial'
                    ));
                    \Mail::to($order->user->email)->send(new RefundInvoice($order->user,$order,1,50));
                    \Mail::to($order->Mikitchn->user->email)->send(new RefundInvoice($order->user,$order,0,25));
                }
                
            }
            

        }else{

            if ($order->payment) {

                $this->paymentService->safely(fn () => $this->paymentService->refundAmount(
                    $order->payment->payment_id,
                    (float) $order->total_price,
                    0,
                    'order_refund_' . $order->id . '_kitchen_full'
                ));
                \Mail::to($order->user->email)->send(new RefundInvoice($order->user,$order,1,100));
                
            }

        }
       
        // print_r($order); 
        // die();
    }
}
