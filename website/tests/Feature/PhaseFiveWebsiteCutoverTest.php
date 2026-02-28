<?php

namespace Tests\Feature;

use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class PhaseFiveWebsiteCutoverTest extends TestCase
{
    public function test_website_intake_proxy_no_longer_references_salesforce(): void
    {
        $services = (string) file_get_contents(config_path('services.php'));
        $controller = (string) file_get_contents(app_path('Http/Controllers/Api/WebApiToCurlController.php'));
        $envExample = (string) file_get_contents(base_path('.env.example'));

        $this->assertStringContainsString("'backend_api' => [", $services);
        $this->assertStringNotContainsString("'salesforce' => [", $services);
        $this->assertStringContainsString('forwardToBackend', $controller);
        $this->assertStringNotContainsString('getAccToken', $controller);
        $this->assertStringNotContainsString('services.salesforce', $controller);
        $this->assertStringContainsString('BACKEND_API_BASE_URL', $envExample);
        $this->assertStringNotContainsString('SALESFORCE_', $envExample);
    }

    public function test_website_mobcontact_proxy_preserves_backend_deprecation_headers(): void
    {
        Http::fake([
            '*' => Http::response([
                'status' => 200,
                'isSuccess' => true,
                'message' => 'Contact Message Sent Successfully',
                'data' => ['accepted' => true],
            ], 200, [
                'Content-Type' => 'application/json',
                'Deprecation' => 'true',
                'Sunset' => 'Wed, 31 Dec 2026 00:00:00 GMT',
                'Link' => '</api/support/ticket>; rel="successor-version"',
            ]),
        ]);

        $response = $this->postJson('/api/mobcontact', [
            'SuppliedEmail' => 'proxy@example.com',
            'Subject' => 'Proxy compatibility',
            'Description' => 'Header passthrough should preserve deprecation metadata.',
        ]);

        $response->assertStatus(200)
            ->assertHeader('Deprecation', 'true')
            ->assertHeader('Sunset', 'Wed, 31 Dec 2026 00:00:00 GMT')
            ->assertHeader('Link', '</api/support/ticket>; rel="successor-version"');
    }

    public function test_website_has_health_probe_endpoint(): void
    {
        $response = $this->get('/health');

        $response->assertStatus(200);
        $this->assertSame('ok', trim($response->getContent()));
    }
}
