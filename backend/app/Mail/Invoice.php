<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;
use App\Models\Mikitchn;

class Invoice extends Mailable
{
    use Queueable, SerializesModels;

    public $user;
    public $order;
    public $customer;
    /**
     * Create a new message instance.
     *
     * @return void
     */
    public function __construct($user,$order,$customer)
    {
        $this->user = $user;
        $this->order = $order;
        $this->customer = $customer;
    }

    /**
     * Build the message.
     *
     * @return $this
     */
    public function build()
    {
        return $this->view('Mail.orderInvoice')
                    ->subject('Order Invoice');
    }
}
