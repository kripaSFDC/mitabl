<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Auth;

class FcmController extends Controller
{

    public function getAllNotifications(Request $request)
    {
        $queryparams = $request->query();
        $limit = max((int) ($queryparams['limit'] ?? 10), 1);
        $page = max(((int) ($queryparams['page'] ?? 1)) - 1, 0);

        $notifications = $this->authenticatedUser()->notifications()
                        ->select('data','created_at');
        $data['total_count'] = $notifications->count();

        $data['notifications'] = $notifications
                                ->offset($page * $limit)
                                ->limit($limit)
                                ->get();
        return $this->responser($data, 'notifications history.');
    }

    public  function sendTo($device_token=null,$title="FCMAPP",$body="FCMAPP BODY",$icon=null,$data) {

        $notification = [
            'title' => $title,
            'body' => $body,
            'icon' => $icon,
        ];

        $notification = array_filter($notification, function($value) {
            return $value !== null;
        });

        $url = 'https://fcm.googleapis.com/fcm/send';

        $fields = array (
            'registration_ids' => $device_token,
            'notification' => $notification,
            'data'=>['fcmapp'=>$data]
        );
        $fields = json_encode ( $fields );

        $headers = array (
            'Authorization: key=' . config('services.fcm.server_key'),
            'Content-Type: application/json'
        );

        $ch = curl_init ();
        curl_setopt ( $ch, CURLOPT_URL, $url );
        curl_setopt ( $ch, CURLOPT_POST, true );
        curl_setopt ( $ch, CURLOPT_HTTPHEADER, $headers );
        curl_setopt ( $ch, CURLOPT_RETURNTRANSFER, true );
        curl_setopt ( $ch, CURLOPT_POSTFIELDS, $fields );
        $result = curl_exec ( $ch );
        curl_close ( $ch );

        return $result;
    }
}
