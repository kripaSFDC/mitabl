<?php

namespace App\Http\Middleware;

use App\Http\Controllers\Controller;
use App\Models\UserRole;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class Restaurant
{
    private const UNAUTHORIZED_MESSAGE = 'Your account is unauthorized for this request. Login with Restaurant account.';
    private const ONBOARDING_REQUIRED_MESSAGE = 'Complete your kitchen profile first. Create your kitchen before managing restaurant operations.';

    public function handle(Request $request, Closure $next)
    {
        $user = Auth::guard('api')->user();

        if ($user && (int) $user->active_role_id !== 2) {
            $cookMembership = $user->roleMembershipFor(2);

            if ($cookMembership && $cookMembership->status !== UserRole::STATUS_DISABLED) {
                $user->role_id = 2;
                $user->save();
                $user->refresh();
            }
        }

        if ($user && (int) $user->active_role_id === 2) {
            $membership = $user->roleMembershipFor(2);

            if ($membership && $membership->status === UserRole::STATUS_DISABLED) {
                return Controller::responser([], self::UNAUTHORIZED_MESSAGE, 403);
            }

            if (! $membership) {
                DB::table('user_roles')->insertOrIgnore([
                    'user_id' => $user->id,
                    'role_id' => 2,
                    'status' => UserRole::STATUS_ACTIVE,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);

                $membership = $user->roleMemberships()
                    ->where('role_id', 2)
                    ->first();
            }

            if (! $membership) {
                return Controller::responser([], self::UNAUTHORIZED_MESSAGE, 403);
            }

            if ($membership->status === UserRole::STATUS_ONBOARDING) {
                if ($this->isKitchenOnboardingRoute($request)) {
                    return $next($request);
                }

                return Controller::responser([], self::ONBOARDING_REQUIRED_MESSAGE, 403);
            }

            if ($membership->status !== UserRole::STATUS_ACTIVE) {
                return Controller::responser([], self::UNAUTHORIZED_MESSAGE, 403);
            }

            return $next($request);
        }

        return Controller::responser([], self::UNAUTHORIZED_MESSAGE, 403);
    }

    private function isKitchenOnboardingRoute(Request $request): bool
    {
        return $request->is('api/v1/mikitchn/store')
            || $request->is('api/v1/mikitchn/editkitchen')
            || $request->is('api/v1/food/add')
            || $request->is('api/v1/food/editfood')
            || $request->is('api/v2/mikitchn/store')
            || $request->is('api/v2/mikitchn/editkitchen')
            || $request->is('api/v2/food/add')
            || $request->is('api/v2/food/editfood');
    }
}
