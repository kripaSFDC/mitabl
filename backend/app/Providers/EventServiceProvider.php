<?php

namespace App\Providers;

use Illuminate\Foundation\Support\Providers\EventServiceProvider as ServiceProvider;
use App\Events\MakeOrderPaymentToVendor;
use App\Events\CancelOrderRefund;
use App\Listeners\MakeOrderPaymentToVendorListener;
use App\Listeners\CancelOrderRefundListener;
use App\Listeners\MarkCrmCommunicationDelivered;

class EventServiceProvider extends ServiceProvider
{
    /**
     * The event listener mappings for the application.
     *
     * @var array<class-string, array<int, class-string>>
     */
    protected $listen = [
        // Registered::class => [
        //     SendEmailVerificationNotification::class,
        // ],
        'Illuminate\Notifications\Events\NotificationSent' => [
            'App\Listeners\LogNotification',
        ],
        'Illuminate\Mail\Events\MessageSent' => [
            MarkCrmCommunicationDelivered::class,
        ],
        MakeOrderPaymentToVendor::class => [
            MakeOrderPaymentToVendorListener::class,
        ],
        CancelOrderRefund::class => [
            CancelOrderRefundListener::class,
        ],
    ];
    /**
     * Register any events for your application.
     *
     * @return void
     */
    public function boot()
    {
        //
    }
}
