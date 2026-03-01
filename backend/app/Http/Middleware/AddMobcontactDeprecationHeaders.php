<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Contracts\Debug\ExceptionHandler;
use Symfony\Component\HttpFoundation\Response;
use Throwable;

class AddMobcontactDeprecationHeaders
{
    public function handle(Request $request, Closure $next): Response
    {
        try {
            $response = $next($request);
        } catch (Throwable $throwable) {
            $response = app(ExceptionHandler::class)->render($request, $throwable);
        }

        $replacementPath = (string) config('support.mobcontact_alias_replacement_path', '/api/support/ticket');
        $sunset = (string) config('support.mobcontact_alias_sunset', '2026-12-31');

        $response->headers->set('Deprecation', 'true');
        $response->headers->set('Sunset', $sunset . 'T23:59:59Z');
        $response->headers->set('Link', sprintf('<%s>; rel="successor-version"', $replacementPath));
        $response->headers->set('X-Deprecated-Endpoint', '/api/mobcontact');
        $response->headers->set('X-Replacement-Endpoint', $replacementPath);

        Log::warning('api.mobcontact.alias_used', [
            'path' => $request->path(),
            'replacement_path' => $replacementPath,
            'sunset' => $sunset,
            'ip' => $request->ip(),
            'user_id' => null,
            'request_id' => $request->header('X-Request-Id'),
            'user_agent' => (string) $request->userAgent(),
        ]);

        return $response;
    }
}
