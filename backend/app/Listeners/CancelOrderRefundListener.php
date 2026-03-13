<?php

namespace App\Listeners;

use App\Events\CancelOrderRefund;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Queue\InteractsWithQueue;
use App\Http\Controllers\Controller;
use App\Mail\RefundInvoice;
use App\Services\PaymentService;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use Throwable;

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
                    $this->safeQueueRefundMail($order->user->email, new RefundInvoice($order->user, $order, 1, 100), [
                        'order_id' => $order->id,
                        'recipient' => $order->user->email,
                        'context' => 'customer_full_refund',
                    ]);
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
                    $this->safeQueueRefundMail($order->user->email, new RefundInvoice($order->user, $order, 1, 50), [
                        'order_id' => $order->id,
                        'recipient' => $order->user->email,
                        'context' => 'customer_partial_refund',
                    ]);
                    $this->safeQueueRefundMail($order->Mikitchn->user->email, new RefundInvoice($order->user, $order, 0, 25), [
                        'order_id' => $order->id,
                        'recipient' => $order->Mikitchn->user->email,
                        'context' => 'vendor_partial_transfer',
                    ]);
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
                $this->safeQueueRefundMail($order->user->email, new RefundInvoice($order->user, $order, 1, 100), [
                    'order_id' => $order->id,
                    'recipient' => $order->user->email,
                    'context' => 'kitchen_full_refund',
                ]);
                
            }

        }
       
        // print_r($order); 
        // die();
    }

    private function safeQueueRefundMail(string $recipient, object $mailable, array $context = []): void
    {
        try {
            Mail::to($recipient)->queue(method_exists($mailable, 'afterCommit') ? $mailable->afterCommit() : $mailable);
        } catch (Throwable $throwable) {
            Log::error('orders.refund_mail_failed', $context + [
                'error' => $throwable->getMessage(),
            ]);
        }
    }
}
