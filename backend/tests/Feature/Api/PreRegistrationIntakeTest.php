<?php

namespace Tests\Feature\Api;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class PreRegistrationIntakeTest extends TestCase
{
    use RefreshDatabase;

    public function test_preregister_endpoint_persists_local_lead(): void
    {
        $response = $this->postJson('/api/preregister', [
            'first_name' => 'Ada',
            'last_name' => 'Lovelace',
            'email' => 'Ada@Example.com',
            'phone' => '+61 400 222 333',
            'city' => 'Sydney',
            'interested_as' => 'cook',
            'source' => 'website',
            'consent_to_contact' => true,
            'communication_preference' => 'email',
        ]);

        $response->assertOk()
            ->assertJsonPath('status', 200)
            ->assertJsonPath('data.duplicate', false)
            ->assertJsonPath('data.status', 'new');

        $this->assertDatabaseHas('pre_registrations', [
            'first_name' => 'Ada',
            'last_name' => 'Lovelace',
            'email' => 'ada@example.com',
            'phone' => '61400222333',
            'interested_as' => 'cook',
            'status' => 'new',
        ]);
    }

    public function test_preregister_endpoint_deduplicates_recent_new_or_contacted_leads(): void
    {
        $payload = [
            'first_name' => 'Sam',
            'last_name' => 'Lead',
            'email' => 'sam@example.com',
            'phone' => '+61 444 111 333',
            'interested_as' => 'both',
            'source' => 'campaign',
        ];

        $first = $this->postJson('/api/preregister', $payload);
        $first->assertOk()->assertJsonPath('data.duplicate', false);

        $second = $this->postJson('/api/preregister', $payload);
        $second->assertOk()->assertJsonPath('data.duplicate', true);

        $this->assertDatabaseCount('pre_registrations', 1);
    }

    public function test_preregister_endpoint_forces_source_to_website_and_blocks_email_duplicates(): void
    {
        $this->postJson('/api/preregister', [
            'first_name' => 'Taylor',
            'last_name' => 'Original',
            'email' => 'dupe@example.com',
            'phone' => '+61 401 000 001',
            'city' => 'Melbourne',
            'interested_as' => 'foodie',
            'source' => 'campaign',
        ])->assertOk()->assertJsonPath('data.duplicate', false);

        $second = $this->postJson('/api/preregister', [
            'first_name' => 'Taylor',
            'last_name' => 'Changed',
            'email' => 'dupe@example.com',
            'phone' => '+61 401 999 999',
            'city' => 'Brisbane',
            'interested_as' => 'cook',
            'source' => 'referral',
        ]);

        $second->assertOk()->assertJsonPath('data.duplicate', true);

        $this->assertDatabaseCount('pre_registrations', 1);
        $this->assertDatabaseHas('pre_registrations', [
            'email' => 'dupe@example.com',
            'source' => 'website',
        ]);
    }

}
