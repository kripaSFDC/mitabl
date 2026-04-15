<?php

namespace App\Observers;

use App\Models\Mikitchn;
use App\Models\User;
use App\Mail\KitchenActivation;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Notification;
use App\Notifications\PushUserNotification;
use App\Services\KitchenService;
use Throwable;

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
        app(KitchenService::class)->invalidateDiscoveryCaches();
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
                    $sMsg = 'Your kitchen account is now active!';
                    break;
                
                default:
                    $sMsg = '';
                    break;
            }

            $this->safeSendNotification($user, new PushUserNotification($user, $sMsg, $type), 'kitchens.notification_failed', [
                'kitchen_id' => $mikitchn->id,
                'user_id' => $user?->id,
                'status' => $new_status,
            ]);
            if ($new_status) {
                $this->safeQueueMail((string) $user->email, new KitchenActivation($user), 'kitchens.activation_mail_failed', [
                    'kitchen_id' => $mikitchn->id,
                    'user_id' => $user?->id,
                    'recipient' => $user?->email,
                ]);
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
        app(KitchenService::class)->invalidateDiscoveryCaches();
    }

    /**
     * Handle the Mikitchn "deleted" event.
     *
     * @param  \App\Models\Mikitchn  $mikitchn
     * @return void
     */
    public function deleted(Mikitchn $mikitchn)
    {
        app(KitchenService::class)->invalidateDiscoveryCaches();
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

    private function safeSendNotification(mixed $notifiable, object $notification, string $logEvent, array $context = []): void
    {
        try {
            Notification::send($notifiable, $notification);
        } catch (Throwable $throwable) {
            Log::error($logEvent, $context + [
                'error' => $throwable->getMessage(),
            ]);
        }
    }

    private function safeQueueMail(string $recipient, object $mailable, string $logEvent, array $context = []): void
    {
        try {
            Mail::to($recipient)->queue(method_exists($mailable, 'afterCommit') ? $mailable->afterCommit() : $mailable);
        } catch (Throwable $throwable) {
            Log::error($logEvent, $context + [
                'error' => $throwable->getMessage(),
            ]);
        }
    }
}
