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
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\DB;
use Illuminate\Database\QueryException;
use Tymon\JWTAuth\Exceptions\JWTException;
use Illuminate\Support\Facades\Mail;
use App\Mail\sendOTP;
use Carbon\Carbon;
use App\Models\CookingStyles;
use App\Models\SpecialDiet;
use App\Models\StripeAccount;
use App\Models\StripeBankAccount;
use App\Models\Mikitchn;
use App\Models\UserAuthToken;
use App\Traits\GoogleAddress;
use App\Services\AuthService;
use App\Services\PaymentService;
use App\Http\Controllers\Api\V2\AccountController as V2AccountController;
use App\Http\Controllers\Api\V2\PaymentsController as V2PaymentsController;
use Throwable;
use JWTAuth;

class UserController extends Controller
{
    use GoogleAddress;
    private AuthService $authService;
    private PaymentService $paymentService;
    private V2AccountController $v2AccountController;
    private V2PaymentsController $v2PaymentsController;

    public function __construct(
        AuthService $authService,
        PaymentService $paymentService,
        V2AccountController $v2AccountController,
        V2PaymentsController $v2PaymentsController
    )
    {
        $this->authService = $authService;
        $this->paymentService = $paymentService;
        $this->v2AccountController = $v2AccountController;
        $this->v2PaymentsController = $v2PaymentsController;
    }

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
        $validator = Validator::make($request->all(), [
            'email' => 'required|email',
            'password' => 'required|string|min:8',
        ]);
        if ($validator->fails()) {
            return $this->responser([], $validator->errors()->first(), 422);
        }

        $credentials = $request->only('email', 'password');

        //Request is validated
        //Crean token
        try {
            if (!$token = auth()->attempt($credentials)) {
                return $this->responser([], 'Login credentials are invalid.', 401);
                // return response()->json([
                //     'success' => false,
                //     'message' => 'Login credentials are invalid.',
                // ], 400);
            }
        } catch (JWTException $e) {
            // return $credentials;
            return $this->responser([],'Could not create token.', 500);
            
        }
        $return = [];

        // Get the user data.
        $user = Auth::guard("api")->user();

        if (! $user) {
            return $this->responser([], 'Unable to resolve authenticated user.', 401);
        }

        if ($this->isAdminIdentityRole((int) $user->role_id)) {
            Auth::guard('api')->logout();
            return $this->forbiddenAdminIdentityResponse();
        }

        if ((bool) $user->suspended) {
            Auth::guard('api')->logout();
            return $this->suspendedAccountResponse();
        }

        if ($user->email_verified == 1) {
            if (! $this->hasStripeAccountForRole($user)) {
                $stripeProvisionError = $this->ensureStripeAccountForRole($user);
                if ($stripeProvisionError !== null) {
                    $user->email_verified = 0;
                    $user->save();
                    $this->sendOtp($user->id, $user->email);

                    Auth::guard('api')->logout();
                    return $this->responser(
                        [],
                        'Your account verification needs to be retried. A new OTP has been sent to your email.',
                        422
                    );
                }
            }

            $previousToken = (string) optional($user->Token)->latest_token;
            if ($previousToken !== '') {
                try {
                    JWTAuth::setToken($previousToken);
                    JWTAuth::invalidate();
                } catch (Throwable $throwable) {
                    report($throwable);
                }
            }

            UserAuthToken::query()->updateOrCreate(
                ['user_id' => $user->id],
                ['latest_token' => $token]
            );
            
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
            'role_id' => 'nullable|integer|in:2,3',
            'phone' => 'required|numeric',
        ]);

        if($validator->fails()){
            return $this->responser([],$validator->errors()->first(), 422);
        }

        // $device_token = '';

        $roleId = $request->filled('role_id') ? (int) $request->input('role_id') : 3;

        $input = [
            'first_name' => (string) $request->input('first_name'),
            'last_name' => (string) $request->input('last_name'),
            'email' => (string) $request->input('email'),
            'password' => (string) $request->input('password'),
            'phone' => (string) $request->input('phone'),
            'address' => (string) $request->input('address', ''),
            'role_id' => $roleId,
        ];
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
        $validator = Validator::make($request->all(), [
            'user_id' => 'required|integer|exists:users,id',
        ]);

        if ($validator->fails()) {
            return $this->responser([], $validator->errors()->first(), 422);
        }

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

    	return $this->responser([],'User not found', 404);
    }

    public function sendOtp($id,$userEmail)
    {
        return $this->authService->sendOtp((int) $id, (string) $userEmail);
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
        $validator = Validator::make($request->all(), [
            'id' => 'required|integer|exists:users,id',
            'otp' => 'required|digits:6',
        ]);

        if ($validator->fails()) {
            return $this->responser([], $validator->errors()->first(), 422);
        }

        $verifiedUserId = null;
        $response = DB::transaction(function () use ($request, &$verifiedUserId) {
            $otpRecord = verifyOtp::where('user_id', (int) $request->id)->lockForUpdate()->first();
            if (! $otpRecord) {
                return response()->json(["status" => 401, "isSuccess" => false, 'isError' => 'Invalid Otp.','data'=> []], 401);
            }

            if ($otpRecord->locked_until && $otpRecord->locked_until->isFuture()) {
                return $this->responser([], 'Too many attempts. Try again later.', 429);
            }

            if ($otpRecord->expires_at && $otpRecord->expires_at->isPast()) {
                return $this->responser([], 'OTP expired. Please request a new code.', 422);
            }

            $storedOtp = (string) $otpRecord->otp;
            $providedOtp = (string) $request->otp;
            $otpMatched = Hash::check($providedOtp, $storedOtp) || hash_equals($storedOtp, $providedOtp);

            if (! $otpMatched) {
                $attempts = ((int) $otpRecord->attempts) + 1;
                $lockThreshold = 5;
                $lockMinutes = 15;
                $otpRecord->attempts = $attempts;
                if ($attempts >= $lockThreshold) {
                    $otpRecord->locked_until = now()->addMinutes($lockMinutes);
                    $otpRecord->attempts = 0;
                }
                $otpRecord->save();

                return response()->json(["status" => 401, "isSuccess" => false, 'isError' => 'Invalid Otp.','data'=> []], 401);
            }

            $user = User::where('id', (int) $request->id)->lockForUpdate()->first();
            if (! $user) {
                return $this->responser([], 'User not found.', 404);
            }

            if ($this->isAdminIdentityRole((int) $user->role_id)) {
                return $this->forbiddenAdminIdentityResponse();
            }

            if (! in_array((int) $user->role_id, [2, 3], true)) {
                return response()->json([
                    'status' => 422,
                    'isSuccess' => false,
                    'isError' => 'Unsupported account role for mobile authentication.',
                    'data' => [],
                ], 422);
            }

            if ((bool) $user->suspended) {
                return $this->suspendedAccountResponse();
            }

            $verifiedUserId = (int) $user->id;

            return response()->json([
                "status" => 200,
                "isSuccess" => true,
                'message' => 'OTP Verified',
                'data' => [
                    'user' => [
                        'id' => $user->id,
                        'name' => $user->first_name . ' ' . $user->last_name,
                        'email' => $user->email,
                        'role' => $user->role->role,
                    ],
                ],
            ], 200);
        });

        if ($verifiedUserId === null || $response->getStatusCode() !== 200) {
            return $response;
        }

        $verifiedUser = User::query()->find($verifiedUserId);
        if (! $verifiedUser) {
            return $this->responser([], 'User not found.', 404);
        }

        $stripeProvisionError = $this->ensureStripeAccountForRole($verifiedUser);
        if ($stripeProvisionError !== null) {
            $this->sendOtp($verifiedUser->id, $verifiedUser->email);
            return $this->responser([], 'Unable to create Stripe account. A new OTP has been sent, please verify again.', 422);
        }

        DB::transaction(function () use ($verifiedUser): void {
            $user = User::query()->whereKey($verifiedUser->id)->lockForUpdate()->firstOrFail();
            $user->email_verified = 1;
            $user->save();

            verifyOtp::query()->where('user_id', $user->id)->delete();
        });

        $accessToken = auth()->login($verifiedUser, true);
        if ($accessToken) {
            UserAuthToken::query()->updateOrCreate(
                ['user_id' => $verifiedUser->id],
                ['latest_token' => $accessToken]
            );
        }

        $decoded = $response->getData(true);
        $decoded['data']['access_token'] = $accessToken;

        return response()->json($decoded, 200);
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
        $authUser = Auth::guard('api')->user();
        $accessToken = request()->bearerToken();

        $result = DB::transaction(function () use ($authUser) {
            $user = User::whereKey($authUser->id)->lockForUpdate()->firstOrFail();
            $user->role_id = 3;
            $user->save();

            return ['user' => $user->fresh()];
        });
        $user = $result['user'];

        $stripeProvisionError = $this->ensureStripeAccountForRole($user);
        if ($stripeProvisionError !== null) {
            return $this->responser([], (string) $stripeProvisionError, 422);
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

                )
            ];

        return $this->responser($data, 'User Now changed in foodie');

    }

    public function becomeCook(Request $request)
    {
        $authUser = Auth::guard('api')->user();
        $accessToken = request()->bearerToken();

        $result = DB::transaction(function () use ($authUser) {
            $user = User::whereKey($authUser->id)->lockForUpdate()->firstOrFail();
            $user->role_id = 2;
            $user->save();

            return ['user' => $user->fresh()];
        });
        $user = $result['user'];

        $stripeProvisionError = $this->ensureStripeAccountForRole($user);
        if ($stripeProvisionError !== null) {
            return $this->responser([], (string) $stripeProvisionError, 422);
        }

        
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

    public function myProfile(){

        $user = Auth::guard('api')->user();

        $data = new UserResource($user);

        return $this->responser($data, 'User');

    }

    public function update(Request $request){
        return $this->v2AccountController->update($request);
    }

    public function changePassword(Request $request){
        return $this->v2AccountController->changePassword($request);
    }

    public function updateDeviceToken(Request $request)
    {
        return $this->v2AccountController->updateDeviceToken($request);
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
        return $this->v2PaymentsController->addCard($request);
    }

    public function completedOnBoarding(Request $request)
    {
        $kitchen = Auth::user()->restaurant;
        // print_r(Auth::user()); die();
        if (empty($kitchen)) {
            return $this->responser([],'This user has not Kitchen', 404);
        }

        $isCompleted = $this->checkaccountComplted();
        if ($isCompleted) {

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
            return $this->responser([],$validator->errors()->first(), 422);
        }

        if (!Auth::user()->vendor) {
            return $this->responser([],"you don't have stripe vendor connected account.", 403);
        }

        try {
            $stripe_extrnl_bank = $this->paymentService->createAndAddBankToVendor(Auth::user(), $request->all());
        } catch (Throwable $throwable) {
            report($throwable);
            return $this->responser([], 'Unable to add vendor bank account.', 422);
        }
        $userId = Auth::user()->id;
        $bankAccount = new StripeBankAccount();
        $bankAccount->user_id = $userId;
        $bankAccount->stripe_bank_id = $stripe_extrnl_bank->id;

        if ($bankAccount->save()) {
            $kitchen = Auth::user()->restaurant;
            if ($kitchen) {
                $kitchen->status = 1;
                $kitchen->save();
            }
        }


        return $this->responser($bankAccount,'Bank Account Added successfully.');
    }

    public function toggleNotifications(Request $request)
    {
        return $this->v2AccountController->notificationsToggle($request);

    }

    public function delete(Request $request)
    {
        $user = Auth::guard('api')->user();
        UserAuthToken::query()->where('user_id', $user->id)->delete();
        Auth::guard('api')->logout();
        $user->delete();

        return $this->responser($user,'Account Deleted Successfully.');
    }

    public function getMerchantacc()
    {
        return $this->responser(['client' => get_class($this->paymentService->getMerchantAccountClient())], 'stripe client loaded.');
    }

    public function getAllCards()
    {
        return $this->v2PaymentsController->cards(request());
    }

    public function createCheckoutsession()
    {
        return $this->v2PaymentsController->checkoutSession(request());
    }

    public function createPaymentIntent(Request $request)
    {
        return $this->v2PaymentsController->createIntent($request);
    }

    public function confirmPaymentIntent(Request $request)
    {
        return $this->v2PaymentsController->confirmIntent($request);
    }

    public function transferToVendor(Request $request)
    {
        return $this->v2PaymentsController->vendorTransfer($request);
    }

    public function refundFullAmount(Request $request)
    {
        return response()->json([
            'status' => 403,
            'isSuccess' => false,
            'isError' => 'Forbidden. Manual refunds are restricted to admin identities in the web admin panel.',
            'data' => [],
        ], 403);
    }

    public function retrieveAccount()
    {
        if (!Auth::user()->vendor) {
            return $this->responser([], 'you don\'t have stripe vendor connected account.', 403);
        }

        try {
            $account = $this->paymentService->retrieveAccount(Auth::user());
        } catch (Throwable $throwable) {
            report($throwable);
            return $this->responser([], 'Unable to retrieve Stripe account details.', 422);
        }

        return $this->responser($account, 'stripe account details.');
    }

    public function getVendorBankAcc()
    {
        if (!Auth::user()->vendor) {
            return $this->responser([], 'you don\'t have stripe vendor connected account.', 403);
        }

        try {
            $account = $this->paymentService->getVendorBankAccount(Auth::user());
        } catch (Throwable $throwable) {
            report($throwable);
            return $this->responser([], 'Unable to retrieve vendor bank account.', 422);
        }

        return $this->responser($account, 'vendor bank account.');
    }

    public function getBankAccFromConect()
    {
        if (!Auth::user()->vendor) {
            return $this->responser([], 'you don\'t have stripe vendor connected account.', 403);
        }

        try {
            $bankId = $this->paymentService->getBankAccFromConnect(Auth::user());
        } catch (\Throwable $th) {
            return $this->responser([], $th->getMessage(), 422);
        }

        if (!$bankId) {
            return $this->responser([], 'vendor bank account not found.', 404);
        }

        return $this->responser(['bank_id' => $bankId], 'vendor bank account.');
    }

    public function checkaccountComplted()
    {
        if (!Auth::user()->vendor) {
            return false;
        }

        try {
            $result = $this->paymentService->isAccountCompleted(Auth::user());
        } catch (Throwable $throwable) {
            report($throwable);
            return false;
        }

        return $result;
    }

    public function createAccLoginLink()
    {
        if (!Auth::user()->vendor) {
            return $this->responser([], 'you don\'t have stripe vendor connected account.', 403);
        }

        try {
            $link = $this->paymentService->createAccLoginLink(Auth::user());
        } catch (Throwable $throwable) {
            report($throwable);
            return $this->responser([], 'Unable to create account login link.', 422);
        }

        return $this->responser(['url' => $link->url], 'express account login link');
    }

    public function onboardingLink()
    {
        if (!Auth::user()->vendor) {
            return $this->responser([], 'you don\'t have stripe vendor connected account.', 403);
        }

        try {
            $link = $this->paymentService->onboardingLink(Auth::user());
        } catch (Throwable $throwable) {
            report($throwable);
            return $this->responser([], 'Unable to create onboarding link.', 422);
        }

        return $this->responser(['url' => $link->url], 'On boarding Url');
    }

    public function updateConnectedAccount(Request $request)
    {
        if (!Auth::user()->vendor) {
            return $this->responser([], 'you don\'t have stripe vendor connected account.', 403);
        }

        $accountId = (string) optional(Auth::user()->vendor)->account_id;
        if ($accountId === '') {
            return $this->responser([], 'account_id is required.', 422);
        }
        $requestedAccountId = trim((string) $request->input('account_id', ''));
        if ($requestedAccountId !== '' && $requestedAccountId !== $accountId) {
            return $this->responser([], 'You are not authorized to update this connected account.', 403);
        }

        try {
            $updated = $this->paymentService->updateConnectedAccount($accountId);
        } catch (Throwable $throwable) {
            report($throwable);
            return $this->responser([], 'Unable to update connected account.', 422);
        }

        return $this->responser($updated, 'connected account updated.');
    }

    public function topups()
    {
        return response()->json([
            'status' => 403,
            'isSuccess' => false,
            'isError' => 'Forbidden. Top-up operations are restricted to admin identities in the web admin panel.',
            'data' => [],
        ], 403);
    }

    public function mobileContact(Request $request)
    {
        return $this->v2AccountController->mobileContact($request);
    }

    private function isAdminIdentityRole(int $roleId): bool
    {
        return $roleId === 1;
    }

    private function forbiddenAdminIdentityResponse(): JsonResponse
    {
        return response()->json([
            'status' => 403,
            'isSuccess' => false,
            'isError' => 'Forbidden. Admin identities must authenticate via the web admin panel.',
            'data' => [],
        ], 403);
    }

    private function suspendedAccountResponse(): JsonResponse
    {
        return response()->json([
            'status' => 403,
            'isSuccess' => false,
            'isError' => 'Your account is suspended. Please contact support.',
            'data' => [],
        ], 403);
    }

    private function ensureStripeAccountForRole(User $user): ?string
    {
        $accountType = null;
        if ((int) $user->role_id === 3) {
            $accountType = 'customer';
        } elseif ((int) $user->role_id === 2) {
            $accountType = 'vendor';
        }

        if ($accountType === null) {
            return 'Unsupported account role for payment account provisioning.';
        }

        $existing = StripeAccount::query()
            ->where('user_id', $user->id)
            ->where('account_type', $accountType)
            ->first();
        if ($existing && $existing->account_id) {
            return null;
        }

        try {
            if ($accountType === 'customer') {
                $account = $this->paymentService->createCustomer(['name' => $user->first_name, 'email' => $user->email]);
            } else {
                $account = $this->paymentService->createVendor($user);
            }
        } catch (Throwable $throwable) {
            report($throwable);
            return 'Unable to create Stripe account.';
        }
        if (!is_object($account) || !isset($account->id)) {
            return 'Unable to create Stripe account.';
        }

        try {
            DB::transaction(function () use ($user, $accountType, $account): void {
                $locked = StripeAccount::query()
                    ->where('user_id', $user->id)
                    ->where('account_type', $accountType)
                    ->lockForUpdate()
                    ->first();
                if ($locked && $locked->account_id) {
                    return;
                }

                StripeAccount::query()->updateOrCreate(
                    ['user_id' => $user->id, 'account_type' => $accountType],
                    ['account_id' => (string) $account->id]
                );
            });
        } catch (QueryException $exception) {
            report($exception);
            $existing = StripeAccount::query()
                ->where('user_id', $user->id)
                ->where('account_type', $accountType)
                ->first();
            if (! $existing || ! $existing->account_id) {
                return 'Unable to create Stripe account.';
            }
        }

        return null;
    }

    private function hasStripeAccountForRole(User $user): bool
    {
        if ((int) $user->role_id === 3) {
            return (bool) optional($user->customer)->account_id;
        }

        if ((int) $user->role_id === 2) {
            return (bool) optional($user->vendor)->account_id;
        }

        return false;
    }

}
