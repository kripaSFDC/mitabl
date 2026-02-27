<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;
use App\Models\Mikitchn;

class RefundInvoice extends Mailable
{
    use Queueable, SerializesModels;

    public $user;
    public $order;
    public $customer;
    public $refundAmount;
    /**
     * Create a new message instance.
     *
     * @return void
     */
    public function __construct($user,$order,$customer,$refundAmount)
    {
        $this->user = $user;
        $this->order = $order;
        $this->customer = $customer;
        $this->refundAmount = $refundAmount;
    }

    /**
     * Build the message.
     *
     * @return $this
     */
    public function build()
    {
        return $this->view('Mail.orderRefundInvoice')
                    ->subject('Order Refund Invoice');
    }
}
