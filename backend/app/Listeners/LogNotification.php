<?php

namespace App\Listeners;

use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Events\NotificationSent;
use Illuminate\Queue\InteractsWithQueue;
use FCMAPP;
class LogNotification implements ShouldQueue
{
    use InteractsWithQueue;
    /**
     * Create the event listener.
     *
     * @return void
     */
    public function __construct()
    {
        
    }

    /**
     * Handle the event.
     *
     * @param  object  $event
     * @return void
     */
    public function handle($event)
    {
        $user_not = $event->notifiable;
        $idNotify = $user_not->notifyDisable ? 0 : 1;
        if($idNotify && $user_not->device_token){
            $data_notify= $event->response;
            $notificationData = [];

            if ($data_notify->data['type'] == 8) {
                $notificationData = [
                    'id'=>$data_notify->id,
                    'type'=>$data_notify->data['type'],
                    'message'=>$data_notify->data['message'],
                    'created_at'=>$data_notify->created_at->diffForHumans(),
                ];
            } else {
                $notificationData = [
                    'id'=>$data_notify->id,
                    'type'=>$data_notify->data['type'],
                    'order_id'=>$data_notify->data['order_id'] ,
                    'message'=>$data_notify->data['message'],
                    'created_at'=>$data_notify->created_at->diffForHumans(),
                ];
            }

            $data=json_encode($notificationData);
            $body= $data_notify->data['message'];
            $title =env('APP_NAME');
            $icon =null;
            $device_token= [$user_not->device_token];
            $ob = new FCMAPP;
            $result = $ob->sendTo($device_token,$title,$body,$icon,$data);
        }
    }
}
