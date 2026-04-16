<?php

namespace App\Listeners;

use App\Events\MakeOrderPaymentToVendor;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Queue\InteractsWithQueue;
use App\Models\Order;
use App\Services\PaymentService;

class MakeOrderPaymentToVendorListener implements ShouldQueue
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
     * @param  MakeOrderPaymentToVendor  $event
     * @return void
     */
    public function handle(MakeOrderPaymentToVendor $event)
    {
        $cOrder = $event->order;

        $order = $cOrder->order;

        $kOrderCount = Order::where('mikitchn_id',$order->mikitchn_id)->where('status',1)->count();
        $kRating = $order->mikitchn->reviews->avg('rating');

        if ($kOrderCount <= 5) {
            $dPercent = 0;
        } elseif ($kOrderCount >= 6 && $kOrderCount <= 100) {
            $dPercent = 25;
        } elseif ($kOrderCount >= 101 && $kOrderCount <= 150) {
            $dPercent = 20;
        } elseif ($kOrderCount >= 151 && $kOrderCount <= 230) {
            $dPercent = 18;
        } elseif ($kOrderCount >= 231 && $kOrderCount <= 300) {
            $dPercent = 15;
        } elseif ($kOrderCount > 300 && $kRating >= 4) {
            $dPercent = 10;
        } else {
            $dPercent = 15;
        }
        $trnsfr =  $this->paymentService->safely(
              fn () => $this->paymentService->transferToVendor(
                  $order->Mikitchn,
                  (float) $order->total_price,
                  (int) $order->id,
                  (float) $dPercent,
                  'Order Payment',
                  'order_transfer_' . $order->id . '_completion'
              )
          );
        if (is_object($trnsfr)) {
            $cOrder->completed = 1;
            $cOrder->save();
        }
    }
}
