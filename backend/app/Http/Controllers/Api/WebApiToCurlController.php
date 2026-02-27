<?php
namespace App\Http\Controllers\Api;

use App\Models\User;
use Illuminate\Http\Request;
use App\Http\Controllers\Controller;
use Validator;
use Storage;
use Carbon\Carbon;
use Illuminate\Support\Facades\Http;

class WebApiToCurlController extends Controller
{
    public $data=[];

    public function preRegister(Request $request)
    {
        $postInputSen = $request->all();
        // print_r(); die();

        $apiURL = 'https://mitabl--test.sandbox.my.salesforce.com/services/data/v53.0/sobjects/Lead';
        // $accessTkn = '00D0w0000000VGf!ARgAQNkUQ.96pjGg87HyU_vqm2TfVpHWdF.UM03CFs2Miax2e2oR2OXB3hSpx8S6BfoSYXjFo_RYONUlHpAGdT0U1yE2bNNp';
        $accessTkn = '00D0w0000000VGf!ARgAQFzMElnkNvdJ5KIbX7Mkg2yiCqrbPGQWULGV5gOgUsMtPBIu4OsZYjXM1.48O_vNLmhEs.oHJTzFSzVhBoIthLrSt2lU';

        // print_r(); die();

        if ($this->getAccToken()) {
            $accessTkn = $this->getAccToken();
        }else{
            return $this->responser([],'Pre Registration Not Available');
        }

        // print_r($accessTkn); die();

        $headers = [

            'Access-Control-Allow-Origin' => '*',
            'Authorization' => 'Bearer '.$accessTkn, 

        ];

  

        $response = Http::withHeaders($headers)->post($apiURL, $postInputSen);

  

        $statusCode = $response->status();

        $responseBody = json_decode($response->getBody(), true);

        if ($statusCode == 200) {
            return $this->responser($responseBody,"Your Registration Created Successfully");
        } elseif ($statusCode == 400) {
            return $this->responser([],$responseBody[0]['message']);
        } elseif ($statusCode == 201) {
            return $this->responser($responseBody,"Your Registration Created Successfully");
        } else {
            return $this->responser($responseBody,$statusCode);
        }

        // echo "<pre>";
        // print_r($statusCode);
        // print_r($responseBody[0]['message']);
        // die();
        // dd($responseBody);

        

    }

    public function mobContact(Request $request)
    {
        $postInputSen = $request->all();
        // print_r($postInputSen); die();

        $apiURL = 'https://mitabl--test.sandbox.my.salesforce.com/services/data/v53.0/sobjects/Case';
        // $accessTkn = '00D0w0000000VGf!ARgAQNkUQ.96pjGg87HyU_vqm2TfVpHWdF.UM03CFs2Miax2e2oR2OXB3hSpx8S6BfoSYXjFo_RYONUlHpAGdT0U1yE2bNNp';
        $accessTkn = '00D0w0000000VGf!ARgAQE92IOKKjemBf1EECUijTrCOoD.fKTOMdTF.JsTdpNSYuBIN6jVQ2mHdeK.BhodrZGGNDTJUNiggH1Xe2nDSaI1nVQBA';

        // print_r($accessTkn); die();

        if ($this->getAccToken()) {
            $accessTkn = $this->getAccToken();
        }else{
            return $this->responser([],'Contact Not Available');
        }

        // print_r($accessTkn); die();

        $headers = [

            'Access-Control-Allow-Origin' => '*',
            'Authorization' => 'Bearer '.$accessTkn, 

        ];

  

        $response = Http::withHeaders($headers)->post($apiURL, $postInputSen);

  

        $statusCode = $response->status();

        $responseBody = json_decode($response->getBody(), true);

        if ($statusCode == 200) {
            return $this->responser($responseBody,"Contact Message Sent Successfully");
        } elseif ($statusCode == 400) {
            return $this->responser([],$responseBody[0]['message']);
        } elseif ($statusCode == 201) {
            return $this->responser($responseBody,"Contact Message Sent Successfully");
        } else {
            return response()->json(['body'=>$responseBody],$statusCode);
        }

        

    }

    public function getAccToken()
    {
        $apiUrl = 'https://mitabl--test.sandbox.my.salesforce.com/services/oauth2/token';

        $postInput = [
                'grant_type' => 'password',
                'client_id' => '3MVG9rnryk9FxFMWV7Yuw3aQ.J.KBU2ss23wWNsxfLBLkbNzqEB19rnOjsqls0dd9ruedSClnDEA3Ys2wKqku',
                'client_secret' => 'F9509C8032FF50FAA68E49DD10C3870D0E1EB74A69B5BAE7D97E1B4845D6CCBC',
                'username' => 'int_user@mitabl.com',
                'password' => 'Integration@112233'
            ];

        $headers = [

            'Access-Control-Allow-Origin' => '*',
            'Content-Type' => 'application/x-www-form-urlencoded', 

        ];

        $response = Http::withHeaders($headers)->withBody(http_build_query($postInput), 'application/json')->post($apiUrl)->collect()->toArray();


        if (array_key_exists("access_token",$response)) {
            return $response['access_token'];
        }

        return null;
    }

}
