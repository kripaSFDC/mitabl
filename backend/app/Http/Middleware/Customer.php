<?php

namespace App\Http\Middleware;

use App\Http\Controllers\Controller;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class Customer
{
    public function handle(Request $request, Closure $next)
    {
        $user = Auth::guard('api')->user();

        if ($user && (int) $user->active_role_id === 3 && $user->hasRoleMembership(3, false)) {
            return $next($request);
        }

        return Controller::responser([], 'Your account is Unauthorize for this request. Login with Foodie account.', 403);
    }
}
