<?php

namespace Tests\Feature\Api;

use Tests\TestCase;

class MobileContactV1SunsetTest extends TestCase
{
    public function test_v1_mob_contact_returns_http_410_with_deprecation_headers(): void
    {
        $response = $this->getJson('/api/v1/mob-contact');

        $response
            ->assertStatus(410)
            ->assertHeader('Deprecation', 'true')
            ->assertHeader('Sunset', 'Wed, 01 Jul 2026 00:00:00 GMT')
            ->assertHeader('Link', '</api/v2/mob-contact>; rel="successor-version"')
            ->assertJsonPath('migration_guide', '/docs/MOBILE_APP.md#contact-endpoint-migration');
    }
}
