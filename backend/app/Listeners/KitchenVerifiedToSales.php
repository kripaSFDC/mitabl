<?php

namespace App\Listeners;

use App\Events\KitchenVerified;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Support\Facades\Http;
use App\Http\Controllers\Api\WebApiToCurlController;
use App\Models\SalesKitchen;

class KitchenVerifiedToSales implements ShouldQueue
{
    use InteractsWithQueue;

    /**
     * Create the event listener.
     *
     * @return void
     */
    public function __construct()
    {
        //
    }

    /**
     * Handle the event.
     *
     * @param  App\Events\KitchenVerified  $event
     * @return void
     */
    public function handle(KitchenVerified $event)
    {
        // 
        $userinfo = $event->user;
        $kitcheninfo = $event->kitchen;
        $kitchnAddress = $event->kitchnAddress;
        $status = $event->status;
        $baseUrl = rtrim((string) config('services.salesforce.base_url'), '/');
        if ($baseUrl === '') {
            return;
        }

        $apiVersion = config('services.salesforce.api_version', 'v55.0');
        $apiURL = $baseUrl . '/services/data/' . $apiVersion . '/sobjects/Account';
        $apiUrlForUpdate = $baseUrl . '/services/data/' . $apiVersion . '/sobjects/Account/';

        $ob = new WebApiToCurlController;
        $accessTkn = $ob->getAccToken();
        if (!$accessTkn) {
            return;
        }


        $headers = [
            'Access-Control-Allow-Origin' => '*',
            'Authorization' => 'Bearer '.$accessTkn,
        ];

        // if ($kitcheninfo->certificate && $kitcheninfo->certificate->status) {
        //     $status = 'Active';
        // }

        // if ($kitcheninfo->certificate && !$kitcheninfo->certificate->status && $status == 'Activation Pending') {
        //     $status = 'Activation Pending';
        // }

        $postInputSen = [
            "Name" => $userinfo->first_name.' '.$userinfo->last_name,
            "Type" => "New Customer",
            "mitabl_MiKitchen_Id__c" => $kitcheninfo->id,
            "ShippingStreet" => $kitchnAddress['formatted_address'] ?? '',
            "ShippingCity" => $kitchnAddress['city'] ?? '',
            "ShippingState" => $kitchnAddress['province'] ?? '',
            "ShippingCountry" => $kitchnAddress['country'] ?? '',
            "ShippingPostalCode" => $kitchnAddress['postal_code'] ?? '',
            "Phone" => $kitcheninfo->phone,
            "mitabl_No_of_Seats__c" => $kitcheninfo->no_of_seats,
            "mitabl_Dine_In__c" => $kitcheninfo->dine_in ? 'true' : 'false',
            "mitabl_Take_Away__c" => $kitcheninfo->take_away ? 'true' : 'false',
            "Description" => $kitcheninfo->description,
            "mitabl_ABN__c" => $kitcheninfo->certificate ? $kitcheninfo->certificate->abn : '',
            "mitabl_Certificate_No__c" => $kitcheninfo->certificate ? $kitcheninfo->certificate->certificate_no : '',
            "mitabl_Document_URL__c" => $kitcheninfo->certificate ? $kitcheninfo->certificate->certificate_doc : '',
            "mitabl_Status__c" => $status
        ];

        $upFirstTime = true;

        // die('hbjbvjdf');

        if ($kitcheninfo->saleskitchen) {
            $upFirstTime = false;
            $apiURL = $apiUrlForUpdate.$kitcheninfo->saleskitchen->sales_mikitchn_id;
            $response = Http::withHeaders($headers)->patch($apiURL, $postInputSen);
        }else{
            $postInputSen["mitabl_Micook_Id__c"] = $userinfo->id;
            $response = Http::withHeaders($headers)->post($apiURL, $postInputSen);
        }
        
        // print_r($postInputSen); die();

        

  

        $statusCode = $response->status();

        $responseBody = json_decode($response->getBody(), true);

        if ($upFirstTime && $statusCode == 201) {
            $salesKitchen = new SalesKitchen();
            $salesKitchen->mikitchn_id = $kitcheninfo->id;
            $salesKitchen->sales_mikitchn_id = $responseBody['id'];
            $salesKitchen->save();
        }
        // print_r($statusCode);
        // print_r($responseBody);
        // die();


    }
}
