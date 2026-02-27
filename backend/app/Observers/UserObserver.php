<?php

namespace App\Observers;

use App\Models\User;
use App\Mail\Registered;
use App\Mail\DeleteAccount;
use Illuminate\Support\Facades\Notification;
use App\Notifications\PushUserNotification;
class UserObserver
{
    /**
     * Handle the User "created" event.
     *
     * @param  \App\Models\User  $user
     * @return void
     */
    public function created(User $user)
    {
        
    }

     /**
     * Handle the User "updating" event.
     *
     * @param  \App\Models\User  $order
     * @return void
     */
   

    /**
     * Handle the User "updated" event.
     *
     * @param  \App\Models\User  $user
     * @return void
     */
    public function updated(User $user)
    {
        //
    }

    /**
     * Handle the Order "updating" event.
     *
     * @param  \App\Models\Order  $order
     * @return void
     */
    public function updating(User $user)
    {
        if($user->isDirty('email_verified')){

            $new_status = $user->email_verified;
            // echo "string"; die();
            if ($new_status == 1) {
                \Mail::to($user->email)->send(new Registered($user));
            }

        }
    }

    /**
     * Handle the User "deleted" event.
     *
     * @param  \App\Models\User  $user
     * @return void
     */
    public function deleted(User $user)
    {
        \Mail::to($user->email)->send(new DeleteAccount($user));
    }

    /**
     * Handle the User "restored" event.
     *
     * @param  \App\Models\User  $user
     * @return void
     */
    public function restored(User $user)
    {
        //
    }

    /**
     * Handle the User "force deleted" event.
     *
     * @param  \App\Models\User  $user
     * @return void
     */
    public function forceDeleted(User $user)
    {
        //
    }
}
