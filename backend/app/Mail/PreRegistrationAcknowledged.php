<?php

namespace App\Mail;

use App\Models\PreRegistration;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;

class PreRegistrationAcknowledged extends Mailable implements ShouldQueue
{
    use Queueable, SerializesModels;

    public function __construct(public PreRegistration $preRegistration)
    {
    }

    public function build(): self
    {
        return $this->view('Mail.preRegistrationAcknowledged')
            ->subject('Thanks for your interest in mitabl');
    }
}
