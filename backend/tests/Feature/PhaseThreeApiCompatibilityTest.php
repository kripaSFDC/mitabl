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

    public function test_preregister_accepts_legacy_salesforce_style_payload(): void
    {
        $response = $this->postJson('/api/preregister', [
            'FirstName' => 'Legacy',
            'LastName' => 'Lead',
            'Email' => 'legacy-lead@example.com',
            'MobilePhone' => '0400999888',
            'City' => 'Perth',
            'mitabl_Interested_In__c' => 'cook',
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('isSuccess', true)
            ->assertJsonPath('message', 'Your Registration Created Successfully');

        $this->assertDatabaseHas('pre_registrations', [
            'first_name' => 'Legacy',
            'last_name' => 'Lead',
            'email' => 'legacy-lead@example.com',
            'phone' => '0400999888',
            'interested_as' => 'cook',
            'source' => 'preregister_api',
        ]);
    }

    public function test_preregister_persists_phone_when_client_uses_phone_key_alias(): void
    {
        $response = $this->postJson('/api/preregister', [
            'first_name' => 'Alias',
            'last_name' => 'Phone',
            'email' => 'alias-phone@example.com',
            'phone' => '0400123456',
            'city' => 'Brisbane',
            'mitabl_Interested_In__c' => 'foodie',
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

    public function test_mobcontact_accepts_legacy_salesforce_case_payload(): void
    {
        $response = $this->postJson('/api/mobcontact', [
            'Type' => 'order',
            'SuppliedEmail' => 'legacy-ticket@example.com',
            'SuppliedPhone' => '0400111333',
            'Subject' => 'Legacy contact subject',
            'Description' => 'Legacy contact body should create ticket.',
            'mitabl_Case_For__c' => 'foodie',
            'mitabl_micook_Id__c' => 123,
            'mitabl_Mifoodi_Id__c' => null,
            'mitabl_Order_Id__c' => null,
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('isSuccess', true)
            ->assertJsonPath('message', 'Contact Message Sent Successfully');

        $this->assertDatabaseHas('support_tickets', [
            'requester_email' => 'legacy-ticket@example.com',
            'subject' => 'Legacy contact subject',
            'category' => 'order',
            'source' => 'mobcontact_api',
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
            'FirstName' => 'Bot',
            'LastName' => 'Lead',
            'Email' => 'bot-preregister@example.com',
            'website' => 'https://very-long-bot-url.example.com/this/should/not/error/on/max-length',
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('isSuccess', true)
            ->assertJsonPath('message', 'Your Registration Created Successfully');

        $this->assertDatabaseMissing('pre_registrations', [
            'email' => 'bot-preregister@example.com',
        ]);
    }

    public function test_honeypot_accepts_long_payload_for_mobcontact_without_persisting_records(): void
    {
        $response = $this->postJson('/api/mobcontact', [
            'Type' => 'order',
            'SuppliedEmail' => 'bot-mobcontact@example.com',
            'Subject' => 'Bot contact',
            'Description' => 'This would otherwise create a ticket.',
            'website' => 'https://very-long-bot-url.example.com/this/should/not/error/on/max-length',
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('isSuccess', true)
            ->assertJsonPath('message', 'Contact Message Sent Successfully');

        $this->assertDatabaseMissing('support_tickets', [
            'requester_email' => 'bot-mobcontact@example.com',
            'subject' => 'Bot contact',
        ]);
    }
}
