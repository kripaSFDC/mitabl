<?php

namespace App\Http\Middleware;

use App\Http\Controllers\Controller;
use App\Models\UserRole;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class Customer
{
    public function handle(Request $request, Closure $next)
    {
        $user = Auth::guard('api')->user();

        if ($user && (int) $user->active_role_id === 3) {
            $membership = $user->roleMembershipFor(3);

            if ($membership && $membership->status === UserRole::STATUS_DISABLED) {
                return Controller::responser([], 'Your account is Unauthorize for this request. Login with Foodie account.', 403);
            }

            if (! $membership) {
                DB::table('user_roles')->insertOrIgnore([
                    'user_id' => $user->id,
                    'role_id' => 3,
                    'status' => UserRole::STATUS_ACTIVE,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);

                $membership = $user->roleMemberships()
                    ->where('role_id', 3)
                    ->first();
            }

            if (! $membership || $membership->status !== UserRole::STATUS_ACTIVE) {
                return Controller::responser([], 'Your account is Unauthorize for this request. Login with Foodie account.', 403);
            }

            return $next($request);
        }

        return Controller::responser([], 'Your account is Unauthorize for this request. Login with Foodie account.', 403);
    }
}
