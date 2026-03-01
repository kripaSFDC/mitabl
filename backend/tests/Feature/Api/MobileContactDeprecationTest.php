<?php

namespace Tests\Feature\Api;

use Tests\TestCase;

class MobileContactDeprecationTest extends TestCase
{
    public function test_unversioned_mobcontact_returns_http_410_with_deprecation_headers(): void
    {
        $response = $this->getJson('/api/mobcontact');

        $response
            ->assertStatus(410)
            ->assertHeader('Deprecation', 'true')
            ->assertHeader('Sunset', 'Wed, 01 Jul 2026 00:00:00 GMT');
    }
}
