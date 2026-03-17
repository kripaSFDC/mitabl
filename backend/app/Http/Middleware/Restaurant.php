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
                return Controller::responser([], 'Your account is Unauthorize for this request. Login with Restaurant account.', 403);
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
                return Controller::responser([], 'Your account is Unauthorize for this request. Login with Restaurant account.', 403);
            }

            if ($membership->status === UserRole::STATUS_ONBOARDING && $this->isKitchenOnboardingRoute($request)) {
                return $next($request);
            }

            if ($membership->status !== UserRole::STATUS_ACTIVE) {
                return Controller::responser([], 'Your account is Unauthorize for this request. Login with Restaurant account.', 403);
            }

            return $next($request);
        }

        return Controller::responser([], 'Your account is Unauthorize for this request. Login with Restaurant account.', 403);
    }

    private function isKitchenOnboardingRoute(Request $request): bool
    {
        return $request->is('api/v1/mikitchn/store')
            || $request->is('api/v1/mikitchn/editkitchen')
            || $request->is('api/v2/mikitchn/store')
            || $request->is('api/v2/mikitchn/editkitchen');
    }
}
