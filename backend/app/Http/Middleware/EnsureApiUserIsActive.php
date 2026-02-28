<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class EnsureApiUserIsActive
{
    public function handle(Request $request, Closure $next): mixed
    {
        $user = Auth::guard('api')->user();

        if (! $user) {
            return $next($request);
        }

        if ((int) $user->role_id === 1) {
            Auth::guard('api')->logout();

            return $this->forbiddenResponse(
                'Forbidden. Admin identities must authenticate via the web admin panel.'
            );
        }

        if ((bool) $user->suspended) {
            Auth::guard('api')->logout();

            return $this->forbiddenResponse(
                'Your account is suspended. Please contact support.'
            );
        }

        return $next($request);
    }

    private function forbiddenResponse(string $message): JsonResponse
    {
        return response()->json([
            'status' => 403,
            'isSuccess' => false,
            'isError' => $message,
            'data' => [],
        ], 403);
    }
}
