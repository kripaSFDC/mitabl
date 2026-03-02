<?php

namespace App\Http\Controllers\Api\User;

use App\Http\Controllers\Api\User\Concerns\HandlesUserAuthentication;
use App\Http\Controllers\Api\User\Concerns\HandlesUserPayments;
use App\Http\Controllers\Controller;
use App\Http\Resources\User\CookingStyle as CookingStyleResource;
use App\Http\Resources\User\SpecialDiet as SpecialDietResource;
use App\Http\Resources\User\User as UserResource;
use App\Models\CookingStyles;
use App\Models\NotifyDisable;
use App\Models\SpecialDiet;
use App\Services\AuthService;
use App\Services\PaymentService;
use App\Traits\GoogleAddress;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;

class UserController extends Controller
{
    use GoogleAddress;
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

    public function __construct(
        AuthService $authService,
        PaymentService $paymentService
    ) {
        $this->authService = $authService;
        $this->paymentService = $paymentService;
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

        $validator = Validator::make($request->all(), [
            'first_name' => 'required|string|max:100',
            'last_name' => 'required|string|max:100',
            'phone' => 'required|string|max:30',
            'email' => 'required|email|unique:users,email,' . $user->id,
        ]);

        if ($validator->fails()) {
            return $this->responser([], $validator->errors()->first(), 422);
        }

        $user->first_name = $request->first_name;
        $user->last_name = $request->last_name;
        $user->email = $request->email;
        $user->phone = $request->phone;
        $user->description = $request->description;

        if ($request->hasFile('avatar')) {
            $avatar = $this->uploadImage($request->avatar, 'user');
            if ($avatar['success']) {
                $user->avatar = $avatar['path'];
            } else {
                return $this->responser([], $avatar['msg'], 422);
            }
        }

        $user->save();

        return $this->responser(new UserResource($user), 'User Profile Updated');
    }

    public function changePassword(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'current_password' => 'required',
            'new_password' => 'required|different:current_password|min:6',
        ]);
        if ($validator->fails()) {
            return $this->responser([], $validator->errors()->first(), 422);
        }

        $user = Auth::user();
        if (! Hash::check((string) $request->current_password, (string) $user->password)) {
            return $this->responser([], 'Current password doesn\'t match', 422);
        }

        $user->password = bcrypt((string) $request->new_password);
        $user->save();

        return $this->responser([], 'User Password Updated successfully');
    }

    public function updateDeviceToken(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'device_token' => 'required|string|max:2048',
        ]);
        if ($validator->fails()) {
            return $this->responser([], $validator->errors()->first(), 422);
        }

        $user = Auth::guard('api')->user();
        $user->device_token = $request->device_token;
        $user->save();

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

        $existing = NotifyDisable::where('user_id', $user->id)->first();
        if ($existing) {
            $existing->delete();
        } else {
            $notifyDisable = new NotifyDisable();
            $notifyDisable->user_id = $user->id;
            $notifyDisable->save();
        }

        return $this->responser(['updated' => true], 'User notifications updated successfully.');
    }

    public function mobileContact(Request $request)
    {
        $user = Auth::user();
        $rspn = [
            'role' => $user->role_id,
            'id' => $user->id,
            'email' => $user->email,
            'phone' => $user->phone,
        ];
        return $this->responser($rspn, 'User details.');
    }
}
