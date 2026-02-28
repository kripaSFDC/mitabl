<?php

namespace App\Observers;

use App\Models\Review;
use App\Models\User;
use App\Models\Mikitchn;
use Illuminate\Support\Facades\Notification;
use App\Notifications\PushReviewNotification;
use Auth;
use App\Services\KitchenService;

class ReviewObserver
{
    /**
     * Handle the Review "created" event.
     *
     * @param  \App\Models\Review  $review
     * @return void
     */
    public function created(Review $review)
    {
        app(KitchenService::class)->invalidateDiscoveryCaches();
        $type = null;
        if ($review->by_user == 'customer') {
            $type = 7;
            $kitchen_id = $review->mikitchn_id;
            $user = Mikitchn::find($kitchen_id)->user; 
            $currentUser = Auth::user();
            $kMsg = 'new review from customer '.$currentUser->first_name;
        } else {
            $type = 6;
            $user = User::find($review->user_id);
            $restaurant = Auth::user()->restaurant;
            $kMsg = 'new review from kitchen '.$restaurant->name;
        }
        
        Notification::send($user ,new PushReviewNotification($user,$kMsg,$review,$type));
    }

    /**
     * Handle the Review "updated" event.
     *
     * @param  \App\Models\Review  $review
     * @return void
     */
    public function updated(Review $review)
    {
        app(KitchenService::class)->invalidateDiscoveryCaches();
    }

    /**
     * Handle the Review "deleted" event.
     *
     * @param  \App\Models\Review  $review
     * @return void
     */
    public function deleted(Review $review)
    {
        app(KitchenService::class)->invalidateDiscoveryCaches();
    }

    /**
     * Handle the Review "restored" event.
     *
     * @param  \App\Models\Review  $review
     * @return void
     */
    public function restored(Review $review)
    {
        //
    }

    /**
     * Handle the Review "force deleted" event.
     *
     * @param  \App\Models\Review  $review
     * @return void
     */
    public function forceDeleted(Review $review)
    {
        //
    }
}
