<?php

namespace App\Services;

class AdminRedirectUrlResolver
{
    public function resolveAfterLogin(): string
    {
        session()->forget('url.intended');

        return $this->fallbackUrl();
    }

    public function resolveForAuthenticatedVisit(): string
    {
        $intendedUrl = session()->pull('url.intended');

        return $this->sanitize($intendedUrl) ?? $this->fallbackUrl();
    }

    public function fallbackUrl(): string
    {
        return $this->canonicalBaseUrl() . '/admin';
    }

    public function sanitize(?string $url): ?string
    {
        if (! is_string($url) || trim($url) === '') {
            return null;
        }

        $url = trim($url);

        if (str_starts_with($url, '/')) {
            return $this->canonicalizeAdminPath($url);
        }

        $target = parse_url($url);
        $canonical = parse_url($this->canonicalBaseUrl());

        if (($target === false) || ($canonical === false)) {
            return null;
        }

        $targetScheme = strtolower((string) ($target['scheme'] ?? ''));
        $targetHost = strtolower((string) ($target['host'] ?? ''));
        $targetPort = $target['port'] ?? $this->defaultPort($targetScheme);

        $canonicalScheme = strtolower((string) ($canonical['scheme'] ?? ''));
        $canonicalHost = strtolower((string) ($canonical['host'] ?? ''));
        $canonicalPort = $canonical['port'] ?? $this->defaultPort($canonicalScheme);

        if (
            ($targetScheme !== $canonicalScheme) ||
            ($targetHost !== $canonicalHost) ||
            ($targetPort !== $canonicalPort)
        ) {
            return null;
        }

        $path = (string) ($target['path'] ?? '/');
        $query = isset($target['query']) ? '?' . $target['query'] : '';
        $fragment = isset($target['fragment']) ? '#' . $target['fragment'] : '';

        return $this->canonicalizeAdminPath($path . $query . $fragment);
    }

    private function canonicalizeAdminPath(string $pathWithSuffix): ?string
    {
        $path = preg_replace('/[?#].*$/', '', $pathWithSuffix) ?: '';

        if (($path !== '/admin') && ! str_starts_with($path, '/admin/')) {
            return null;
        }

        return $this->canonicalBaseUrl() . $pathWithSuffix;
    }

    private function canonicalBaseUrl(): string
    {
        return rtrim((string) config('app.url', ''), '/');
    }

    private function defaultPort(string $scheme): ?int
    {
        return match ($scheme) {
            'http' => 80,
            'https' => 443,
            default => null,
        };
    }
}
