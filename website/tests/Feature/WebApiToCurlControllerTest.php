<?php

namespace Tests\Feature;

use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class WebApiToCurlControllerTest extends TestCase
{
    public function test_mobile_contact_proxy_forwards_authorization_header_and_query_params(): void
    {
        config(['services.backend_api.base_url' => 'https://backend.example']);

        Http::fake([
            'https://backend.example/api/v1/mob-contact*' => Http::response([
                'isSuccess' => true,
                'data' => [
                    'email' => 'user@example.com',
                    'phone' => '61411111111',
                ],
            ], 200),
        ]);

        $response = $this->withHeaders([
            'Authorization' => 'Bearer secure-token',
        ])->getJson('/api/v1/mob-contact?locale=en-AU');

        $response->assertOk()->assertJsonPath('isSuccess', true);

        Http::assertSent(function ($request) {
            return $request->url() === 'https://backend.example/api/v1/mob-contact?locale=en-AU'
                && $request->method() === 'GET'
                && $request->hasHeader('Authorization', 'Bearer secure-token');
        });
    }
}
