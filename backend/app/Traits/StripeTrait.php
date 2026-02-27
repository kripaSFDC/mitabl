<?php 
	namespace App\Traits;

	use Stripe\Account as StripeAccount;
	use Stripe\Charge;
	use Stripe\Customer;
	use Stripe\Stripe as StripeBase;
	use Stripe\OAuth;
	use Stripe\StripeClient;
	use Auth, Exception, Validator;;
	use App\Http\Controllers\Controller;
	use Carbon\Carbon;
	use App\Models\User;

	/**
	 * This trait for stripe connect and procedure functions.
	 */
	trait StripeTrait
	{
		private $stripe;

		function __construct()
		{
			$this->stripe = new StripeClient(config('stripe.api_keys.secret_key'));
        	StripeBase::setApiKey(config('stripe.api_keys.secret_key'));
		}

		public function getMerchantacc()
		{
			return print_r($this->stripe);
		}

		public function createCustomer($data)
		{
			$customer = $this->stripe->customers->create([
							'name'=> $data['name'],
							'email'=> $data['email'],
							'description' => 'My First Test Customer',
						]);
			return $customer;
		}

		public function getAllCards()
		{
			if (!Auth::user()->customer) {
				return $this->responser([],'This user has not stripe customer account.');
			}

			$acc_id = Auth::user()->customer->account_id;
			if (!$acc_id) {
				return $this->responser([],'No card.');
			}
			try {
				$respns = $this->stripe->customers->allPaymentMethods(
					$acc_id,
					// 'cus_LzpDSKEQJNm27J',
					['type' => 'card']
				);

				return $this->responser($respns, 'customer cards.');

			} catch (Exception $e) {

				return $this->responser([], $e->getMessage());
			}
		}

		public function createCheckoutsession($value='')
		{
			$customer = Auth::user()->customer;
			// print_r(Auth::user()->customer); die();
			try {

			$session = $this->stripe->checkout->sessions->create([
				  'success_url' => 'https://mitabl.xcelanceweb.com/?success=true',
				  'cancel_url' => 'https://mitabl.xcelanceweb.com/',
				  'payment_method_types' => ['card'],
	      		  'mode' => 'setup',
				  'customer' => $customer->account_id,
				]);
			return $this->responser(['url'=>$session->url],'Add card url session.');
			} catch (Exception $e) {
				return $this->responser([], $e->getMessage());
			}
			
		}

		public function createAndAddCard($data)
		{
			// echo "<pre>";
			// print_r($data); die();
			$expDate = explode('/', $data['exp_date']);
			// 
			try {
				$card =	$this->stripe->paymentMethods->create([
					  'type' => 'card',
					  'card' => [
					    'number' => $data['card_number'],
					    'exp_month' => $expDate[0],
					    'exp_year' => $expDate[1],
					    'cvc' => $data['cvc'],
					  ],
					]);
			} catch (Exception $e) {
				return $e->getMessage();
			}
			
			$acc_id = Auth::user()->customer->account_id;	

				// print_r($acc_id); die();
			try {
				$attachCard = $this->stripe->paymentMethods->attach(
							  $card->id,
							  ['customer' => $acc_id]
							);
				return $attachCard;
			} catch (Exception $e) {
				return $e->getMessage();
			}
			

			
		}
		// {
  //                           type: 'custom',
  //                           country: 'US',
  //                           email: user.email,
  //                           business_type: 'individual',
  //                           business_profile:{
  //                               url: 'www.blulight.tech'
  //                           },
  //                           individual:{
  //                               phone: user.phoneNumber,
  //                               email: user.email,
  //                               first_name: user.name.firstName,
  //                               last_name: user.name.lastName,
  //                               dob: {
  //                                   day: user.dateOfBirth.day,
  //                                   month: user.dateOfBirth.month,
  //                                   year: user.dateOfBirth.year
  //                               },
  //                               address:{
  //                                   line1: user.address.line1,
  //                                   line2: user.address.line2,
  //                                   postal_code: user.address.postal_code,
  //                                   city: user.address.city,
  //                                   state: user.address.state
  //                               },
  //                               ssn_last_4: user.dateOfBirth.ssn_last_4,
  //                               verification: {
  //                                   document:{
  //                                       back:  documents[1].id,
  //                                       front:  documents[0].id,
  //                                   }
  //                               }
  //                           },
  //                           tos_acceptance: {
  //                               date: Math.floor(Date.now() / 1000),
  //                               ip: user.ipAddress
  //                           }
  //                       };
		// [
		// 						  'type' => 'custom',
		// 						  'country' => 'AU',
		// 						  'email' => $user->email,
		// 						  'capabilities' => [
		// 						    'card_payments' => ['requested' => true],
		// 						    'transfers' => ['requested' => true],
		// 						  ],
		// 						  'business_type'=> 'individual',
		// 							'business_profile' => [
		// 								// 'industry' => 'food_and_drink__other_food_and_dining',
		// 								'mcc' => 5814,
		// 								'url'=> 'https://mitabl.xcelanceweb.com'
		// 							],
		// 							'individual' => [
		// 								// 'phone'=> '+'.$user->phone,
		//                                 'email'=> $user->email,
		//                                 'first_name'=> $user->first_name,
		//                                 'last_name'=> $user->last_name,
		//          //                        'dob' => [
		//          //                        	'day'=> 03,
		//          //                            'month'=> 03,
		//          //                            'year'=> 1998 
		//          //                        ],
		//          //                        'address' => [
		//          //                        	'line1' => $user->address,
		// 									// 'postal_code' => 4000,
		// 									// 'city' => 'Kangley',
		// 									// 'state' => 'queensland'
		//          //                        ],
		//                                 // 'verification' => [
		//                                 // 	'document' => [
		//                                 // 		'back' => 
		//                                 // 		'front' =>
		//                                 // 	]
		//                                 // ],
		// 							],
		// 							// 'tos_acceptance' => [
		// 							// 	'date' => $date['timestamp'],
  //        //                        		'ip' => $reqIP
		// 							// ],
		// 						]
		public function createVendor($user)
		{
			// AU
			// $carbon = Carbon::date
			$cDate = Carbon::now();
			$date = $cDate->toArray();
			// print_r($date['timestamp']);
			$reqIP = \Request::ip(); 
			// die();
			try {
				$connectedAcc =	$this->stripe->accounts->create([
					'type' => 'express',
					'country' => 'AU',
					'email' => $user->email,
					'capabilities' => [
					    'card_payments' => ['requested' => true],
					    'transfers' => ['requested' => true],
					],
					'business_type'=> 'individual',
					'business_profile' => [
						'mcc' => 5814,
						'url'=> 'https://mitabl.xcelanceweb.com'
					],
					'individual' => [
                        'email'=> $user->email,
                        'first_name'=> $user->first_name,
                        'last_name'=> $user->last_name,
					]
				]);

				return $connectedAcc;
			} catch(\Stripe\Error\Card $e) {
			    // Since it's a decline, \Stripe\Error\Card will be caught
			    // $body = $e->getJsonBody();
			    // $err  = $body['error'];

			    // print('Status is:' . $e->getHttpStatus() . "\n");
			    // print('Type is:' . $err['type'] . "\n");
			    // print('Code is:' . $err['code'] . "\n");

			    //  // param is '' in this case
			    // print('Param is:' . $err['param'] . "\n");
			    // print('Message is:' . $err['message'] . "\n");
			    // die('card');
			    return $e->getMessage();
			} catch (\Stripe\Error\InvalidRequest $e) {
				return $e->getMessage(); 
				// die('invalid');
			    // Invalid parameters were supplied to Stripe's API
			} catch (\Stripe\Error\Authentication $e) {
				return $e->getMessage();
				// die('auth');
			    // Authentication with Stripe's API failed
			    // (maybe you changed API keys recently)
			} catch (\Stripe\Error\ApiConnection $e) {
				return $e->getMessage();
				// die('api');
			    // Network communication with Stripe failed
			} catch (\Stripe\Error\Base $e) {
				return $e->getMessage();
				// die('base');
			    // Display a very generic error to the user, and maybe send
			    // yourself an email
			} catch (Exception $e) {
				return $e->getMessage();
				
			    // Something else happened, completely unrelated to Stripe
			}

		}

		public function createAndAddBankToVendor($data)
		{
			$acc_id = Auth::user()->vendor->account_id;
			try {
				$extrnlBnkAcc =	$this->stripe->accounts->createExternalAccount(
							  $acc_id,
							  [
							    'external_account' => [
							    	'object' => 'bank_account',
							    	'country' => 'AU',
							    	'currency' => 'aud',
							    	'account_holder_name' => $data['holder_name'],
							    	'routing_number' => $data['bsb'],
							    	'account_number' => $data['number'],
							    ],
							  ]
							);
				return $extrnlBnkAcc;
			} catch (Exception $e) {
				return $e->getMessage();
			}
			
		}

		public function createPaymentIntent($order)
		{
			$data['transaction_id'] = \Str::random(18); // random string for transaction id
			$customer_id = User::find($order->user_id)->customer->account_id;
			$request_data = [
                'amount' => $order->total_price * 100, // multiply amount with 100
                'currency' => 'aud',
                'payment_method_types[]' => 'card',
                'customer' => $customer_id,
                // 'payment_method' => 'pm_1LD6DLJ5D9KpYwZ5cfxFbIjh',
                // 'confirm' => true,
                // 'off_session' => true,
                'capture_method' => 'automatic',
                'payment_method_options[card][request_three_d_secure]' => 'automatic',
            ];

            try {

            	return $this->stripe->paymentIntents->create($request_data);

            } catch (Exception $e) {
				return $e->getMessage();
				
			    // Something else happened, completely unrelated to Stripe
			}
            
		}

		public function confirmPaymentIntent($payment)
		{
			// pi_3LDKwuJ5D9KpYwZ50103dgXa

			try {
				return $this->stripe->paymentIntents->confirm(
				  $payment->payment_id,
				  ['payment_method' => $payment->card_id]
				);
			} catch (Exception $e) {
				return $e->getMessage();			
			}
		}

		public function updateConnectedAccount()
		{
			try {
				return $this->stripe->accounts->update(
						  'acct_1LDB9kQvLgPncbX3',
						 	[
								'business_profile' => [
									'mcc' => 5814,
								],
						 		// 'individual' => [
						 		// 	'verification'=> [
							 	// 		'document' => [
							 	// 			'front' => 'file_1LD0WrQt7YPqIHfAzREpbQM5'
							 	// 		]
							 	// 	],
						 		// ],
									
							]
						);
			} catch (Exception $e) {
				return $e->getMessage();
			}
		}

		public function refundAmount($intentId,$amount,$percent)
		{
			$this->stripe = new StripeClient(config('stripe.api_keys.secret_key'));
        	StripeBase::setApiKey(config('stripe.api_keys.secret_key'));

        	$percentInDecimal = $percent / 100;
			$percentDeductAmount = $percentInDecimal * $amount;

			$transferAmount = $amount - $percentDeductAmount;

			try {
				// return $this->stripe->refunds->create([
				//   'charge' => 'ch_3LDKwuJ5D9KpYwZ50vBs00y3',
				// ]);
				return $this->stripe->refunds->create(
					[
						'payment_intent' => $intentId, 
						'amount' => (int) $transferAmount * 100 
					]
				);
			} catch (Exception $e) {
				return $e->getMessage();
			}
		}

		public function getVendorLifetimeAmount()
		{
			$stripe_account_id = Auth::user()->vendor->account_id;

			try {
				return $this->stripe->transfers->all(['destination'=>$stripe_account_id]);
			} catch (Exception $e) {
				return $e->getMessage();
			}
		}

		public function retrieveAccount()
		{

			// payouts_enabled, charges_enabled
			$stripe_account_id = Auth::user()->vendor->account_id;
			try {

				$account = $this->stripe->accounts->retrieve(
						  // 'acct_1LIluoQrSj1ahoqQ',
						  $stripe_account_id,
						  []
						);
				return $account;
			} catch (Exception $e) {
				return $e->getMessage();
			}
			
		}

		public function getVendorBankAcc()
		{
			$connectAccount = $this->retrieveAccount();
			try {

				$extrnlAcc = $this->stripe->accounts->retrieveExternalAccount(
				  $connectAccount->id,
				  $connectAccount->external_accounts->data[0]->id,
				  []
				);

				return $this->responser($extrnlAcc, 'vendor bank account.');
				// return $this->stripe->accounts->deleteExternalAccount(
				//   $connectAccount->id,
				//   $connectAccount->external_accounts->data[0]->id,
				//   []
				// );

			} catch (Exception $e) {
				return $this->responser([], $e->getMessage());
			}
		}

		public function getBankAccFromConect()
		{
			// code...
			$connectAccount = $this->retrieveAccount();

			return $connectAccount->external_accounts->data[0]->id;
		}

		public function checkaccountComplted()
		{
			$connectAccount = $this->retrieveAccount();

			if ($connectAccount->payouts_enabled && $connectAccount->charges_enabled) {
				return true;
			}

			return false;
		}

		public function createAccLoginLink()
		{
			$connectAccount = $this->retrieveAccount();
			
			try {
			
				$return = $this->stripe->accounts->createLoginLink(
				  	$connectAccount->id,
				  	[]
				);
				return $this->responser(['url'=>$return->url],'express account login link');
			} catch (Exception $e) {
				return $this->responser([],$e->getMessage());
			}
		}

		public function transferToVendor($vendor,$tamount,$orderId,$percentToGet,$desc)
		{
			$account_id = $vendor->user->vendor->account_id;
			// print_r($vendor->user->vendor->account_id); die();
			// $percentToGet = 20;
			$percentInDecimal = $percentToGet / 100;
			$percentDeductAmount = $percentInDecimal * $tamount;

			$transferAmount = $tamount - $percentDeductAmount;

			//Print it out - Result is 232.
			// echo (int) $transferAmount; 
			// echo $account_id; 
			// echo $orderId; 
			// die();
			$this->stripe = new StripeClient(config('stripe.api_keys.secret_key'));
        	StripeBase::setApiKey(config('stripe.api_keys.secret_key'));
			try {
				$trnsferData = $this->stripe->transfers->create([
								  'amount' => (int) $transferAmount * 100,
								  'currency' => 'aud',
								  'destination' => $account_id,
								  'transfer_group' => 'ORDER_'.$orderId,
								  'description' => $desc
								]);
				return $trnsferData;
			} catch (Exception $e) {
				return $e->getMessage();
			}
		}

		public function topups()
		{
			try {
				return $this->stripe->topups->create(
					[
					'amount' => 2000,
					'currency' => 'aud',
					'description' => 'Top-up for week of May 31',
					'statement_descriptor' => 'Weekly top-up',
					]
				);
			} catch (Exception $e) {
				return $e->getMessage();
			}
		}

		public function onboardingLink($value='')
		{
			$stripe_account_id = Auth::user()->vendor->account_id;

			try {
				$accLink = $this->stripe->accountLinks->create([
				  'account' => $stripe_account_id,
				  'refresh_url' => 'https://mitabl.xcelanceweb.com/',
				  'return_url' => 'https://mitabl.xcelanceweb.com/?success=true',
				  'type' => 'account_onboarding',
				]);

				return $this->responser(['url'=>$accLink->url], 'On boarding Url');
			} catch (Exception $e) {
				return $this->responser([], $e->getMessage());
			}
			
		}
	}

?>