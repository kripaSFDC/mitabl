<?php

namespace App\Services;

use App\Models\AdminActionLog;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

class AdminAuditLogService
{
    public function log(
        string $action,
        ?Request $request = null,
        ?array $metadata = null,
        ?array $requestPayload = null,
        ?int $statusCode = null
    ): void {
        $request = $request ?: request();

        try {
            AdminActionLog::create([
                'admin_user_id' => Auth::guard('admin')->id(),
                'action' => $action,
                'method' => strtoupper((string) $request->method()),
                'path' => (string) $request->path(),
                'route_name' => optional($request->route())->getName(),
                'status_code' => $statusCode,
                'ip_address' => $request->ip(),
                'user_agent' => (string) $request->userAgent(),
                'correlation_id' => $this->normalizeCorrelationId($request->headers->get('X-Request-Id')),
                'metadata' => $metadata,
                'request_payload' => $this->sanitizePayload($requestPayload),
                'created_at' => now(),
            ]);
        } catch (\Throwable $throwable) {
            Log::warning('admin.audit.log_failed', [
                'action' => $action,
                'error' => $throwable->getMessage(),
            ]);
        }
    }

    private function sanitizePayload(?array $payload): ?array
    {
        if ($payload === null) {
            return null;
        }

        $hiddenKeys = [
            'password',
            'password_confirmation',
            'token',
            '_token',
            'secret',
            'authorization',
            'cookie',
            'current_password',
        ];

        $sanitize = function ($value, $key = null) use (&$sanitize, $hiddenKeys) {
            if ($key !== null && in_array(strtolower((string) $key), $hiddenKeys, true)) {
                return '[redacted]';
            }

            if (is_array($value)) {
                $sanitized = [];
                foreach ($value as $innerKey => $innerValue) {
                    $sanitized[$innerKey] = $sanitize($innerValue, $innerKey);
                }

                return $sanitized;
            }

            if (is_string($value) && strlen($value) > 500) {
                return substr($value, 0, 500) . '...[truncated]';
            }

            if (is_object($value)) {
                return '[object:' . get_class($value) . ']';
            }

            if (is_resource($value)) {
                return '[resource]';
            }

            return $value;
        };

        return $sanitize($payload);
    }

    private function normalizeCorrelationId(?string $correlationId): ?string
    {
        $correlationId = trim((string) $correlationId);

        if ($correlationId === '' || ! Str::isUuid($correlationId)) {
            return null;
        }

        return $correlationId;
    }
}
