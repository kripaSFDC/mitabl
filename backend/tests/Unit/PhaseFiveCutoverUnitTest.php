<?php

namespace Tests\Unit;

use App\Http\Controllers\Api\WebApiToCurlController;
use App\Models\PreRegistration;
use App\Services\PreRegistrationService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Request;
use Mockery;
use Tests\TestCase;

class PhaseFiveCutoverUnitTest extends TestCase
{
    use RefreshDatabase;

    protected function tearDown(): void
    {
        Mockery::close();
        parent::tearDown();
    }

    public function test_preregister_compatibility_payload_maps_to_local_service_contract(): void
    {
        $preRegistrationService = Mockery::mock(PreRegistrationService::class);

        $registration = new PreRegistration();
        $registration->id = 42;
        $registration->status = 'new';

        $preRegistrationService
            ->shouldReceive('create')
            ->once()
            ->withArgs(function (array $payload, string $source): bool {
                return $source === 'preregister_api'
                    && $payload['first_name'] === 'Legacy'
                    && $payload['last_name'] === 'Lead'
                    && $payload['email'] === 'legacy@example.com'
                    && $payload['phone'] === null
                    && $payload['city'] === 'Sydney'
                    && $payload['interested_as'] === 'cook'
                    && $payload['consent_to_contact'] === false;
            })
            ->andReturn([
                'registration' => $registration,
                'duplicate' => false,
            ]);

        $controller = new WebApiToCurlController($preRegistrationService);

        $request = Request::create('/api/preregister', 'POST', [
            'first_name' => 'Legacy',
            'last_name' => 'Lead',
            'email' => 'legacy@example.com',
            'phone' => '0400111222',
            'city' => 'Sydney',
            'interested_as' => 'cook',
        ]);

        $response = $controller->preRegister($request);
        $payload = $response->getData(true);

        $this->assertSame(200, $response->getStatusCode());
        $this->assertTrue($payload['isSuccess']);
        $this->assertSame(42, $payload['data']['id']);
        $this->assertSame('new', $payload['data']['status']);
        $this->assertFalse($payload['data']['duplicate']);
    }


    public function test_preregister_honeypot_accepts_without_persisting(): void
    {
        config([
            'support.honeypot_field' => 'website',
        ]);

        $preRegistrationService = Mockery::mock(PreRegistrationService::class);
        $preRegistrationService->shouldNotReceive('create');

        $controller = new WebApiToCurlController($preRegistrationService);
        $request = Request::create('/api/preregister', 'POST', [
            'first_name' => 'Bot',
            'last_name' => 'Lead',
            'email' => 'bot@example.com',
            'website' => 'https://spam.example.com',
        ]);

        $response = $controller->preRegister($request);
        $payload = $response->getData(true);

        $this->assertSame(200, $response->getStatusCode());
        $this->assertTrue($payload['isSuccess']);
        $this->assertTrue($payload['data']['accepted']);
    }

}
