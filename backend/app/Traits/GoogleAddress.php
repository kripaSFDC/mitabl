<?php 
	namespace App\Traits;

	/**
	 * This trait for stripe connect and procedure functions.
	 */
	trait GoogleAddress
	{
		public static function geolocationaddress($lat, $long)
		{
		    $apiKey = (string) config('services.google_maps.api_key');
		    if ($apiKey === '') {
		    	return 'Not Found';
		    }
		    $geocode = "https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$long&sensor=false&key=$apiKey";
		    $response = self::performSecureGeocodeRequest($geocode);
		    if ($response === null) {
		    	return 'Not Found';
		    }
		    $output = json_decode($response);
		    if (!is_object($output)) {
		    	return 'Not Found';
		    }
		    $dataarray = get_object_vars($output);
		    if ($dataarray['status'] != 'ZERO_RESULTS' && $dataarray['status'] != 'INVALID_REQUEST') {
		        if (isset($dataarray['results'][0]->formatted_address)) {

		            $address = $dataarray['results'][0]->formatted_address;

		        } else {
		            $address = 'Not Found';

		        }
		    } else {
		        $address = 'Not Found';
		    }

		    return $address;
		}
		function Get_Address_From_Google_Maps($lat, $lon) {

			$apiKey = (string) config('services.google_maps.api_key');
			if ($apiKey === '') {
				return array();
			}
			$url = "https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lon&sensor=false&key=$apiKey";

			// Make the HTTP request using verified TLS.
			$data = self::performSecureGeocodeRequest($url);
			if ($data === null) {
				return array();
			}
			// Parse the json response
			$jsondata = json_decode($data,true);
			// return $jsondata; die();
			// If the json data is invalid, return empty array
			if (!$this->check_status($jsondata))   return array();

			$address = array(
			    'country' => $this->google_getCountry($jsondata),
			    'province' => $this->google_getProvince($jsondata),
			    'city' => $this->google_getCity($jsondata),
			    'street' => $this->google_getStreet($jsondata),
			    'postal_code' => $this->google_getPostalCode($jsondata),
			    'country_code' => $this->google_getCountryCode($jsondata),
			    'formatted_address' => $this->google_getAddress($jsondata),
			);

			return $address;
			}

			/* 
			* Check if the json data from Google Geo is valid 
			*/

			function check_status($jsondata) {
			    if ($jsondata["status"] == "OK") return true;
			    return false;
			}

			/*
			* Given Google Geocode json, return the value in the specified element of the array
			*/

			function google_getCountry($jsondata) {
			    return $this->Find_Long_Name_Given_Type("country", $jsondata["results"][0]["address_components"]);
			}
			function google_getProvince($jsondata) {
			    return $this->Find_Long_Name_Given_Type("administrative_area_level_1", $jsondata["results"][0]["address_components"], true);
			}
			function google_getCity($jsondata) {
			    return $this->Find_Long_Name_Given_Type("locality", $jsondata["results"][0]["address_components"]);
			}
			function google_getStreet($jsondata) {
			    return $this->Find_Long_Name_Given_Type("street_number", $jsondata["results"][0]["address_components"]) . ' ' . $this->Find_Long_Name_Given_Type("route", $jsondata["results"][0]["address_components"]);
			}
			function google_getPostalCode($jsondata) {
			    return $this->Find_Long_Name_Given_Type("postal_code", $jsondata["results"][0]["address_components"]);
			}
			function google_getCountryCode($jsondata) {
			    return $this->Find_Long_Name_Given_Type("country", $jsondata["results"][0]["address_components"], true);
			}
			function google_getAddress($jsondata) {
			    return $jsondata["results"][0]["formatted_address"];
			}

			/*
			* Searching in Google Geo json, return the long name given the type. 
			* (If short_name is true, return short name)
			*/

			function Find_Long_Name_Given_Type($type, $array, $short_name = false) {
			    foreach( $array as $value) {
			        if (in_array($type, $value["types"])) {
			            if ($short_name)    
			                return $value["short_name"];
			            return $value["long_name"];
			        }
			    }
			}

			private static function performSecureGeocodeRequest(string $url): ?string
			{
				$ch = curl_init();
				curl_setopt($ch, CURLOPT_URL, $url);
				curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
				curl_setopt($ch, CURLOPT_TIMEOUT, 10);
				curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, 5);
				curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 2);
				curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, 1);

				$response = curl_exec($ch);
				$httpCode = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
				$curlError = curl_error($ch);
				curl_close($ch);

				if ($response === false || $httpCode < 200 || $httpCode >= 300 || $curlError !== '') {
					return null;
				}

				return (string) $response;
			}
	}

?>
