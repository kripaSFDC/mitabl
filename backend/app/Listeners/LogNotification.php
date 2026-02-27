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
        // print_r($event);
        // die('data_notify');
        $idNotify = $user_not->notifyDisable ? 0 : 1;
        if($idNotify && $user_not->device_token){
            $data_notify= $event->response;
            $notificationData = [];
            
            // if (empty($data_notify)) {
            //     // print_r($data_notify);
            //     // die('data_notify');
            //     // return true;
            // } else {
                // die('data_notify');
                if ($data_notify->data['type'] == 8) {
                    $notificationData = [
                        'id'=>$data_notify->id,
                        'type'=>$data_notify->data['type'],
                        'message'=>$data_notify->data['message'],
                        'created_at'=>$data_notify->created_at->diffForHumans(),
                        // 'read_at'=>$data_notify->read_at,
                    ];
                } else {
                    $notificationData = [
                        'id'=>$data_notify->id,
                        'type'=>$data_notify->data['type'],
                        'order_id'=>$data_notify->data['order_id'] ,
                        'message'=>$data_notify->data['message'],
                        'created_at'=>$data_notify->created_at->diffForHumans(),
                        // 'read_at'=>$data_notify->read_at,
                    ];
                }


                $data=json_encode($notificationData);
                $body= $data_notify->data['message'];
                // $body= $data_notify->data;
                // $title =config('app.APP_NAME');
                $title =env('APP_NAME');
                $icon =null;
                $auth_id = auth()->id();
                $device_token= [$user_not->device_token];
                $ob = new FCMAPP;
                $result = $ob->sendTo($device_token,$title,$body,$icon,$data);
            // }
        // print_r($event); 

        // die('jkfgbk');
            
        }
    }
}
