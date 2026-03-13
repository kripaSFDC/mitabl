<?php

namespace App\Observers;

use App\Models\User;
use App\Mail\Registered;
use App\Mail\DeleteAccount;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use Throwable;

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
        if (! $user->wasChanged('email_verified') || ! (bool) $user->email_verified) {
            return;
        }

        try {
            Mail::to($user->email)->queue((new Registered($user))->afterCommit());
        } catch (Throwable $throwable) {
            Log::error('users.email_verified_notification_failed', [
                'user_id' => $user->id,
                'email' => $user->email,
                'error' => $throwable->getMessage(),
            ]);
        }
    }

    /**
     * Handle the Order "updating" event.
     *
     * @param  \App\Models\Order  $order
     * @return void
     */
    public function updating(User $user)
    {
        //
    }

    /**
     * Handle the User "deleted" event.
     *
     * @param  \App\Models\User  $user
     * @return void
     */
    public function deleted(User $user)
    {
        try {
            Mail::to($user->email)->queue((new DeleteAccount($user))->afterCommit());
        } catch (Throwable $throwable) {
            Log::error('users.delete_notification_failed', [
                'user_id' => $user->id,
                'email' => $user->email,
                'error' => $throwable->getMessage(),
            ]);
        }
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
