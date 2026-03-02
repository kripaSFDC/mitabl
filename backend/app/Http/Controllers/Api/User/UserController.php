<?php

namespace App\Http\Controllers\Api\User;

use App\Http\Controllers\Api\User\Concerns\HandlesUserAuthentication;
use App\Http\Controllers\Api\User\Concerns\HandlesUserPayments;
use App\Http\Controllers\Api\V2\AccountController as V2AccountController;
use App\Http\Controllers\Api\V2\PaymentsController as V2PaymentsController;
use App\Http\Controllers\Controller;
use App\Http\Resources\User\CookingStyle as CookingStyleResource;
use App\Http\Resources\User\SpecialDiet as SpecialDietResource;
use App\Http\Resources\User\User as UserResource;
use App\Models\CookingStyles;
use App\Models\SpecialDiet;
use App\Services\AuthService;
use App\Services\PaymentService;
use App\Traits\GoogleAddress;
use Illuminate\Http\Request;

class UserController extends Controller
{
    use GoogleAddress;
    use HandlesUserAuthentication;
    use HandlesUserPayments;

    private AuthService $authService;
    private PaymentService $paymentService;
    private V2AccountController $v2AccountController;
    private V2PaymentsController $v2PaymentsController;

    public function __construct(
        AuthService $authService,
        PaymentService $paymentService,
        V2AccountController $v2AccountController,
        V2PaymentsController $v2PaymentsController
    ) {
        $this->authService = $authService;
        $this->paymentService = $paymentService;
        $this->v2AccountController = $v2AccountController;
        $this->v2PaymentsController = $v2PaymentsController;
    }

    public function myProfile()
    {
        $user = auth()->guard('api')->user();
        $data = new UserResource($user);

        return $this->responser($data, 'User');
    }

    public function update(Request $request)
    {
        return $this->v2AccountController->update($request);
    }

    public function changePassword(Request $request)
    {
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

        return $this->responser($data, 'All Cooking styles.');
    }

    public function getSpecialDiets()
    {
        $specialDiets = SpecialDiet::all();
        $data = SpecialDietResource::collection($specialDiets);

        return $this->responser($data, 'All Special Diets.');
    }

    public function toggleNotifications(Request $request)
    {
        return $this->v2AccountController->notificationsToggle($request);
    }

    public function mobileContact(Request $request)
    {
        return $this->v2AccountController->mobileContact($request);
    }
}
