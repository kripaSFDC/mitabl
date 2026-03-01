<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Client\Response as HttpClientResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Symfony\Component\HttpFoundation\Response as HttpFoundationResponse;

class WebApiToCurlController extends Controller
{
    public function preRegister(Request $request)
    {
        return $this->forwardToBackend('POST', '/api/preregister', $request->all());
    }

    public function supportTicket(Request $request)
    {
        return $this->forwardToBackend('POST', '/api/support/ticket', $request->all());
    }

    public function mobileContact(Request $request)
    {
        return $this->forwardToBackend(
            'GET',
            '/api/v1/mob-contact',
            $request->query(),
            [
                'Authorization' => (string) $request->header('Authorization', ''),
            ]
        );
    }

    private function forwardToBackend(string $method, string $path, array $payload = [], array $headers = [])
    {
        $baseUrl = rtrim((string) config('services.backend_api.base_url'), '/');
        $url = $baseUrl . $path;

        try {
            $http = Http::acceptJson()
                ->connectTimeout(10)
                ->timeout(20)
                ->withHeaders(array_filter($headers));

            $response = match (strtoupper($method)) {
                'GET' => $http->get($url, $payload),
                default => $http->post($url, $payload),
            };
        } catch (\Throwable $e) {
            return response()->json([
                'status' => 503,
                'isSuccess' => false,
                'message' => 'Backend intake service is unavailable.',
                'data' => [],
            ], 503);
        }

        if ($response->header('Content-Type') && str_contains($response->header('Content-Type'), 'application/json')) {
            return $this->withForwardedHeaders(
                response()->json($response->json(), $response->status()),
                $response
            );
        }

        return $this->withForwardedHeaders(
            response($response->body(), $response->status()),
            $response
        );
    }

    private function withForwardedHeaders(HttpFoundationResponse $downstream, HttpClientResponse $upstream): HttpFoundationResponse
    {
        foreach (['Deprecation', 'Sunset', 'Link'] as $header) {
            $value = $upstream->header($header);
            if ($value !== null && $value !== '') {
                $downstream->headers->set($header, $value);
            }
        }

        return $downstream;
    }
}
