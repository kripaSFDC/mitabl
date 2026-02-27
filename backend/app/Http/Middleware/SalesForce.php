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
        $sales_auth = env('SALES_AUTH');
        // echo $request->header('Authorization'); 
        // die();

        if ($sales_auth == $request->header('Sales-Auth')) {
            return $next($request);
            
        } 

        return response()->json('Unauthorized', 401);
        
    }
}
