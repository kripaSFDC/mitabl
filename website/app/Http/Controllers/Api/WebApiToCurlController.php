<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Support\Facades\Http;
use Illuminate\Http\Client\Response as HttpClientResponse;
use Symfony\Component\HttpFoundation\Response as HttpFoundationResponse;
use Illuminate\Http\Request;

class WebApiToCurlController extends Controller
{
    public function preRegister(Request $request)
    {
        return $this->forwardToBackend('/api/preregister', $request->all());
    }

    public function mobContact(Request $request)
    {
        return $this->forwardToBackend('/api/mobcontact', $request->all());
    }

    private function forwardToBackend(string $path, array $payload)
    {
        $baseUrl = rtrim((string) config('services.backend_api.base_url'), '/');
        $url = $baseUrl . $path;

        try {
            $response = Http::acceptJson()
                ->connectTimeout(10)
                ->timeout(20)
                ->post($url, $payload);
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
