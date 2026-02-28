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
        $postInputSen = $this->normalizePreRegisterPayload($request->all());
        $apiURL = rtrim((string) config('services.salesforce.base_url'), '/') .
            '/services/data/' . config('services.salesforce.api_version', 'v55.0') . '/sobjects/Lead';

        $accessTkn = $this->getAccToken();
        if ($accessTkn) {
            // token resolved
        } else {
            return $this->responser([],'Pre Registration Not Available');
        }

        // print_r($accessTkn); die();

        $headers = [

            'Access-Control-Allow-Origin' => '*',
            'Authorization' => 'Bearer '.$accessTkn, 

        ];

  

        try {
            $response = Http::withHeaders($headers)
                ->connectTimeout(10)
                ->timeout(20)
                ->post($apiURL, $postInputSen);
        } catch (\Throwable $e) {
            return $this->responser([], 'Pre Registration Not Available');
        }

  

        $statusCode = $response->status();

        $responseBody = $response->json();

        if ($statusCode == 200) {
            return $this->responser($responseBody,"Your Registration Created Successfully");
        } elseif ($statusCode == 400) {
            $message = is_array($responseBody) && isset($responseBody[0]['message'])
                ? (string) $responseBody[0]['message']
                : 'Pre Registration Not Available';
            return $this->responser([], $message);
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
        $postInputSen = $this->normalizeMobContactPayload($request->all());
        $apiURL = rtrim((string) config('services.salesforce.base_url'), '/') .
            '/services/data/' . config('services.salesforce.api_version', 'v55.0') . '/sobjects/Case';

        $accessTkn = $this->getAccToken();
        if ($accessTkn) {
            // token resolved
        } else {
            return $this->responser([],'Contact Not Available');
        }

        // print_r($accessTkn); die();

        $headers = [

            'Access-Control-Allow-Origin' => '*',
            'Authorization' => 'Bearer '.$accessTkn, 

        ];

  

        try {
            $response = Http::withHeaders($headers)
                ->connectTimeout(10)
                ->timeout(20)
                ->post($apiURL, $postInputSen);
        } catch (\Throwable $e) {
            return $this->responser([], 'Contact Not Available');
        }

  

        $statusCode = $response->status();

        $responseBody = $response->json();

        if ($statusCode == 200) {
            return $this->responser($responseBody,"Contact Message Sent Successfully");
        } elseif ($statusCode == 400) {
            $message = is_array($responseBody) && isset($responseBody[0]['message'])
                ? (string) $responseBody[0]['message']
                : 'Contact Not Available';
            return $this->responser([], $message);
        } elseif ($statusCode == 201) {
            return $this->responser($responseBody,"Contact Message Sent Successfully");
        } else {
            return response()->json(['body'=>$responseBody],$statusCode);
        }

        

    }

    public function getAccToken()
    {
        $baseUrl = rtrim((string) config('services.salesforce.base_url'), '/');
        if ($baseUrl === '') {
            return null;
        }
        $apiUrl = $baseUrl . '/services/oauth2/token';

        $postInput = [
                'grant_type' => 'password',
                'client_id' => config('services.salesforce.client_id'),
                'client_secret' => config('services.salesforce.client_secret'),
                'username' => config('services.salesforce.username'),
                'password' => (string) config('services.salesforce.password') . (string) config('services.salesforce.security_token'),
            ];

        if (empty($postInput['client_id']) || empty($postInput['client_secret']) || empty($postInput['username']) || empty($postInput['password'])) {
            return null;
        }

        $headers = [
            'Access-Control-Allow-Origin' => '*',
        ];

        try {
            $response = Http::withHeaders($headers)
                ->asForm()
                ->connectTimeout(10)
                ->timeout(20)
                ->post($apiUrl, $postInput);
        } catch (\Throwable $e) {
            return null;
        }
        $responseBody = $response->json();

        if (is_array($responseBody) && array_key_exists('access_token', $responseBody)) {
            return $responseBody['access_token'];
        }

        return null;
    }

    private function normalizePreRegisterPayload(array $payload): array
    {
        if (!isset($payload['FirstName']) && isset($payload['first_name'])) {
            $payload['FirstName'] = $payload['first_name'];
        }
        if (!isset($payload['LastName']) && isset($payload['last_name'])) {
            $payload['LastName'] = $payload['last_name'];
        }
        if (!isset($payload['Email']) && isset($payload['email'])) {
            $payload['Email'] = $payload['email'];
        }
        if (!isset($payload['MobilePhone']) && isset($payload['mobile'])) {
            $payload['MobilePhone'] = $payload['mobile'];
        }
        if (!isset($payload['City']) && isset($payload['city'])) {
            $payload['City'] = $payload['city'];
        }
        if (!isset($payload['mitabl_Interested_In__c']) && isset($payload['00N5i000006uZtT'])) {
            $payload['mitabl_Interested_In__c'] = $payload['00N5i000006uZtT'];
        }

        return $payload;
    }

    private function normalizeMobContactPayload(array $payload): array
    {
        if (!isset($payload['Type']) && isset($payload['type'])) {
            $payload['Type'] = $payload['type'];
        }
        if (!isset($payload['SuppliedEmail']) && isset($payload['email'])) {
            $payload['SuppliedEmail'] = $payload['email'];
        }
        if (!isset($payload['SuppliedPhone']) && isset($payload['phone'])) {
            $payload['SuppliedPhone'] = $payload['phone'];
        }
        if (!isset($payload['Subject']) && isset($payload['subject'])) {
            $payload['Subject'] = $payload['subject'];
        }
        if (!isset($payload['Description']) && isset($payload['description'])) {
            $payload['Description'] = $payload['description'];
        }
        if (!isset($payload['mitabl_Case_For__c']) && isset($payload['recordType'])) {
            $payload['mitabl_Case_For__c'] = $payload['recordType'];
        }
        if (!isset($payload['mitabl_micook_Id__c']) && isset($payload['00N5i000009zQqb'])) {
            $payload['mitabl_micook_Id__c'] = $payload['00N5i000009zQqb'];
        }
        if (!isset($payload['mitabl_Mifoodi_Id__c']) && isset($payload['00N5i000009zQxr'])) {
            $payload['mitabl_Mifoodi_Id__c'] = $payload['00N5i000009zQxr'];
        }
        if (!isset($payload['mitabl_Order_Id__c']) && isset($payload['00N5i000006ubH5'])) {
            $payload['mitabl_Order_Id__c'] = $payload['00N5i000006ubH5'];
        }

        return $payload;
    }

}
