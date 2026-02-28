<?php

namespace Tests\Unit;

use App\Http\Controllers\Api\WebApiToCurlController;
use App\Models\PreRegistration;
use App\Models\SupportTicket;
use App\Services\PreRegistrationService;
use App\Services\SupportTicketService;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
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
        $supportTicketService = Mockery::mock(SupportTicketService::class);

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
                    && $payload['phone'] === '0400111222'
                    && $payload['city'] === 'Sydney'
                    && $payload['interested_as'] === 'cook'
                    && $payload['consent_to_contact'] === true;
            })
            ->andReturn([
                'registration' => $registration,
                'duplicate' => false,
            ]);

        $controller = new WebApiToCurlController($preRegistrationService, $supportTicketService);

        $request = Request::create('/api/preregister', 'POST', [
            'FirstName' => 'Legacy',
            'LastName' => 'Lead',
            'Email' => 'legacy@example.com',
            'phone' => '0400111222',
            'City' => 'Sydney',
            'mitabl_Interested_In__c' => 'cook',
        ]);

        $response = $controller->preRegister($request);
        $payload = $response->getData(true);

        $this->assertSame(200, $response->getStatusCode());
        $this->assertTrue($payload['isSuccess']);
        $this->assertSame(42, $payload['data']['id']);
        $this->assertSame('new', $payload['data']['status']);
        $this->assertFalse($payload['data']['duplicate']);
    }

    public function test_mobcontact_honeypot_returns_success_with_deprecation_headers_without_ticket_creation(): void
    {
        config([
            'support.honeypot_field' => 'website',
            'support.mobcontact_alias_sunset' => '2026-12-31',
            'support.mobcontact_alias_replacement_path' => '/api/support/ticket',
        ]);

        Log::spy();

        $preRegistrationService = Mockery::mock(PreRegistrationService::class);
        $supportTicketService = Mockery::mock(SupportTicketService::class);
        $supportTicketService->shouldNotReceive('createTicket');

        $controller = new WebApiToCurlController($preRegistrationService, $supportTicketService);
        $request = Request::create('/api/mobcontact', 'POST', [
            'SuppliedEmail' => 'Legacy-Ticket@Example.com',
            'Subject' => 'Legacy contact',
            'Description' => 'Bot-like request should be accepted silently.',
            'website' => 'https://bot.example.com',
        ]);

        $response = $controller->mobContact($request);
        $payload = $response->getData(true);

        $this->assertSame(200, $response->getStatusCode());
        $this->assertTrue($payload['isSuccess']);
        $this->assertSame('true', $response->headers->get('Deprecation'));
        $this->assertSame(Carbon::parse('2026-12-31')->toRfc7231String(), $response->headers->get('Sunset'));
        $this->assertStringContainsString('/api/support/ticket', (string) $response->headers->get('Link'));

        Log::shouldHaveReceived('info')
            ->withArgs(function (string $event, array $context): bool {
                return $event === 'support.mobcontact.alias_used'
                    && ($context['email_hash'] ?? null) === hash('sha256', 'legacy-ticket@example.com')
                    && ($context['honeypot_accepted'] ?? null) === true
                    && ! array_key_exists('email', $context)
                    && ! array_key_exists('SuppliedEmail', $context);
            })
            ->once();
    }

    public function test_mobcontact_compatibility_payload_maps_to_local_ticket_contract(): void
    {
        config([
            'support.honeypot_field' => 'website',
            'support.mobcontact_alias_replacement_path' => '/api/support/ticket',
        ]);

        $preRegistrationService = Mockery::mock(PreRegistrationService::class);
        $supportTicketService = Mockery::mock(SupportTicketService::class);

        $ticket = new SupportTicket();
        $ticket->id = 99;
        $ticket->ticket_number = 'TCK-20260228-ABC123';
        $ticket->status = SupportTicket::STATUS_OPEN;

        $supportTicketService
            ->shouldReceive('createTicket')
            ->once()
            ->withArgs(function (array $payload, string $source): bool {
                return $source === 'mobcontact_api'
                    && $payload['requester_email'] === 'user@example.com'
                    && $payload['requester_phone'] === '0400999888'
                    && $payload['subject'] === 'Legacy subject'
                    && $payload['description'] === 'Legacy body for local ticket creation.'
                    && $payload['category'] === 'order'
                    && $payload['priority'] === SupportTicket::PRIORITY_URGENT
                    && $payload['order_id'] === 123
                    && $payload['mikitchn_id'] === 456
                    && $payload['user_id'] === 789
                    && $payload['actor_type'] === 'guest'
                    && $payload['actor_id'] === null;
            })
            ->andReturn([
                'ticket' => $ticket,
                'duplicate' => false,
            ]);

        $controller = new WebApiToCurlController($preRegistrationService, $supportTicketService);
        $request = Request::create('/api/mobcontact', 'POST', [
            'Type' => 'order',
            'SuppliedEmail' => 'user@example.com',
            'SuppliedPhone' => '0400999888',
            'Subject' => 'Legacy subject',
            'Description' => 'Legacy body for local ticket creation.',
            'priority' => SupportTicket::PRIORITY_URGENT,
            'mitabl_Order_Id__c' => 123,
            'mitabl_micook_Id__c' => 456,
            'mitabl_Mifoodi_Id__c' => 789,
        ]);

        $response = $controller->mobContact($request);
        $payload = $response->getData(true);

        $this->assertSame(200, $response->getStatusCode());
        $this->assertTrue($payload['isSuccess']);
        $this->assertSame(99, $payload['data']['id']);
        $this->assertSame('TCK-20260228-ABC123', $payload['data']['ticket_number']);
        $this->assertSame('true', $response->headers->get('Deprecation'));
    }

    public function test_mobcontact_invalid_sunset_config_falls_back_to_default_cutover_date(): void
    {
        config([
            'support.mobcontact_alias_sunset' => 'not-a-date',
            'support.mobcontact_alias_replacement_path' => '/api/support/ticket',
        ]);

        $preRegistrationService = Mockery::mock(PreRegistrationService::class);
        $supportTicketService = Mockery::mock(SupportTicketService::class);
        $supportTicketService->shouldNotReceive('createTicket');

        $controller = new WebApiToCurlController($preRegistrationService, $supportTicketService);
        $request = Request::create('/api/mobcontact', 'POST', [
            'SuppliedEmail' => 'fallback@example.com',
            'Subject' => 'Fallback date test',
            'Description' => 'Uses honeypot path to avoid service call.',
            'website' => 'bot-value',
        ]);

        $response = $controller->mobContact($request);

        $this->assertSame(Carbon::parse('2026-12-31')->toRfc7231String(), $response->headers->get('Sunset'));
    }

    public function test_preregister_honeypot_accepts_without_persisting(): void
    {
        config([
            'support.honeypot_field' => 'website',
        ]);

        $preRegistrationService = Mockery::mock(PreRegistrationService::class);
        $preRegistrationService->shouldNotReceive('create');
        $supportTicketService = Mockery::mock(SupportTicketService::class);

        $controller = new WebApiToCurlController($preRegistrationService, $supportTicketService);
        $request = Request::create('/api/preregister', 'POST', [
            'FirstName' => 'Bot',
            'LastName' => 'Lead',
            'Email' => 'bot@example.com',
            'website' => 'https://spam.example.com',
        ]);

        $response = $controller->preRegister($request);
        $payload = $response->getData(true);

        $this->assertSame(200, $response->getStatusCode());
        $this->assertTrue($payload['isSuccess']);
        $this->assertTrue($payload['data']['accepted']);
    }

    public function test_phase_five_reconciliation_command_normalizes_and_reports_counts_duplicates_and_orphans(): void
    {
        DB::table('pre_registrations')->insert([
            [
                'first_name' => 'Lead',
                'last_name' => 'One',
                'email' => ' Lead@One.COM ',
                'phone' => ' 0400 11-22(33) ',
                'city' => 'Sydney',
                'interested_as' => 'cook',
                'source' => 'preregister_api',
                'status' => 'new',
                'consent_to_contact' => true,
                'duplicate_fingerprint' => 'dup-pre-1',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'first_name' => 'Lead',
                'last_name' => 'Two',
                'email' => 'lead.two@example.com',
                'phone' => '0400112234',
                'city' => 'Melbourne',
                'interested_as' => 'foodie',
                'source' => 'preregister_api',
                'status' => 'new',
                'consent_to_contact' => true,
                'duplicate_fingerprint' => 'dup-pre-1',
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);

        DB::table('support_tickets')->insert([
            [
                'ticket_number' => 'TCK-20260228-AAA111',
                'requester_email' => ' Legacy@Example.COM ',
                'requester_phone' => ' (0400) 77-88 99 ',
                'subject' => 'Subject A',
                'description' => 'Description A',
                'source' => 'mobcontact_api',
                'category' => 'order',
                'priority' => 'normal',
                'status' => 'open',
                'intake_fingerprint' => 'dup-ticket-1',
                'user_id' => null,
                'order_id' => null,
                'mikitchn_id' => null,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'ticket_number' => 'TCK-20260228-BBB222',
                'requester_email' => 'another@example.com',
                'requester_phone' => '0400123000',
                'subject' => 'Subject B',
                'description' => 'Description B',
                'source' => 'mobcontact_api',
                'category' => 'general',
                'priority' => 'high',
                'status' => 'open',
                'intake_fingerprint' => 'dup-ticket-1',
                'user_id' => null,
                'order_id' => null,
                'mikitchn_id' => null,
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);

        $exitCode = Artisan::call('phase5:cutover:reconcile', ['--normalize' => true]);
        $output = trim(Artisan::output());
        $json = json_decode($output, true);

        $this->assertSame(0, $exitCode);
        $this->assertIsArray($json);
        $this->assertSame(2, $json['counts']['pre_registrations']);
        $this->assertSame(2, $json['counts']['support_tickets']);
        $this->assertSame(1, $json['duplicates']['pre_registrations_by_fingerprint']);
        $this->assertSame(1, $json['duplicates']['support_tickets_by_intake_fingerprint']);
        $this->assertSame(0, $json['orphan_links']['support_tickets_user_id']);
        $this->assertSame(0, $json['orphan_links']['support_tickets_order_id']);
        $this->assertSame(0, $json['orphan_links']['support_tickets_mikitchn_id']);

        $this->assertSame('lead@one.com', DB::table('pre_registrations')->where('first_name', 'Lead')->where('last_name', 'One')->value('email'));
        $this->assertSame('0400112233', DB::table('pre_registrations')->where('first_name', 'Lead')->where('last_name', 'One')->value('phone'));
        $this->assertSame('legacy@example.com', DB::table('support_tickets')->where('ticket_number', 'TCK-20260228-AAA111')->value('requester_email'));
        $this->assertSame('0400778899', DB::table('support_tickets')->where('ticket_number', 'TCK-20260228-AAA111')->value('requester_phone'));
    }
}
