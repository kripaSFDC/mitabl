<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use App\Observers\OrderObserver;
use App\Observers\MikitchnObserver;
use App\Observers\ReviewObserver;
use App\Observers\UserObserver;
use App\Models\Order;
use App\Models\Mikitchn;
use App\Models\Review;
use App\Models\User;
use Illuminate\Routing\UrlGenerator;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     *
     * @return void
     */
    public function register()
    {
        //
    }

    /**
     * Bootstrap any application services.
     *
     * @return void
     */
    public function boot(UrlGenerator $url)
    {

        $url->forceScheme('https');


        Order::observe(OrderObserver::class);
        Mikitchn::observe(MikitchnObserver::class);
        Review::observe(ReviewObserver::class);
        User::observe(UserObserver::class);
    }
}
