<?php

namespace App\Http\Middleware;

use App\Services\AdminAuditLogService;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Symfony\Component\HttpKernel\Exception\HttpExceptionInterface;

class RecordAdminAction
{
    public function __construct(private readonly AdminAuditLogService $auditLogService)
    {
    }

    public function handle(Request $request, Closure $next)
    {
        $response = null;
        $caught = null;

        try {
            $response = $next($request);
        } catch (\Throwable $throwable) {
            $caught = $throwable;
        }

        if (! Auth::guard('admin')->check()) {
            if ($caught) {
                throw $caught;
            }

            return $response;
        }

        if (! in_array(strtoupper($request->method()), ['POST', 'PUT', 'PATCH', 'DELETE'], true)) {
            if ($caught) {
                throw $caught;
            }

            return $response;
        }

        $action = $this->resolveActionName($request);
        $payload = $this->extractActionPayload($request);
        $statusCode = $caught
            ? ($caught instanceof HttpExceptionInterface ? $caught->getStatusCode() : 500)
            : (method_exists($response, 'getStatusCode') ? $response->getStatusCode() : null);

        $this->auditLogService->log(
            $action,
            $request,
            [
                'response_status' => $statusCode,
                'error' => $caught?->getMessage(),
            ],
            $payload,
            $statusCode
        );

        if ($caught) {
            throw $caught;
        }

        return $response;
    }

    private function resolveActionName(Request $request): string
    {
        $routeName = optional($request->route())->getName();
        if (is_string($routeName) && $routeName !== '') {
            return $routeName;
        }

        if ($request->is('*livewire/update')) {
            $method = data_get($request->input('components'), '0.calls.0.method');
            if (is_string($method) && $method !== '') {
                return 'admin.livewire.' . $method;
            }
        }

        return 'admin.' . str_replace('/', '.', trim((string) $request->path(), '/'));
    }

    private function extractActionPayload(Request $request): array
    {
        if ($request->is('*livewire/update')) {
            return [
                'components' => collect((array) $request->input('components'))
                    ->map(function (array $component): array {
                        return [
                            'calls' => $component['calls'] ?? [],
                            'updates' => $component['updates'] ?? [],
                        ];
                    })
                    ->toArray(),
            ];
        }

        return $request->except(['_token']);
    }
}
