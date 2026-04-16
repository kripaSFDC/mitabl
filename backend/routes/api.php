<?php

use App\Http\Controllers\Api\AppVersionController;
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
use App\Http\Controllers\Api\V2\AccountFoodieController as V2AccountFoodieController;
use App\Http\Controllers\Api\FcmController;
use App\Http\Controllers\Api\ReviewController;
use App\Http\Controllers\Api\DineInSlotController;
use App\Http\Controllers\Api\CancellationPolicyController;
use App\Services\SystemHealthService;
use Illuminate\Http\Request;
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

// DEV ONLY: reset OTP to a known value and return it (local/testing only)
Route::get('/dev/otp/{userId}', function ($userId) {
    if (!in_array(config('app.env'), ['local', 'testing'])) {
        abort(404);
    }
    $knownOtp = '123456';
    \DB::table('verify_otps')->updateOrInsert(
        ['user_id' => $userId],
        [
            'otp' => \Hash::make($knownOtp),
            'expires_at' => now()->addMinutes(30),
            'attempts' => 0,
            'locked_until' => null,
            'updated_at' => now(),
        ]
    );
    return response()->json(['otp' => $knownOtp]);
});

// Mobile app version gate — no auth required.
// Returns minimum/latest version info for the update check dialog.
Route::get('/app/version', [AppVersionController::class, 'show'])
    ->middleware('throttle:public-api');

Route::post('login', [UserController::class, 'login'])->middleware('throttle:mobile-login');
Route::post('token/refresh', [UserController::class, 'refreshToken'])->middleware('throttle:mobile-token-refresh');
Route::post('register', [UserController::class, 'register'])->middleware('throttle:mobile-register');
Route::post('verifyOtp', [UserController::class, 'verifyOtp'])->middleware('throttle:mobile-verify-otp');
Route::post('resendotp', [UserController::class, 'resendOtp'])->middleware('throttle:mobile-resend-otp');

Route::post('password/reset', [ResetPasswordController::class, 'sendResetLinkResponse']);
Route::post('stripe/webhook', [StripeWebhookController::class, 'handle']);
Route::get('v2/payments/payment-method-entry', [V2PaymentsController::class, 'paymentMethodForm']);


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

Route::get('support/tickets', [SupportTicketController::class, 'index'])->middleware(['auth:api', 'throttle:support-read']);
Route::post('support/ticket', [SupportTicketController::class, 'store'])->middleware('throttle:support-intake');
Route::get('support/ticket/{id}', [SupportTicketController::class, 'show'])->middleware('throttle:support-read');
Route::post('support/ticket/{id}/reply', [SupportTicketController::class, 'reply'])->middleware('throttle:support-reply');
Route::post('orders', [OrderController::class, 'store'])->middleware(['auth:api', 'api.user.active', 'customer']);

$registerLegacyMobileRoutes = function (): void {
    Route::post('editprofile', [UserController::class, 'update']);
    Route::get('getcookingstyles', [UserController::class, 'getCookingStyles']);
    Route::get('getspecialdiets', [UserController::class, 'getSpecialDiets']);

    Route::group(['middleware' => ['restaurant']], function () {
        Route::post('mikitchn/store', [MikitchnController::class, 'createKitchen']);
        Route::post('mikitchn/editkitchen', [MikitchnController::class, 'updateKitchen']);
        Route::post('deleteimage', [MikitchnController::class, 'deleteImage']);
        Route::get('mymenu', [MikitchnController::class, 'getMyMenu']);
        Route::get('mikitchn/dine-in-slots', [DineInSlotController::class, 'index']);
        Route::put('mikitchn/dine-in-slots/sync', [DineInSlotController::class, 'sync']);
        Route::post('mikitchn/dine-in-slots', [DineInSlotController::class, 'store']);
        Route::put('mikitchn/dine-in-slots/{id}', [DineInSlotController::class, 'update']);
        Route::delete('mikitchn/dine-in-slots/{id}', [DineInSlotController::class, 'destroy']);
        Route::get('mikitchn/cancellation-policy', [CancellationPolicyController::class, 'show']);
        Route::put('mikitchn/cancellation-policy', [CancellationPolicyController::class, 'update']);
        Route::post('food/add', [FoodsController::class, 'createFood']);
        Route::post('food/editfood', [FoodsController::class, 'updateFood']);
        Route::delete('food/{id}', [FoodsController::class, 'destroy']);
        Route::post('food/status/{id}', [FoodsController::class, 'statusUpdate']);
        Route::get('getprofile', [UserController::class, 'myProfile']);
        Route::get('kitchenupcomingorders', [OrderController::class, 'myUpcomingOrders']);
        Route::get('kitchenorderrequest', [OrderController::class, 'myRequestedOrders']);
        Route::get('allorders', [OrderController::class, 'allOrders']);
        Route::get('getdashboarddata', [MikitchnController::class, 'getDashboardData']);
    });

    Route::group(['middleware' => ['customer']], function () {
        Route::get('getcustomerprofile', [UserController::class, 'myProfile']);
    });
};

Route::group(['prefix' => 'v2', 'middleware' => ['auth:api', 'api.user.active']], function ($router) use ($registerLegacyMobileRoutes) {
	Route::get('mob-contact', [UserController::class, 'mobileContact']);
    Route::post('logout', [UserController::class, 'logout']);
    Route::middleware(['customer', 'throttle:order-create'])->post('orders', [OrderController::class, 'store']);
    Route::post('updateorderstatus', [OrderController::class, 'statusUpdate']);

    // Legacy-mobile compatibility aliases retained under /v2 during migration.
    $registerLegacyMobileRoutes();

	Route::prefix('account')->group(function () {
			Route::get('profile', [V2AccountController::class, 'show']);
            Route::middleware('customer')->group(function () {
            Route::get('orders', [V2AccountFoodieController::class, 'orders']);
            Route::get('favorites', [V2AccountFoodieController::class, 'favorites']);
            Route::post('favorites/toggle', [V2AccountFoodieController::class, 'toggleFavorite']);
            Route::get('payments/history', [V2AccountFoodieController::class, 'paymentHistory']);
            Route::middleware('throttle:order-create')->post('orders', [OrderController::class, 'store']);
            });
			Route::put('profile', [V2AccountController::class, 'update']);
            Route::delete('delete', [UserController::class, 'delete'])->middleware('throttle:account-delete');
            Route::post('delete', [UserController::class, 'delete'])->middleware('throttle:account-delete');
			Route::post('switch-role', [V2AccountController::class, 'switchRole']);
            Route::post('roles/cook/activate', [V2AccountController::class, 'startCookOnboarding']);
            Route::post('onboarding/cook/start', [V2AccountController::class, 'startCookOnboarding']);
            Route::post('onboarding/cook/vendor-account', [V2AccountController::class, 'completeCookVendorAccountStep']);
			Route::get('dashboard', [MikitchnController::class, 'getDashboardData'])->middleware('restaurant');
		Route::post('password/change', [V2AccountController::class, 'changePassword']);
		Route::post('device-token', [V2AccountController::class, 'updateDeviceToken']);
		Route::post('notifications/toggle', [V2AccountController::class, 'notificationsToggle']);
        Route::post('notification-preferences', [V2AccountController::class, 'updateNotificationPreferences']);
		Route::get('mobile-contact', [V2AccountController::class, 'mobileContact']);
		Route::get('dietary-preferences', function () {
			return response()->json([
				'preferences' => auth()->user()->dietaryPreferences->pluck('id'),
			]);
		});
		Route::put('dietary-preferences', function (\Illuminate\Http\Request $request) {
			$validated = $request->validate([
				'preference_ids' => 'required|array',
				'preference_ids.*' => 'integer|exists:special_diets,id',
			]);
			auth()->user()->dietaryPreferences()->sync($validated['preference_ids']);
			return response()->json([
				'preferences' => auth()->user()->fresh()->dietaryPreferences->pluck('id'),
			]);
		});
	});

	// Notifications
	Route::get('notifications', [FcmController::class, 'getAllNotifications']);
	Route::put('notifications/{id}/read', function ($id) {
		$notification = auth()->user()->notifications()->findOrFail($id);
		$notification->markAsRead();
		return response()->json(['status' => 'ok']);
	});

	// Reviews
	Route::post('addreviewtorestaurant', [ReviewController::class, 'addReviewToRestaurant']);

	// Kitchen open/close toggle (cook only)
	Route::middleware('restaurant')->post('mikitchn/toggle-open', function (Request $request) {
		$kitchen = \App\Models\Mikitchn::where('user_id', auth()->id())->firstOrFail();
		$kitchen->update(['open' => $kitchen->open ? 0 : 1]);
		return response()->json(['open' => (bool) $kitchen->open]);
	});

	// Single order detail and no-show
	Route::middleware('restaurant')->post('orders/{id}/no-show', [CancellationPolicyController::class, 'noShow']);
	Route::get('orders/{id}', function ($id) {
		$order = \App\Models\Order::with(['mikitchn', 'user', 'orderData.food'])
			->where(function ($q) {
				$q->where('user_id', auth()->id())
				  ->orWhereHas('mikitchn', fn($q2) => $q2->where('user_id', auth()->id()));
			})
			->findOrFail($id);
		return new \App\Http\Resources\Order\Order($order);
	});

	Route::prefix('discovery')->group(function () {
		Route::get('filtered', [V2DiscoveryController::class, 'filtered']);
		Route::get('nearest', [V2DiscoveryController::class, 'nearest']);
		Route::get('top-rated', [V2DiscoveryController::class, 'topRated']);
		Route::get('recommended', [V2DiscoveryController::class, 'recommended']);
		Route::get('search', [V2DiscoveryController::class, 'search']);
		Route::get('restaurants/{id}', [V2DiscoveryController::class, 'show']);
		Route::get('restaurants/{id}/menu', [V2DiscoveryController::class, 'menu']);
		Route::get('restaurants/{id}/dine-in-slots', [V2DiscoveryController::class, 'dineInSlots']);
	});

	Route::prefix('payments')->group(function () {
		Route::get('cards', [V2PaymentsController::class, 'cards']);
		Route::post('cards', [V2PaymentsController::class, 'addCard']);
		Route::post('checkout-session', [V2PaymentsController::class, 'checkoutSession']);
		Route::post('intent', [V2PaymentsController::class, 'createIntent']);
		Route::post('intent/confirm', [V2PaymentsController::class, 'confirmIntent']);
		Route::post('vendor/bank-account', [UserController::class, 'addBankAccToVendor']);
		Route::get('vendor/bank-account', [UserController::class, 'getVendorBankAcc']);
		Route::get('vendor/bank-account/id', [UserController::class, 'getBankAccFromConect']);
		Route::get('vendor/account', [UserController::class, 'retrieveAccount']);
		Route::get('vendor/onboarding-link', [UserController::class, 'onboardingLink']);
		Route::get('vendor/login-link', [UserController::class, 'createAccLoginLink']);
		Route::get('vendor/account/completed', [UserController::class, 'accountCompletionStatus']);
		Route::post('vendor/account/refresh', [UserController::class, 'updateConnectedAccount']);
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
    Route::post('logout', [UserController::class, 'logout']);
});

Route::get('v1/food/status/{id}', function () {
    return response()->json([
        'status' => 405,
        'isSuccess' => false,
        'isError' => true,
        'message' => 'Method not allowed. Use POST /api/v1/food/status/{id}.',
        'data' => [],
    ], 405);
});

Route::get('v2/payments/checkout-session', function () {
    return response()->json([
        'status' => 405,
        'isSuccess' => false,
        'isError' => true,
        'message' => 'Method not allowed. Use POST /api/v2/payments/checkout-session.',
        'data' => [],
    ], 405);
});

Route::get('v2/food/status/{id}', function () {
    return response()->json([
        'status' => 405,
        'isSuccess' => false,
        'isError' => true,
        'message' => 'Method not allowed. Use POST /api/v2/food/status/{id}.',
        'data' => [],
    ], 405);
});
