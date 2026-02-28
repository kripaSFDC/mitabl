<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Mail;
use Tests\TestCase;

class PhaseThreeApiCompatibilityTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Mail::fake();
    }

    public function test_preregister_persists_phone_when_client_uses_phone_key_alias(): void
    {
        $response = $this->postJson('/api/preregister', [
            'first_name' => 'Alias',
            'last_name' => 'Phone',
            'email' => 'alias-phone@example.com',
            'phone' => '0400123456',
            'city' => 'Brisbane',
            'interested_as' => 'foodie',
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('isSuccess', true)
            ->assertJsonPath('message', 'Your Registration Created Successfully');

        $this->assertDatabaseHas('pre_registrations', [
            'email' => 'alias-phone@example.com',
            'phone' => '0400123456',
            'source' => 'preregister_api',
        ]);
    }

    

    public function test_honeypot_blocks_bot_submission_without_persisting_records(): void
    {
        $response = $this->postJson('/api/support/ticket', [
            'requester_email' => 'bot@example.com',
            'subject' => 'Bot submission',
            'description' => 'Bot payload',
            'website' => 'https://spam.example.com',
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('isSuccess', true);

        $this->assertDatabaseMissing('support_tickets', [
            'requester_email' => 'bot@example.com',
            'subject' => 'Bot submission',
        ]);
    }

    public function test_honeypot_accepts_long_payload_for_preregister_without_persisting_records(): void
    {
        $response = $this->postJson('/api/preregister', [
            'first_name' => 'Bot',
            'last_name' => 'Lead',
            'email' => 'bot-preregister@example.com',
            'website' => 'https://very-long-bot-url.example.com/this/should/not/error/on/max-length',
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('isSuccess', true)
            ->assertJsonPath('message', 'Your Registration Created Successfully');

        $this->assertDatabaseMissing('pre_registrations', [
            'email' => 'bot-preregister@example.com',
        ]);
    }
}
