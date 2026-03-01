<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\User\UserController;
use App\Http\Controllers\Api\MikitchnController;
use App\Http\Controllers\Api\ResetPasswordController;
use App\Http\Controllers\Api\FoodsController;
use App\Http\Controllers\Api\ReviewController;
use App\Http\Controllers\Api\FavoriteController;
use App\Http\Controllers\Api\OrderController;
use App\Http\Controllers\Api\FcmController;
use App\Http\Controllers\Api\SupportTicketController;
use App\Http\Controllers\Api\PreRegistrationController;
use App\Services\SystemHealthService;
/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| is assigned the "api" middleware group. Enjoy building your API!
|
*/

// Route::middleware('auth:sanctum')->get('/user', function (Request $request) {
//     return $request->user();
// });

Route::get('/health', function () {
    return response('ok', 200)
                  ->header('Content-Type', 'text/plain');
});
Route::get('/health/live', function () {
    return response()->json([
        'status' => 'ok',
        'timestamp' => now()->toISOString(),
    ]);
});
Route::get('/health/startup', function () {
    return response()->json([
        'status' => 'ok',
        'app_env' => config('app.env'),
        'timestamp' => now()->toISOString(),
    ]);
});
Route::get('/health/ready', function (SystemHealthService $healthService) {
    $summary = $healthService->runChecks();
    $errorCount = collect($summary['checks'] ?? [])->where('status', 'error')->count();
    $isReady = $errorCount === 0;

    return response()->json($summary, $isReady ? 200 : 503);
});
Route::post('login', [UserController::class, 'login']);
Route::post('register', [UserController::class, 'register']);
Route::post('verifyOtp', [UserController::class, 'verifyOtp']);
Route::post('resendotp', [UserController::class, 'resendOtp']);

Route::post('password/reset', [ResetPasswordController::class, 'sendResetLinkResponse']);


Route::post('preregister', [PreRegistrationController::class, 'store'])->middleware('throttle:pre-register-intake');

Route::any('/mobcontact', function () {
    return response()->json([
        'message' => 'Deprecated endpoint. Use /api/v2/mob-contact.',
        'migration_guide' => '/docs/MOBILE_APP.md#contact-endpoint-migration',
    ], 410)
        ->header('Deprecation', 'true')
        ->header('Sunset', 'Wed, 01 Jul 2026 00:00:00 GMT')
        ->header('Link', '</api/v2/mob-contact>; rel="successor-version"');
});


Route::post('support/ticket', [SupportTicketController::class, 'store'])->middleware('throttle:support-intake');
Route::get('support/ticket/{id}', [SupportTicketController::class, 'show'])->middleware('throttle:support-read');
Route::post('support/ticket/{id}/reply', [SupportTicketController::class, 'reply'])->middleware('throttle:support-reply');


// Route::group(['prefix' => 'v1/kitchen', 'namespace' => 'Api'], function ($router) { 
// });
// add card to customer
	// Route::post('addcard', [UserController::class, 'addCardToCustomer']);


Route::group(['prefix' => 'v2', 'middleware' => ['auth:api', 'api.user.active']], function ($router) {
    Route::get('mob-contact', [UserController::class, 'mobileContact']);
});

Route::get('v1/mob-contact', function () {
    return response()->json([
        'message' => 'v1/mob-contact has been sunset. Use v2/mob-contact before 2026-07-01.',
        'migration_guide' => '/docs/MOBILE_APP.md#contact-endpoint-migration',
    ], 410)
        ->header('Deprecation', 'true')
        ->header('Sunset', 'Wed, 01 Jul 2026 00:00:00 GMT')
        ->header('Link', '</api/v2/mob-contact>; rel="successor-version"');
});

Route::group(['prefix' => 'v1', 'middleware' => ['auth:api', 'api.user.active']], function ($router){

	Route::post('changepassword', [UserController::class, 'changePassword']);

	Route::get('getmerchant', [UserController::class, 'getMerchantacc']);


	Route::post('logout', [UserController::class, 'logout']);

	Route::post('editprofile', [UserController::class, 'update']);

	Route::post('updatedevicetoken', [UserController::class, 'updateDeviceToken']);

	Route::post('cancelorder', [OrderController::class, 'orderCancelWithReason']);

	Route::get('getorderdetails/{id}', [OrderController::class, 'getOrderDetails']);

	Route::get('getcookingstyles', [UserController::class, 'getCookingStyles']);
	Route::get('getspecialdiets', [UserController::class, 'getSpecialDiets']);

	Route::get('getnotifications', [FcmController::class, 'getAllNotifications']);

	Route::get('togglenotifications', [UserController::class, 'toggleNotifications']);
	
	Route::delete('deleteuser', [UserController::class, 'delete']);

	Route::get('getallpartners', [MikitchnController::class, 'getPartners']);
	//Routes only restaurant user can access
	Route::group(['middleware' => ['restaurant']], function () {
		
		Route::post('addcertificate', [MikitchnController::class, 'addCertificate']);
		Route::get('checkcertificate', [MikitchnController::class, 'checkCertificate']);

		Route::post('mikitchn/store', [MikitchnController::class, 'store']);
		Route::post('mikitchn/editkitchen', [MikitchnController::class, 'store']);

		//image delete
		Route::post('deleteimage', [MikitchnController::class, 'deleteImage']);


		//Review
		Route::get('reviewOfRestaurant', [ReviewController::class, 'reviewOfRestaurant']);

		//menu
		Route::get('mymenu', [MikitchnController::class, 'getMyMenu']);

		Route::post('food/add', [FoodsController::class, 'store']);
		Route::post('food/editfood', [FoodsController::class, 'store']);
		Route::delete('food/{id}', [FoodsController::class, 'destroy']);
		Route::get('food/status/{id}', [FoodsController::class, 'statusUpdate']);
		Route::get('getprofile', [UserController::class, 'myProfile']);

		//orders

		//review
		Route::post('addreviewtofoodie', [ReviewController::class, 'addReviewToFoodie']);

		// Route::get('upcomingorders', [MikitchnController::class, 'myUpcomingOrders']);
		Route::post('kitchenupcomingorders', [OrderController::class, 'myUpcomingOrderss']);

		Route::get('kitchenorderrequest', [OrderController::class, 'myRequestedOrders']);

		Route::post('allorders', [OrderController::class, 'allOrders']);

		Route::post('updateorderstatus', [OrderController::class, 'statusUpdate']);
		Route::post('addbankaccount', [UserController::class, 'addBankAccToVendor']);

		Route::get('getdashboarddata', [MikitchnController::class, 'getDashboardData']);

		
		Route::post('updateopenmikitchen', [MikitchnController::class, 'updateOpenMikitchen']);

		Route::put('completedonboarding', [UserController::class, 'completedOnBoarding']);
		
		Route::get('getvendorbankacc', [UserController::class, 'getVendorBankAcc']);

		Route::get('becomefoodie', [UserController::class, 'becomeFoodie']);

		Route::post('transfertovendor', [UserController::class, 'transferToVendor']);

		Route::get('checkaccountcompleted', [UserController::class, 'checkaccountComplted']);
		Route::get('getbankaccfromconect', [UserController::class, 'getBankAccFromConect']);
		Route::get('onboardingLink', [UserController::class, 'onboardingLink']);
		Route::get('editvendorbankaccount', [UserController::class, 'createAccLoginLink']);
		Route::get('retrieveaccount', [UserController::class, 'retrieveAccount']);
		Route::post('updateconnectedaccount', [UserController::class, 'updateConnectedAccount']);

	});

	Route::group(['middleware' => ['customer']], function () {

		// search restaurants
		Route::post('filterRestaurant', [MikitchnController::class, 'filterRestaurant']);
		Route::post('nearestRestaurant', [MikitchnController::class, 'nearestRestaurant']);
		Route::post('topRatedRestaurant', [MikitchnController::class, 'topRatedRestaurant']);

		Route::post('recommendedrestaurant', [MikitchnController::class, 'recommendedRestaurant']);


		Route::get('viewRestaurant/{id}', [MikitchnController::class, 'viewRestaurant']);

		Route::post('toggleFavoriteRestaurant', [FavoriteController::class, 'toggleFavorite']);
		Route::get('getFavoritesList', [FavoriteController::class, 'getFavoritesList']);

		//review
		Route::post('addReviewToRestaurant', [ReviewController::class, 'addReviewToRestaurant']);
		Route::get('getnikitchenreviews/{id}', [ReviewController::class, 'getKitchenReviews']);
		// Order

		Route::post('applypromocode', [OrderController::class, 'checkPromoCode']);

		Route::post('createorder', [OrderController::class, 'store']);

		Route::get('myorderlist', [OrderController::class, 'myorderlist']);

		Route::get('getcustomerprofile', [UserController::class, 'myProfile']);


		Route::get('getallcards', [UserController::class, 'getAllCards']);

		Route::post('makepayment', [OrderController::class, 'makePayment']);

		Route::get('restaurant/menu/{resturantId}', [FoodsController::class, 'foodOfRestaurant']);

		Route::get('getbookeddates/{restaurantId}', [OrderController::class, 'getBookedDates']);
		Route::post('checkbookedtime', [OrderController::class, 'checkBookedTimeByDate']);
		// Route::post('addcard', [UserController::class, 'addCardToCustomer']);

		Route::post('paymentintent', [UserController::class, 'createPaymentIntent']);
		Route::post('confirmpaymentintent', [UserController::class, 'confirmPaymentIntent']);

		Route::get('createCheckoutsession', [UserController::class, 'createCheckoutsession']);
		Route::post('addcard', [UserController::class, 'addCardToCustomer']);

		Route::get('becomecook', [UserController::class, 'becomeCook']);

		Route::get('checkdiscounteduser', [OrderController::class, 'checkDiscountedUser']);

	});
	// Route::get('mob-contact', [UserController::class, 'mobileContact']);

});
