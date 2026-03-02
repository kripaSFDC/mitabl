<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\User\UserController;
use App\Http\Controllers\Api\MikitchnController;
use App\Http\Controllers\Api\ResetPasswordController;
use App\Http\Controllers\Api\FoodsController;
use App\Http\Controllers\Api\OrderController;
use App\Http\Controllers\Api\StripeWebhookController;
use App\Http\Controllers\Api\SupportTicketController;
use App\Http\Controllers\Api\PreRegistrationController;
use App\Http\Controllers\Api\V2\DiscoveryController as V2DiscoveryController;
use App\Http\Controllers\Api\V2\AccountController as V2AccountController;
use App\Http\Controllers\Api\V2\PaymentsController as V2PaymentsController;
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
Route::post('login', [UserController::class, 'login'])->middleware('throttle:10,1');
Route::post('register', [UserController::class, 'register']);
Route::post('verifyOtp', [UserController::class, 'verifyOtp'])->middleware('throttle:10,1');
Route::post('resendotp', [UserController::class, 'resendOtp'])->middleware('throttle:5,1');

Route::post('password/reset', [ResetPasswordController::class, 'sendResetLinkResponse']);
Route::post('stripe/webhook', [StripeWebhookController::class, 'handle']);


Route::post('preregister', [PreRegistrationController::class, 'store'])->middleware('throttle:pre-register-intake');

Route::get('/mobcontact', function () {
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

$registerLegacyMobileRoutes = function (): void {
    Route::post('editprofile', [UserController::class, 'update']);
    Route::get('getcookingstyles', [UserController::class, 'getCookingStyles']);
    Route::get('getspecialdiets', [UserController::class, 'getSpecialDiets']);

    Route::group(['middleware' => ['restaurant']], function () {
        Route::post('mikitchn/store', [MikitchnController::class, 'createKitchen']);
        Route::post('mikitchn/editkitchen', [MikitchnController::class, 'updateKitchen']);
        Route::post('deleteimage', [MikitchnController::class, 'deleteImage']);
        Route::get('mymenu', [MikitchnController::class, 'getMyMenu']);
        Route::post('food/add', [FoodsController::class, 'createFood']);
        Route::post('food/editfood', [FoodsController::class, 'updateFood']);
        Route::delete('food/{id}', [FoodsController::class, 'destroy']);
        Route::post('food/status/{id}', [FoodsController::class, 'statusUpdate']);
        Route::get('getprofile', [UserController::class, 'myProfile']);
        Route::post('kitchenupcomingorders', [OrderController::class, 'myUpcomingOrderss']);
        Route::get('kitchenorderrequest', [OrderController::class, 'myRequestedOrders']);
        Route::post('allorders', [OrderController::class, 'allOrders']);
        Route::post('updateorderstatus', [OrderController::class, 'statusUpdate']);
        Route::get('getdashboarddata', [MikitchnController::class, 'getDashboardData']);
    });

    Route::group(['middleware' => ['customer']], function () {
        Route::get('getcustomerprofile', [UserController::class, 'myProfile']);
    });
};

// Route::group(['prefix' => 'v1/kitchen', 'namespace' => 'Api'], function ($router) { 
// });
// add card to customer
	// Route::post('addcard', [UserController::class, 'addCardToCustomer']);


Route::group(['prefix' => 'v2', 'middleware' => ['auth:api', 'api.user.active']], function ($router) use ($registerLegacyMobileRoutes) {
    Route::get('mob-contact', [UserController::class, 'mobileContact']);
    Route::post('logout', [UserController::class, 'logout']);

    // Legacy-mobile compatibility aliases retained under /v2 during migration.
    $registerLegacyMobileRoutes();

	Route::prefix('account')->group(function () {
		Route::get('profile', [V2AccountController::class, 'show']);
		Route::put('profile', [V2AccountController::class, 'update']);
		Route::post('password/change', [V2AccountController::class, 'changePassword']);
		Route::post('device-token', [V2AccountController::class, 'updateDeviceToken']);
		Route::post('notifications/toggle', [V2AccountController::class, 'notificationsToggle']);
		Route::get('mobile-contact', [V2AccountController::class, 'mobileContact']);
	});

	Route::prefix('discovery')->group(function () {
		Route::get('filtered', [V2DiscoveryController::class, 'filtered']);
		Route::get('nearest', [V2DiscoveryController::class, 'nearest']);
		Route::get('top-rated', [V2DiscoveryController::class, 'topRated']);
		Route::get('recommended', [V2DiscoveryController::class, 'recommended']);
		Route::post('filtered', [V2DiscoveryController::class, 'filtered']);
		Route::post('nearest', [V2DiscoveryController::class, 'nearest']);
		Route::post('top-rated', [V2DiscoveryController::class, 'topRated']);
		Route::post('recommended', [V2DiscoveryController::class, 'recommended']);
		Route::get('restaurants/{id}', [V2DiscoveryController::class, 'show']);
	});

	Route::prefix('payments')->group(function () {
		Route::get('cards', [V2PaymentsController::class, 'cards']);
		Route::post('cards', [V2PaymentsController::class, 'addCard']);
		Route::post('checkout-session', [V2PaymentsController::class, 'checkoutSession']);
		Route::post('intent', [V2PaymentsController::class, 'createIntent']);
		Route::post('intent/confirm', [V2PaymentsController::class, 'confirmIntent']);
		Route::post('vendor-transfer', [V2PaymentsController::class, 'vendorTransfer']);
	});

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

Route::group(['prefix' => 'v1', 'middleware' => ['auth:api', 'api.user.active']], function ($router) use ($registerLegacyMobileRoutes) {
    // Canonical legacy-mobile route surface.
    $registerLegacyMobileRoutes();
    Route::post('logout', [UserController::class, 'logout']);
});

Route::get('v1/food/status/{id}', function () {
    return response()->json([
        'status' => 405,
        'isSuccess' => false,
        'isError' => 'Method not allowed. Use POST /api/v1/food/status/{id}.',
        'data' => [],
    ], 405);
});

Route::get('v2/payments/checkout-session', function () {
    return response()->json([
        'status' => 405,
        'isSuccess' => false,
        'isError' => 'Method not allowed. Use POST /api/v2/payments/checkout-session.',
        'data' => [],
    ], 405);
});

Route::get('v2/food/status/{id}', function () {
    return response()->json([
        'status' => 405,
        'isSuccess' => false,
        'isError' => 'Method not allowed. Use POST /api/v2/food/status/{id}.',
        'data' => [],
    ], 405);
});
