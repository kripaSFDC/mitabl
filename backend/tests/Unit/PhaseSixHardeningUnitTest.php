<?php

namespace Tests\Unit;

use App\Http\Controllers\Api\SupportTicketController;
use App\Http\Controllers\Api\WebApiToCurlController;
use App\Jobs\ProcessSupportTicketSlaEscalationJob;
use App\Models\Certificate;
use App\Models\PreRegistration;
use App\Models\SupportTicket;
use App\Models\User;
use App\Services\PreRegistrationService;
use App\Services\SupportTicketService;
use Database\Seeders\AdminRolePermissionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\Http;
use Illuminate\Validation\ValidationException;
use Mockery;
use Spatie\Permission\Models\Role;
use Tests\TestCase;

class PhaseSixHardeningUnitTest extends TestCase
{
    use RefreshDatabase;

    protected function tearDown(): void
    {
        Mockery::close();
        parent::tearDown();
    }

    public function test_phase_six_horizon_runtime_configuration_is_wired(): void
    {
        $this->assertContains(\App\Providers\HorizonServiceProvider::class, config('app.providers'));
        $this->assertSame('redis', config('horizon.defaults.supervisor-1.connection'));
        $this->assertSame(['crm-escalations', 'crm-communications', 'default'], config('horizon.defaults.supervisor-1.queue'));
        $this->assertSame(30, config('horizon.waits.redis:crm-escalations'));
        $this->assertSame(30, config('horizon.waits.redis:crm-communications'));
        $this->assertSame('crm-escalations', (new ProcessSupportTicketSlaEscalationJob(1, 'first_response'))->queue);
    }

    public function test_phase_six_captcha_is_enforced_for_preregister_and_mobcontact_when_secret_is_configured(): void
    {
        config(['services.recaptcha.secret' => 'phase6-test-secret']);
        Http::fake([
            'https://www.google.com/recaptcha/api/siteverify' => Http::response(['success' => false], 200),
        ]);

        $preRegistrationService = Mockery::mock(PreRegistrationService::class);
        $supportTicketService = Mockery::mock(SupportTicketService::class);
        $preRegistrationService->shouldNotReceive('create');
        $supportTicketService->shouldNotReceive('createTicket');

        $controller = new WebApiToCurlController($preRegistrationService, $supportTicketService);

        $preRegisterRequest = Request::create('/api/preregister', 'POST', [
            'Email' => 'captcha-preregister@example.com',
            'captcha_token' => 'invalid-token',
        ]);

        try {
            $controller->preRegister($preRegisterRequest);
            $this->fail('Expected preregister captcha validation to fail.');
        } catch (ValidationException $exception) {
            $this->assertSame(422, $exception->status);
            $this->assertArrayHasKey('captcha_token', $exception->errors());
        }

        $mobContactRequest = Request::create('/api/mobcontact', 'POST', [
            'SuppliedEmail' => 'captcha-mobcontact@example.com',
            'Subject' => 'Captcha check',
            'Description' => 'Captcha must fail this request.',
            'captcha_token' => 'invalid-token',
        ]);

        try {
            $controller->mobContact($mobContactRequest);
            $this->fail('Expected mobcontact captcha validation to fail.');
        } catch (ValidationException $exception) {
            $this->assertSame(422, $exception->status);
            $this->assertArrayHasKey('captcha_token', $exception->errors());
        }

        Http::assertSentCount(2);
    }

    public function test_phase_six_captcha_transport_failures_return_validation_errors_instead_of_500(): void
    {
        config(['services.recaptcha.secret' => 'phase6-test-secret']);
        Http::fake(function () {
            throw new \RuntimeException('captcha upstream down');
        });

        $preRegistrationService = Mockery::mock(PreRegistrationService::class);
        $supportTicketService = Mockery::mock(SupportTicketService::class);
        $preRegistrationService->shouldNotReceive('create');
        $supportTicketService->shouldNotReceive('createTicket');

        $webController = new WebApiToCurlController($preRegistrationService, $supportTicketService);
        $supportController = new SupportTicketController($supportTicketService);

        try {
            $webController->preRegister(Request::create('/api/preregister', 'POST', [
                'Email' => 'transport-preregister@example.com',
                'captcha_token' => 'token',
            ]));
            $this->fail('Expected preregister captcha transport failure to return validation error.');
        } catch (ValidationException $exception) {
            $this->assertSame(422, $exception->status);
            $this->assertArrayHasKey('captcha_token', $exception->errors());
        }

        try {
            $supportController->store(Request::create('/api/support/ticket', 'POST', [
                'requester_email' => 'transport-support@example.com',
                'subject' => 'Captcha transport',
                'description' => 'Transport failure should not produce 500.',
                'captcha_token' => 'token',
            ]));
            $this->fail('Expected support captcha transport failure to return validation error.');
        } catch (ValidationException $exception) {
            $this->assertSame(422, $exception->status);
            $this->assertArrayHasKey('captcha_token', $exception->errors());
        }
    }

    public function test_phase_six_preregister_accepts_grecaptcha_response_alias_on_success(): void
    {
        config(['services.recaptcha.secret' => 'phase6-test-secret']);
        Http::fake([
            'https://www.google.com/recaptcha/api/siteverify' => Http::response(['success' => true], 200),
        ]);

        $registration = new PreRegistration();
        $registration->id = 404;
        $registration->status = 'new';

        $preRegistrationService = Mockery::mock(PreRegistrationService::class);
        $supportTicketService = Mockery::mock(SupportTicketService::class);

        $preRegistrationService
            ->shouldReceive('create')
            ->once()
            ->withArgs(function (array $payload, string $source): bool {
                return $source === 'preregister_api'
                    && $payload['email'] === 'alias@example.com'
                    && $payload['interested_as'] === 'cook';
            })
            ->andReturn([
                'registration' => $registration,
                'duplicate' => false,
            ]);

        $controller = new WebApiToCurlController($preRegistrationService, $supportTicketService);

        $request = Request::create('/api/preregister', 'POST', [
            'FirstName' => 'Alias',
            'LastName' => 'Captcha',
            'Email' => 'alias@example.com',
            'mitabl_Interested_In__c' => 'cook',
            'g-recaptcha-response' => 'valid-token',
        ]);

        $response = $controller->preRegister($request);
        $payload = $response->getData(true);

        $this->assertSame(200, $response->getStatusCode());
        $this->assertTrue($payload['isSuccess']);
        $this->assertSame(404, $payload['data']['id']);
        Http::assertSentCount(1);
    }

    public function test_phase_six_support_ticket_controller_rejects_invalid_captcha_when_secret_is_configured(): void
    {
        config(['services.recaptcha.secret' => 'phase6-test-secret']);
        Http::fake([
            'https://www.google.com/recaptcha/api/siteverify' => Http::response(['success' => false], 200),
        ]);

        $supportTicketService = Mockery::mock(SupportTicketService::class);
        $supportTicketService->shouldNotReceive('createTicket');

        $controller = new SupportTicketController($supportTicketService);
        $request = Request::create('/api/support/ticket', 'POST', [
            'requester_email' => 'captcha-support@example.com',
            'subject' => 'Captcha support',
            'description' => 'This support request should fail captcha validation.',
            'captcha_token' => 'invalid-token',
        ]);

        try {
            $controller->store($request);
            $this->fail('Expected support/ticket captcha validation to fail.');
        } catch (ValidationException $exception) {
            $this->assertSame(422, $exception->status);
            $this->assertArrayHasKey('captcha_token', $exception->errors());
        }

        $legacyFieldRequest = Request::create('/api/support/ticket', 'POST', [
            'requester_email' => 'captcha-support-legacy@example.com',
            'subject' => 'Captcha support legacy field',
            'description' => 'Legacy recaptcha response field should also be validated.',
            'g-recaptcha-response' => 'invalid-token',
        ]);

        try {
            $controller->store($legacyFieldRequest);
            $this->fail('Expected support/ticket legacy captcha field validation to fail.');
        } catch (ValidationException $exception) {
            $this->assertSame(422, $exception->status);
            $this->assertArrayHasKey('captcha_token', $exception->errors());
        }

        Http::assertSentCount(2);
    }

    public function test_phase_six_horizon_gate_safely_denies_non_admin_users(): void
    {
        $user = User::create([
            'role_id' => 3,
            'first_name' => 'Front',
            'last_name' => 'User',
            'email' => 'phase6-front-' . uniqid() . '@example.com',
            'password' => bcrypt('password'),
            'phone' => 400111999,
            'address' => 'Riyadh',
        ]);

        $this->assertFalse(Gate::forUser($user)->check('viewHorizon'));
    }

    public function test_phase_six_sla_escalation_job_is_idempotent_for_first_response_breach(): void
    {
        $service = app(SupportTicketService::class);

        $ticket = $service->createTicket([
            'requester_email' => 'phase6-sla@example.com',
            'subject' => 'SLA idempotency',
            'description' => 'Validate breach marker is not duplicated.',
            'priority' => 'normal',
        ])['ticket'];

        $job = new ProcessSupportTicketSlaEscalationJob($ticket->id, 'first_response');
        $job->handle($service);

        $ticket->refresh();
        $this->assertNotNull($ticket->first_response_breached_at);
        $this->assertSame(1, $ticket->events()->where('event_type', 'sla_escalated')->count());

        $job->handle($service);
        $ticket->refresh();
        $this->assertSame(1, $ticket->events()->where('event_type', 'sla_escalated')->count());
    }

    public function test_phase_six_certificate_document_validation_guards_extensions(): void
    {
        $certificate = new Certificate();
        $method = new \ReflectionMethod(\App\Filament\Resources\CertificateResource::class, 'hasValidCertificateDocument');
        $method->setAccessible(true);

        $certificate->certificate_doc = '/storage/certificates/valid-file.pdf';
        $this->assertTrue($method->invoke(null, $certificate));

        $certificate->certificate_doc = 'https://cdn.example.com/certs/proof.jpeg?download=1';
        $this->assertTrue($method->invoke(null, $certificate));

        $certificate->certificate_doc = '/storage/certificates/malicious.exe';
        $this->assertFalse($method->invoke(null, $certificate));

        $certificate->certificate_doc = '';
        $this->assertFalse($method->invoke(null, $certificate));
    }

    public function test_phase_six_certificate_review_snapshot_detects_stale_edits(): void
    {
        $certificate = new Certificate();
        $certificate->updated_at = now();

        $method = new \ReflectionMethod(\App\Filament\Resources\CertificateResource::class, 'isReviewSnapshotCurrent');
        $method->setAccessible(true);

        $this->assertTrue($method->invoke(null, $certificate, $certificate->updated_at->toISOString()));
        $this->assertFalse($method->invoke(null, $certificate, now()->subMinute()->toISOString()));
        $this->assertTrue($method->invoke(null, $certificate, null));
    }

    public function test_phase_six_policy_permission_role_boundaries_from_seeder(): void
    {
        $this->seed(AdminRolePermissionSeeder::class);

        $platformAdmin = Role::findByName('platform_admin', 'admin');
        $customerService = Role::findByName('customer_service', 'admin');
        $operations = Role::findByName('operations', 'admin');
        $superAdmin = Role::findByName('super_admin', 'admin');

        $this->assertTrue($platformAdmin->hasPermissionTo('policy_changes.publish'));
        $this->assertFalse($customerService->hasPermissionTo('policy_changes.publish'));
        $this->assertFalse($operations->hasPermissionTo('policy_changes.publish'));
        $this->assertTrue($superAdmin->hasPermissionTo('policy_changes.publish'));
    }

    public function test_phase_six_load_and_dr_artifacts_include_required_hardening_switches(): void
    {
        $supportLoad = (string) file_get_contents(base_path('../deploy/load-tests/support-intake-load-test.js'));
        $loadReadme = (string) file_get_contents(base_path('../deploy/load-tests/README.md'));
        $drRunbook = (string) file_get_contents(base_path('../docs/phase6_hardening_runbook.md'));
        $drScript = (string) file_get_contents(base_path('../deploy/scripts/validate-backup-restore.ps1'));

        $this->assertStringContainsString('CAPTCHA_TOKEN', $supportLoad);
        $this->assertStringContainsString('captcha_token', $supportLoad);
        $this->assertStringContainsString('/api/support/ticket', $supportLoad);
        $this->assertStringContainsString('CAPTCHA_TOKEN', $loadReadme);
        $this->assertStringContainsString('-ExecutionPolicy Bypass', $drRunbook);
        $this->assertStringContainsString('RequiredScopes', $drScript);
        $this->assertStringContainsString('RestoreEvidenceFile', $drScript);
    }
}
