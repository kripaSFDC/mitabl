<?php

namespace App\Providers;

use Illuminate\Auth\Events\Registered;

use Illuminate\Auth\Listeners\SendEmailVerificationNotification;
use Illuminate\Foundation\Support\Providers\EventServiceProvider as ServiceProvider;
use Illuminate\Support\Facades\Event;
use App\Events\KitchenVerified;
use App\Events\UserMobileNotification;
use App\Events\MakeOrderPaymentToVendor;
use App\Events\CancelOrderRefund;
use App\Listeners\KitchenVerifiedToSales;
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
        // UserMobileNotification::class => [
        //     'App\Listeners\LogNotification',
        // ],
        KitchenVerified::class => [
            KitchenVerifiedToSales::class,
        ],
        MakeOrderPaymentToVendor::class => [
            MakeOrderPaymentToVendorListener::class,
        ],
        CancelOrderRefund::class => [
            CancelOrderRefundListener::class,
        ],
    ];

    // UserMobileNotification::class => [
    //         'App\Listeners\LogNotification',
    //     ],
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
