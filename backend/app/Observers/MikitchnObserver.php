<?php

namespace App\Observers;

use App\Models\Mikitchn;
use App\Models\User;
use App\Mail\KitchenActivation;
use Illuminate\Support\Facades\Notification;
use App\Notifications\PushUserNotification;
class MikitchnObserver
{
    /**
     * Handle the Mikitchn "created" event.
     *
     * @param  \App\Models\Mikitchn  $mikitchn
     * @return void
     */
    public function created(Mikitchn $mikitchn)
    {
        //
    }

     public function updating(Mikitchn $mikitchn)
    {
        
        $user_id = $mikitchn->user_id;

        $user = User::where('id',$user_id)->get()->first();

        if($mikitchn->isDirty('status')){
            // email has changed
            $new_status = $mikitchn->status; 
            $old_status = $mikitchn->getOriginal('status');
            $type = 8;
            switch ($new_status) {
                case 1:
                    $sMsg = 'your kitchen account is activate';
                    break;
                
                default:
                    $sMsg = '';
                    break;
            }

            Notification::send($user ,new PushUserNotification($user,$sMsg,$type)); 
            if ($new_status) {
                \Mail::to($user->email)->send(new KitchenActivation($user));
            }
            
        }

        
    }

    /**
     * Handle the Mikitchn "updated" event.
     *
     * @param  \App\Models\Mikitchn  $mikitchn
     * @return void
     */
    public function updated(Mikitchn $mikitchn)
    {
        
    }

    /**
     * Handle the Mikitchn "deleted" event.
     *
     * @param  \App\Models\Mikitchn  $mikitchn
     * @return void
     */
    public function deleted(Mikitchn $mikitchn)
    {
        //
    }

    /**
     * Handle the Mikitchn "restored" event.
     *
     * @param  \App\Models\Mikitchn  $mikitchn
     * @return void
     */
    public function restored(Mikitchn $mikitchn)
    {
        //
    }

    /**
     * Handle the Mikitchn "force deleted" event.
     *
     * @param  \App\Models\Mikitchn  $mikitchn
     * @return void
     */
    public function forceDeleted(Mikitchn $mikitchn)
    {
        //
    }
}
