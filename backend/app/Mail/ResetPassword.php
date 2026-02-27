<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;
use Illuminate\Notifications\Messages\MailMessage;

class ResetPassword extends Mailable
{
    use Queueable, SerializesModels;

    /**
     * Create a new message instance.
     *
     * @return void
     */
    public $name;
    public $token;

    public function __construct($name, $token)
    {
        $this->name = $name;
        $this->token = $token;
    }

    /**
     * Build the message.
     *
     * @return $this
     */
    public function build()
    {
        $user['name'] = $this->name;
        $user['token'] = $this->token;
        $pageUrl = env('APP_URL');
        
        return $this->subject('Reset Password')
            ->html((new MailMessage)
                // ->subject('Reset application Password v1')
                ->line('You are receiving this email because we received a password reset request for your account.')
                ->action('Reset Password', $pageUrl."reset-password/".$this->token)
                ->line('If you did not request a password reset, no further action is required.')
                ->render()
            );

    }
}
