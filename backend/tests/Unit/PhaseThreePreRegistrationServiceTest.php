<?php

namespace Tests\Unit;

use App\Services\PreRegistrationService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Mail;
use Tests\TestCase;

class PhaseThreePreRegistrationServiceTest extends TestCase
{
    use RefreshDatabase;

    private PreRegistrationService $service;

    protected function setUp(): void
    {
        parent::setUp();
        Mail::fake();
        $this->service = app(PreRegistrationService::class);
    }

    public function test_pre_registration_create_and_duplicate_detection(): void
    {
        $payload = [
            'first_name' => 'Taylor',
            'last_name' => 'Lead',
            'email' => 'lead@example.com',
            'phone' => '0400333444',
            'city' => 'Sydney',
            'interested_as' => 'cook',
            'consent_to_contact' => true,
        ];

        $first = $this->service->create($payload, 'preregister_api');
        $second = $this->service->create($payload, 'preregister_api');

        $this->assertFalse($first['duplicate']);
        $this->assertTrue($second['duplicate']);
        $this->assertSame($first['registration']->id, $second['registration']->id);
        $this->assertDatabaseHas('crm_communication_logs', [
            'pre_registration_id' => $first['registration']->id,
            'template' => 'pre_registration_acknowledged',
            'status' => 'queued',
        ]);
    }

    public function test_no_contact_payloads_do_not_over_collapse_after_fingerprint_hardening(): void
    {
        $first = $this->service->create([
            'first_name' => 'Alex',
            'last_name' => 'One',
            'interested_as' => 'foodie',
            'city' => 'Melbourne',
        ], 'preregister_api');

        $second = $this->service->create([
            'first_name' => 'Alex',
            'last_name' => 'Two',
            'interested_as' => 'foodie',
            'city' => 'Melbourne',
        ], 'preregister_api');

        $this->assertFalse($first['duplicate']);
        $this->assertFalse($second['duplicate']);
        $this->assertNotSame($first['registration']->id, $second['registration']->id);
    }

    public function test_spam_like_pre_registration_is_marked_spam_and_ack_is_not_sent(): void
    {
        $result = $this->service->create([
            'first_name' => 'Loan',
            'last_name' => 'Casino',
            'email' => 'spammy@example.com',
            'interested_as' => 'cook',
            'notes' => 'Best forex casino crypto loan offers',
        ], 'preregister_api');

        $registration = $result['registration'];

        $this->assertSame('spam', $registration->status);
        $this->assertNotNull($registration->spam_detected_at);
        $this->assertDatabaseMissing('crm_communication_logs', [
            'pre_registration_id' => $registration->id,
            'template' => 'pre_registration_acknowledged',
        ]);
    }
}
