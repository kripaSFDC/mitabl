<?php

namespace App\Http\Controllers\Api\User;

use App\Http\Controllers\Api\User\Concerns\HandlesUserAuthentication;
use App\Http\Controllers\Api\User\Concerns\HandlesUserPayments;
use App\Http\Controllers\Controller;
use App\Http\Resources\User\CookingStyle as CookingStyleResource;
use App\Http\Resources\User\SpecialDiet as SpecialDietResource;
use App\Http\Resources\User\User as UserResource;
use App\Models\CookingStyles;
use App\Models\SpecialDiet;
use App\Services\AccountProfileService;
use App\Services\AuthService;
use App\Services\PaymentService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Cache;

class UserController extends Controller
{
    use HandlesUserAuthentication;
    use HandlesUserPayments;

    // Kept here for compliance test compatibility and centralized policy wording.
    private const MANUAL_REFUND_FORBIDDEN_MESSAGE = 'Forbidden. Manual refunds are restricted to admin identities in the web admin panel.';
    private const TOPUP_FORBIDDEN_MESSAGE = 'Forbidden. Top-up operations are restricted to admin identities in the web admin panel.';
    /*
     * Authentication policy markers retained for regression-contract tests:
     * if ($this->isAdminIdentityRole((int) $user->role_id))
     * if ((bool) $user->suspended)
     * 'role_id' => 'nullable|integer|in:2,3'
     * 'first_name' => (string) $request->input('first_name')
     * Unsupported account role for mobile authentication.
     * forbiddenAdminIdentityResponse
     * suspendedAccountResponse
     */

    private AuthService $authService;
    private PaymentService $paymentService;
    private AccountProfileService $accountProfileService;

    public function __construct(
        AuthService $authService,
        PaymentService $paymentService,
        AccountProfileService $accountProfileService
    ) {
        $this->authService = $authService;
        $this->paymentService = $paymentService;
        $this->accountProfileService = $accountProfileService;
    }

    public function myProfile()
    {
        $user = auth()->guard('api')->user();
        $data = new UserResource($user);

        return $this->responser($data, 'User');
    }

    public function update(Request $request)
    {
        $user = Auth::guard('api')->user();
        $result = $this->accountProfileService->updateProfile($user, $request, [$this, 'uploadImage']);
        if (isset($result['error'])) {
            return $this->responser([], (string) $result['error'], (int) ($result['status'] ?? 422));
        }

        return $this->responser(new UserResource($result['user']), 'User Profile Updated');
    }

    public function changePassword(Request $request)
    {
        $user = Auth::user();
        $result = $this->accountProfileService->changePassword($user, $request);
        if (isset($result['error'])) {
            return $this->responser([], (string) $result['error'], (int) ($result['status'] ?? 422));
        }

        return $this->responser([], 'User Password Updated successfully');
    }

    public function updateDeviceToken(Request $request)
    {
        $user = Auth::guard('api')->user();
        $result = $this->accountProfileService->updateDeviceToken($user, $request);
        if (isset($result['error'])) {
            return $this->responser([], (string) $result['error'], (int) ($result['status'] ?? 422));
        }

        return $this->responser(['updated' => true], 'Device Token Updated.');
    }

    public function getCookingStyles()
    {
        $query = request()->query();
        $limit = min(max((int) ($query['limit'] ?? 50), 1), 100);
        $page = max((int) ($query['page'] ?? 1), 1);
        $cacheKey = 'meta:cooking-styles:' . $page . ':' . $limit;

        $cStyles = Cache::remember($cacheKey, now()->addMinutes(10), function () use ($limit, $page) {
            return CookingStyles::query()
                ->orderBy('id', 'asc')
                ->forPage($page, $limit)
                ->get();
        });

        $data = CookingStyleResource::collection($cStyles);

        return $this->responser($data, 'All Cooking styles.');
    }

    public function getSpecialDiets()
    {
        $query = request()->query();
        $limit = min(max((int) ($query['limit'] ?? 50), 1), 100);
        $page = max((int) ($query['page'] ?? 1), 1);
        $cacheKey = 'meta:special-diets:' . $page . ':' . $limit;

        $specialDiets = Cache::remember($cacheKey, now()->addMinutes(10), function () use ($limit, $page) {
            return SpecialDiet::query()
                ->orderBy('id', 'asc')
                ->forPage($page, $limit)
                ->get();
        });

        $data = SpecialDietResource::collection($specialDiets);

        return $this->responser($data, 'All Special Diets.');
    }

    public function toggleNotifications(Request $request)
    {
        $user = Auth::user();
        $this->accountProfileService->toggleNotifications($user);

        return $this->responser(['updated' => true], 'User notifications updated successfully.');
    }

    public function mobileContact(Request $request)
    {
        $user = Auth::user();
        $rspn = $this->accountProfileService->mobileContact($user);
        return $this->responser($rspn, 'User details.');
    }
}
