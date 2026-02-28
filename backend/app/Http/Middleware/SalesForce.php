<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class SalesForce
{
    /**
     * Handle an incoming request.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \Closure(\Illuminate\Http\Request): (\Illuminate\Http\Response|\Illuminate\Http\RedirectResponse)  $next
     * @return \Illuminate\Http\Response|\Illuminate\Http\RedirectResponse
     */
    public function handle(Request $request, Closure $next)
    {
        $salesAuth = (string) config('services.salesforce.auth_header', '');
        $incoming = (string) $request->header('Sales-Auth', '');

        if ($salesAuth !== '' && hash_equals($salesAuth, $incoming)) {
            return $next($request);
        }

        return response()->json('Unauthorized', 401);
        
    }
}
