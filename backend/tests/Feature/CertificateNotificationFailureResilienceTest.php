<?php

namespace Tests\Feature;

use App\Jobs\SendCertificateReviewOutcomeJob;
use App\Models\AdminUser;
use App\Models\Certificate;
use App\Models\Mikitchn;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Notification;
use RuntimeException;
use Tests\TestCase;

class CertificateNotificationFailureResilienceTest extends TestCase
{
    use RefreshDatabase;

    public function test_certificate_outcome_job_does_not_throw_when_mail_and_notification_fail(): void
    {
        Mail::shouldReceive('to->sendNow')
            ->once()
            ->andThrow(new RuntimeException('SMTP unavailable'));
        Notification::shouldReceive('sendNow')
            ->once()
            ->andThrow(new RuntimeException('Notification unavailable'));

        AdminUser::query()->create([
            'name' => 'Admin',
            'email' => 'admin@example.test',
            'password' => bcrypt('password123'),
            'is_active' => true,
        ]);

        $user = User::query()->create([
            'role_id' => 2,
            'first_name' => 'Cook',
            'last_name' => 'One',
            'email' => 'cook@example.test',
            'password' => bcrypt('password123'),
            'phone' => '1234567890',
            'address' => 'Cook address',
        ]);

        $kitchen = Mikitchn::query()->create([
            'user_id' => $user->id,
            'name' => 'Kitchen One',
            'address' => 'Kitchen address',
            'phone' => '1234567890',
            'latitude' => 24.7,
            'longitude' => 46.7,
            'status' => 1,
            'open' => 1,
        ]);

        $certificate = Certificate::query()->create([
            'mikitchn_id' => $kitchen->id,
            'abn' => '12345678901',
            'first_name' => 'Cook',
            'last_name' => 'One',
            'certificate_no' => 'CERT-1',
            'certificate_doc' => 'certs/test.pdf',
            'abn_gst' => 1,
            'status' => 1,
            'reviewed_at' => now(),
            'reviewed_by' => 1,
        ]);

        (new SendCertificateReviewOutcomeJob($certificate->id))->handle();

        $this->assertTrue(true);
    }
}
