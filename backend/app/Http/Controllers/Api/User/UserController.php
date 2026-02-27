<?php
namespace App\Http\Controllers\Api\User;

use Illuminate\Http\Request;
use App\Http\Controllers\Controller;
use App\Http\Resources\User\User as UserResource;
use App\Http\Resources\User\CookingStyle as CookingStyleResource;
use App\Http\Resources\User\SpecialDiet as SpecialDietResource;
use App\Models\User;
use App\Models\verifyOtp;
use Illuminate\Support\Facades\Auth;
use Validator;
use GuzzleHttp\Client;
use Illuminate\Support\Facades\Hash;
use Tymon\JWTAuth\Exceptions\JWTException;
use Illuminate\Support\Facades\Mail;
use App\Mail\sendOTP;
use Carbon\Carbon;
use App\Models\CookingStyles;
use App\Models\SpecialDiet;
use App\Models\StripeAccount;
use App\Models\StripeBankAccount;
use App\Models\Card;
use App\Models\Mikitchn;
use App\Models\NotifyDisable;
use App\Models\UserAuthToken;
use App\Traits\StripeTrait;
use App\Traits\GoogleAddress;
use App\Events\KitchenVerified;
use JWTAuth;

class UserController extends Controller
{
    use StripeTrait,GoogleAddress;

    /**
     * login api
     *
     * @return \Illuminate\Http\Response
     */

    /**
    * @OA\Post(
    * path="/api/login",
    * summary="login user",
    * description="User Login",
    * operationId="login",
    * tags={"User"},
    * @OA\RequestBody(
    *         @OA\MediaType(
    *            mediaType="multipart/form-data",
    *            @OA\Schema(
    *               type="object",
    *               required={"email","password"},
    *               @OA\Property(property="email", type="string"),
    *               @OA\Property(property="password", type="string")
    *            ),
    *        ),
    *       @OA\MediaType(
    *            mediaType="application/json",
    *            @OA\Schema(
    *               type="object",
    *               required={"email","password"},
    *               @OA\Property(property="email", type="string"),
    *               @OA\Property(property="password", type="string")
    *            ),
    *        ),
    *    ),
    *      @OA\Response(
    *          response=201,
    *          description="All details fetched Successfully",
    *          @OA\JsonContent()
    *       ),
    *      @OA\Response(
    *          response=200,
    *          description="All details fetched Successfully",
    *          @OA\JsonContent()
    *       ),
    *      @OA\Response(
    *          response=422,
    *          description="Unprocessable Entity",
    *          @OA\JsonContent()
    *       ),
    *      @OA\Response(response=400, description="Bad request"),
    *      @OA\Response(response=404, description="Resource Not Found"),
    * )
    */

    public function login(Request $request){

        $credentials = $request->only('email', 'password');

        //Request is validated
        //Crean token
        try {
            if (!$token = auth()->attempt($credentials)) {
                return $this->responser([], 'Login credentials are invalid.');
                // return response()->json([
                //     'success' => false,
                //     'message' => 'Login credentials are invalid.',
                // ], 400);
            }
        } catch (JWTException $e) {
            // return $credentials;
            return $this->responser([],'Could not create token.');
            
        }
        $return = [];

        // Get the user data.
        $user = Auth::guard("api")->user(); 

        if ($user->email_verified == 1) {
            $asgnToken = null;
            if ($user->Token) {
                

                UserAuthToken::where('user_id', $user->id)
                ->first()
                ->update(['latest_token' => $token]);
                // $asgnToken = $token;

                

            } else {

                $UserAuthToken = new UserAuthToken();
                $UserAuthToken->user_id = $user->id;
                $UserAuthToken->latest_token = $token;
                $UserAuthToken->save();

                // $asgnToken = $user->Token->latest_token;

            }

            if ($user->Token) {
                JWTAuth::setToken($user->Token->latest_token);
                JWTAuth::invalidate();
            }
            
            if ($request->has('device_token')) {
                $user->device_token = $request->device_token;
            }
            $user->save();

            $uData = array(
                        'id' => $user->id,
                        'name' => $user->first_name,
                        'role' => $user->role->role,
                        'role_id' => $user->role_id,
                    );

            if ($user->role_id == 2) {
            	$existKitchen = Mikitchn::where('user_id',$user->id)->first();
            	$is_kitchen = 0;
				if ($existKitchen) {
					$is_kitchen = 1;
				}

				$uData['is_kitchen_added'] = $is_kitchen;
            }


            $return = [
                'status' => 200,
                'isSuccess' => true,
                'message' => '',
                'data'=>[
                    'access_token' => $token,
                    'token_type' => 'bearer',
                    // 'expires_in' => auth()->factory()->getTTL() * 60,
                    'user' => $uData
                ]
            ];

        } else{
            $responseOtp = $this->sendOtp($user->id,$user->email);
            $msg = '';
            if ($responseOtp['status'] == 200) {
                $msg = 'UnAuthorized Please Check Your Email To Verify Your Account.';
            } else {
                $msg = 'UnAuthorized.';
            }
            
            $uData = [
            	'id' => $user->id,
                'name' => $user->first_name,
                'role' => $user->role->role,
            	'role_id' => $user->role_id,
            	'is_email_verfied' => 0
            ];

            if ($user->role_id == 2) {
            	$existKitchen = Mikitchn::where('user_id',$user->id)->first();
            	$is_kitchen = 0;
				if ($existKitchen) {
					$is_kitchen = 1;
				}

				$uData['is_kitchen_added'] = $is_kitchen;
            }


            $data['user'] = $uData;
            // $return = [
            //     'response_code' => 200,
            //     'isSuccess' => false,
            //     'isError' => $msg,
            //     'data' => 
            //     
            // ];

            return $this->responser($data,$msg);

        }
        return response()->json($return,$return['status']);

    }

    /**
     * Register api
     *
     * @return \Illuminate\Http\Response
     */
    /**
    * @OA\Post(
    * path="/api/register",
    * summary="Register User",
    * description="User Registration",
    * operationId="register",
    * tags={"User"},
    * @OA\RequestBody(
    *         @OA\MediaType(
    *            mediaType="multipart/form-data",
    *            @OA\Schema(
    *               type="object",
    *               required={"first_name","last_name","email","password","role_id","phone","address"},
    *               @OA\Property(property="first_name", type="string"),
    *               @OA\Property(property="last_name", type="string"),
    *               @OA\Property(property="email", type="string"),
    *               @OA\Property(property="password", type="string"),
    *               @OA\Property(property="role_id", type="integer"),
    *               @OA\Property(property="phone", type="string"),
    *               @OA\Property(property="address", type="string"),
    *            ),
    *        ),
    *        @OA\MediaType(
    *            mediaType="application/json",
    *            @OA\Schema(
    *               type="object",
    *               required={"first_name","last_name","email","password","role_id","phone","address"},
    *               @OA\Property(property="first_name", type="string"),
    *               @OA\Property(property="last_name", type="string"),
    *               @OA\Property(property="email", type="string"),
    *               @OA\Property(property="password", type="string"),
    *               @OA\Property(property="role_id", type="integer"),
    *               @OA\Property(property="phone", type="string"),
    *               @OA\Property(property="address", type="string"),
    *            ),
    *        ),
    *    ),
    *      @OA\Response(
    *          response=201,
    *          description="All details fetched Successfully",
    *          @OA\JsonContent()
    *       ),
    *      @OA\Response(
    *          response=200,
    *          description="All details fetched Successfully",
    *          @OA\JsonContent()
    *       ),
    *      @OA\Response(
    *          response=422,
    *          description="Unprocessable Entity",
    *          @OA\JsonContent()
    *       ),
    *      @OA\Response(response=400, description="Bad request"),
    *      @OA\Response(response=404, description="Resource Not Found"),
    * )
    */
    public function register(Request $request){
        // die('test');
        $validator = Validator::make($request->all(), [
            'first_name' => 'required',
            'last_name' => 'required',
            'email' => 'required|email|unique:users,email',
            'password' => 'required',
            // 'c_password' => 'required|same:password',
            'phone' => 'required|numeric',
        ]);

        if($validator->fails()){
            return $this->responser([],$validator->errors()->first());
        }

        // $device_token = '';

        $input = $request->all();

        $input['password'] = bcrypt($input['password']);
        // echo "<pre>"; 
        $user = User::create($input);

        if ($request->has('device_token')) {
            $user->device_token = $request->device_token;
        }
        // print_r($user); die();
        $user->save();
        $userData['id'] = $user->id;
        
        $userData['name'] = $user->first_name.' '.$user->last_name;
        $userData['email'] = $user->email;
        $userData['role_id'] = $user->role_id;
        $userData['role'] = $user->role->role;
        $this->sendOtp($user->id,$user->email);
        $return = [
            'status' => 200,
            'isSuccess'=>true,
            'message' => 'Registered Successfully.',
            'data'=>$userData,
        ];
        return response()->json($return, 200);
    }

    public function resendOtp(Request $request)
    {
    	$user = User::find($request->user_id);

    	if ($user) {
    		$otpres = $this->sendOtp($user->id,$user->email);
    		if ($otpres['status'] == 200) {
    			$rsend = 1;
                $msg = 'Send Otp Successfully';
            } else {
                $msg = 'UnAuthorized.';
                $rsend = 0;
            }

           return $this->responser(['resend'=>$rsend],$msg);


    	}

    	return $this->responser([],'User not found');
    }

    public function sendOtp($id,$userEmail)
    {

        $otp = rand(1000,9999);
        // Log::info("otp = ".$otp);
        $userOtpExist = verifyOtp::where('user_id',$id)->get()->first();


        if (!empty($userOtpExist)) {
            $sendOtp = verifyOtp::where('user_id','=',$id)->update(['otp' => $otp]);
        } else {
            $sendOtp = verifyOtp::create(['user_id' => $id,'otp' => $otp]);
        }
        
        if($sendOtp){
        // send otp in the email
        $mail_details = [
            'subject' => 'Testing Application OTP',
            'otp' => $otp
        ];
       
         \Mail::to($userEmail)->send(new sendOTP($mail_details));
       
         return array("status" => 200, "message" => "OTP sent successfully");
        }
        else{
            return array("status" => 401, 'message' => 'Invalid');
        }
    }

    /**
    * @OA\Post(
    * path="/api/verifyOtp",
    * summary="user verfiy",
    * description="user verfiy",
    * operationId="verifyOtp",
    * tags={"User"},
    * @OA\RequestBody(
    *         @OA\MediaType(
    *            mediaType="multipart/form-data",
    *            @OA\Schema(
    *               type="object",
    *               required={"id","otp"},
    *               @OA\Property(property="id", type="integer"),
    *               @OA\Property(property="otp", type="integer"),
    *            ),
    *        ),
    *       @OA\MediaType(
    *            mediaType="application/json",
    *            @OA\Schema(
    *               type="object",
    *               required={"id","otp"},
    *               @OA\Property(property="id", type="integer"),
    *               @OA\Property(property="otp", type="integer"),
    *            ),
    *        ),
    *    ),
    *      @OA\Response(
    *          response=201,
    *          description="All details fetched Successfully",
    *          @OA\JsonContent()
    *       ),
    *      @OA\Response(
    *          response=200,
    *          description="All details fetched Successfully",
    *          @OA\JsonContent()
    *       ),
    *      @OA\Response(
    *          response=422,
    *          description="Unprocessable Entity",
    *          @OA\JsonContent()
    *       ),
    *      @OA\Response(response=400, description="Bad request"),
    *      @OA\Response(response=404, description="Resource Not Found"),
    * )
    */

    public function verifyOtp(Request $request){
    
        $checkOtp  = verifyOtp::where([['user_id',$request->id],['otp',$request->otp]])->first();
        // echo "string";
        if($checkOtp){
            $chkstrpaccexist = 0;
            $user = User::where('id',$request->id)->first();

            $user->email_verified = 1;
            $user->save();
            // ->update(['email_verified' => 1]);


            if ($user->role_id == 3) {
                
                $account = $this->createCustomer(['name'=>$user->first_name,'email'=>$user->email]);
                $acc_type = 'customer';
            } elseif($user->role_id == 2){
                $account = $this->createVendor($user);
                $acc_type = 'vendor';
            }
            // echo $account; die();
            if (!is_object($account)) {
                return $this->responser([],$account);
            }

            if ($user->customer) { $chkstrpaccexist++; }
            if ($user->vendor) { $chkstrpaccexist++; }

            if (!$chkstrpaccexist) {
                $stripeAccount = new StripeAccount();
                $stripeAccount->user_id = $user->id;
                $stripeAccount->account_type = $acc_type;
                $stripeAccount->account_id = $account->id;
                $stripeAccount->save();
            }
            

            $accessToken = auth()->login($user, true);
            
            if ($accessToken) {
                $UserAuthToken = new UserAuthToken();
                $UserAuthToken->user_id = $user->id;
                $UserAuthToken->latest_token = $accessToken;
                $UserAuthToken->save();
            }

            $return = [
                "status" => 200,
                "isSuccess" => true, 
                'message' => 'OTP Verified',
                'data' => [
                    'user' => [
                        'id' => $user->id,
                        'name' => $user->first_name.' '.$user->last_name,
                        'email' => $user->email,
                        'role' => $user->role->role,
                    ], 
                    'access_token' => $accessToken
                ],   
            ];
            
        }
        else{
            $return = ["status" => 401, "isSuccess" => false, 'isError' => 'Invalid Otp.','data'=> []];
        }
        return response()->json($return,$return['status']);
    }

    /**
     * @OA\Post(
     *      path="/api/v1/logout",
     *      operationId="logout",
     *      tags={"User"},
     *      summary="User Logged out.",
     *      description="Returns Food data",
     *      security={ {"Authorization": {} }},
     *     @OA\Response(
    *          response=201,
    *          description="All details fetched Successfully",
    *          @OA\JsonContent()
    *       ),
    *      @OA\Response(
    *          response=200,
    *          description="All details fetched Successfully",
    *          @OA\JsonContent()
    *       ),
    *      @OA\Response(
    *          response=422,
    *          description="Unprocessable Entity",
    *          @OA\JsonContent()
    *       ),
    *      @OA\Response(response=400, description="Bad request"),
    *      @OA\Response(response=404, description="Resource Not Found"),
     * )
     */
    public function logout(Request $request)
    {
        // $accessToken = Auth::guard('api')->user()->token;
        // $accessToken = Auth::guard('api')->user()->token;
        // $user = JWTAuth::setToken($token)->toUser();
        // $accessToken= request()->bearerToken();
        // return $this->responser($accessToken, 'User logged not out.'); 

        $data = Auth::guard('api')->user();
        Auth::guard('api')->logout();

        return $this->responser($data, 'User logged out.');
        // return response()->json(['data' => 'User logged out.'], 200);
    }

    public function becomeFoodie(Request $request)
    {
        $user = Auth::guard('api')->user();
        $user->role_id = 3;
        $user->save();
        $accessToken= request()->bearerToken();
        $isCustomer = $user->customer;
         
        if (!is_object($isCustomer) && $isCustomer == '') {
            $account = $this->createCustomer(['name'=>$user->first_name,'email'=>$user->email]);
            if (!is_object($account)) {
                return $this->responser([],$account);
            }else{
                $stripeAccount = new StripeAccount();
                $stripeAccount->user_id = $user->id;
                $stripeAccount->account_type = 'customer';
                $stripeAccount->account_id = $account->id;
                $stripeAccount->save();
            }
        }

        $user = User::find($user->id);

        $data = [
                'access_token' => $accessToken,
                'token_type' => 'bearer',
                // 'expires_in' => auth()->factory()->getTTL() * 60,
                'user' => array(
                    'id' => $user->id,
                    'name' => $user->first_name,
                    'role' => $user->role->role,
                    'role_id' => $user->role_id,

                )
            ];

        return $this->responser($data, 'User Now changed in foodie');

    }

    public function becomeCook(Request $request)
    {
        $user = Auth::guard('api')->user();
        $user->role_id = 2;
        $user->save();
        $accessToken= request()->bearerToken();
        $isVendor = $user->vendor;

        if (!is_object($isVendor) && $isVendor == '') {
            $account = $this->createVendor($user);
            if (!is_object($account)) {
                return $this->responser([],$account);
            }else{
                $stripeAccount = new StripeAccount();
                $stripeAccount->user_id = $user->id;
                $stripeAccount->account_type = 'vendor';
                $stripeAccount->account_id = $account->id;
                $stripeAccount->save();
            }
            
        }
        
        $user = User::find($user->id);

        
    	$existKitchen = Mikitchn::where('user_id',$user->id)->first();
    	$is_kitchen = 0;
		if ($existKitchen) {
			$is_kitchen = 1;
		}
        

        $data = [
                'access_token' => $accessToken,
                'token_type' => 'bearer',
                // 'expires_in' => auth()->factory()->getTTL() * 60,
                'user' => array(
                    'id' => $user->id,
                    'name' => $user->first_name,
                    'role' => $user->role->role,
                    'role_id' => $user->role_id,
                    'is_kitchen_added' => $is_kitchen,
                )
            ];

        return $this->responser($data, 'User Now changed in cook');

    }

    public function index(){

        $user = User::OrderBy('id', 'asc')->get();

        $data = UserResource::collection($user);

        return $this->responser($user, $data, 'Users');

    }

    public function myProfile(){

        $user = Auth::guard('api')->user();

        $data = new UserResource($user);

        return $this->responser($data, 'User');

    }

    public function update(Request $request){

        $user = Auth::guard('api')->user();

        $validator = Validator::make($request->all(), [
            'first_name' => 'required',
            'last_name' => 'required',
            'phone' => 'required',
            'email' => 'required|email|unique:users,email,'.$user->id
        ]);

        if($validator->fails()){
            return $this->responser([],$validator->errors()->first());
        }

        $user->first_name = $request->first_name;
        $user->last_name = $request->last_name;
        $user->email = $request->email;
        
        $user->phone = $request->phone;
        $user->description = $request->description;
        if ($request->hasFile('avatar')) {
            $avatar = $this->uploadImage($request->avatar,'user');
            if ($avatar['success']) {
                $user->avatar = $avatar['path'];
            } else {
                return $this->responser($data, $avatar['msg']);
            }
        }

        $user->save();

        $data = new UserResource($user);
        return $this->responser($data, 'User Profile Updated');
    }

    public function changePassword(Request $request){

        $validator = Validator::make($request->all(), [
            'current_password' => 'required',
            'new_password' => 'required|different:current_password'
        ]);

        if($validator->fails()){
            return $this->responser([],$validator->errors()->first());
        }

        $user = Auth::user();
        $oldpass = $request->current_password;
        $ok = password_verify($oldpass, $user->password);
        if ( $ok == true) {
            // if($request->new_password == $request->confirm__password){
                $user->password = bcrypt($request->new_password);
                $user->save();
                return $this->responser($user,'User Password Updated successfully');
            // } else {
                // return $this->responser([],'Password doesn\'t match');
            // }
        } else {
            return $this->responser([],'Current password doesn\'t match');
        }
    }

    public function updateDeviceToken(Request $request)
    {
        $user = Auth::guard('api')->user();
        if ($request->has('device_token')) {
            $user->device_token = $request->device_token;
            $user->save();
        }

        return $this->responser($user,'Device Token Updated.');
    }

    public function getCookingStyles()
    {
        $cStyles = CookingStyles::all();
        $data = CookingStyleResource::collection($cStyles);
        return $this->responser($data,'All Cooking styles.');
    }

    public function getSpecialDiets()
    {
        $specialDiets = SpecialDiet::all();
        $data = SpecialDietResource::collection($specialDiets);
        return $this->responser($data,'All Special Diets.');
    }

    public function addCardToCustomer(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required',
            'card_number' => 'required',
            'exp_date' => 'required',
            'cvc' => 'required'
        ]);

        if($validator->fails()){    
            return $this->responser([],$validator->errors()->first());
        }

        // echo "<pre>";
        // print_r(Auth::user()); die();

        if (!Auth::user()->customer) {
            return $this->responser([],"you don't have stripe customer account.");
        }
        // die('enter');
        $stripe_card = $this->createAndAddCard($request->all());

        $card = new Card();
        $card->user_id = Auth::user()->id;
        $card->stripe_card_id = $stripe_card->id;
        $card->save();

        return $this->responser($card,'Card Added successfully.');
    }

    public function completedOnBoarding(Request $request)
    {
        $kitchen = Auth::user()->restaurant;
        // print_r(Auth::user()); die();
        if (empty($kitchen)) {
            return $this->responser([],'This user has not Kitchen');
        }

        if ($this->checkaccountComplted()) {

            $kitchen->status = 1;
            $kitchen->save();

        }

        return $this->responser($kitchen,'Kitchen stripe on boarding process completed');
    }


    public function addBankAccToVendor(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'holder_name' => 'required',
            'bsb' => 'required',
            'number' => 'required'
        ]);

        if($validator->fails()){    
            return $this->responser([],$validator->errors()->first());
        }

        if (!Auth::user()->vendor) {
            return $this->responser([],"you don't have stripe vendor connected account.");
        }

        $stripe_extrnl_bank = $this->createAndAddBankToVendor($request->all());
        if (!is_object($stripe_extrnl_bank)) {
            return $this->responser([],$stripe_extrnl_bank);
        }
        $userId = Auth::user()->id;
        $bankAccount = new StripeBankAccount();
        $bankAccount->user_id = $userId;
        $bankAccount->stripe_bank_id = $stripe_extrnl_bank->id;

        if ($bankAccount->save()) {
            $kitchen = Auth::user()->restaurant;
            $kitchen->status = 1;
            $kitchen->save();
        }


        return $this->responser($bankAccount,'Bank Account Added successfully.');
    }

    public function toggleNotifications(Request $request)
    {
        $user = Auth::user();

        $exitsInNotify = NotifyDisable::where('user_id',$user->id)->get()->first();
        if ($exitsInNotify) {
            $exitsInNotify->delete();
        } else {
            $notifyDisable = new NotifyDisable();
            $notifyDisable->user_id = $user->id;
            $notifyDisable->save();
        }
        
        return $this->responser($user,'User notifications updated successfully.');

    }

    public function delete(Request $request)
    {
        $user = Auth::guard('api')->user();
        $user->delete();

        return $this->responser($user,'Account Deleted Successfully.');
    }

    public function mobileContact(Request $request)
    {
        $user = Auth::user();
        // $user = User::find(25);
        $rspn = ['role' => $user->role_id,'id' => $user->id,'email' => $user->email,'phone' => $user->phone ];
        return $this->responser($rspn,'User details.');
    }

}
