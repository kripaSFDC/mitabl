<?php

namespace App\Services;

use App\Models\PreRegistration;
use Illuminate\Support\Str;

class PreRegistrationService
{
    public function __construct(private CrmCommunicationService $communications)
    {
    }

    public function create(array $payload, string $source = 'marketing'): array
    {
        $normalized = $this->normalize($payload, $source);

        $existing = PreRegistration::query()
            ->where('duplicate_fingerprint', $normalized['duplicate_fingerprint'])
            ->where('created_at', '>=', now()->subMinutes((int) config('support.duplicate_window_minutes', 10)))
            ->first();

        if ($existing) {
            return ['registration' => $existing, 'duplicate' => true];
        }

        $registration = PreRegistration::create($normalized);

        if ($registration->status !== PreRegistration::STATUS_SPAM) {
            $this->communications->sendPreRegistrationAcknowledgement($registration);
        }

        return ['registration' => $registration, 'duplicate' => false];
    }

    private function normalize(array $payload, string $source): array
    {
        $firstName = trim((string) ($payload['first_name'] ?? ''));
        $lastName = trim((string) ($payload['last_name'] ?? ''));
        $email = Str::lower(trim((string) ($payload['email'] ?? '')));
        $phone = trim((string) ($payload['phone'] ?? ''));
        $city = trim((string) ($payload['city'] ?? ''));
        $interestedAs = Str::lower(trim((string) ($payload['interested_as'] ?? 'foodie')));
        $notes = trim((string) ($payload['notes'] ?? ''));

        $spamScore = $this->detectSpamScore($firstName, $lastName, $email, $notes);
        $status = $spamScore >= 90 ? PreRegistration::STATUS_SPAM : PreRegistration::STATUS_NEW;

        return [
            'first_name' => $firstName === '' ? 'Unknown' : $firstName,
            'last_name' => $lastName === '' ? 'User' : $lastName,
            'email' => $email !== '' ? $email : null,
            'phone' => $phone !== '' ? $phone : null,
            'city' => $city !== '' ? $city : null,
            'interested_as' => $interestedAs === '' ? 'foodie' : $interestedAs,
            'source' => $source,
            'status' => $status,
            'notes' => $notes !== '' ? $notes : null,
            'consent_to_contact' => (bool) ($payload['consent_to_contact'] ?? true),
            'duplicate_fingerprint' => hash('sha256', implode('|', [
                $email !== '' ? $email : 'no-email',
                $phone !== '' ? $phone : 'no-phone',
                $interestedAs !== '' ? $interestedAs : 'general',
                Str::lower(trim($firstName)),
                Str::lower(trim($lastName)),
                Str::lower(trim($city)),
            ])),
            'spam_score' => $spamScore,
            'spam_detected_at' => $status === PreRegistration::STATUS_SPAM ? now() : null,
        ];
    }

    private function detectSpamScore(string $firstName, string $lastName, string $email, string $notes): int
    {
        $score = 0;
        $content = Str::lower("{$firstName} {$lastName} {$email} {$notes}");
        foreach (['casino', 'forex', 'crypto', 'viagra', 'loan'] as $token) {
            if (Str::contains($content, $token)) {
                $score += 25;
            }
        }

        if ($email !== '' && ! filter_var($email, FILTER_VALIDATE_EMAIL)) {
            $score += 30;
        }

        if (strlen($firstName . $lastName) < 3) {
            $score += 20;
        }

        return min($score, 100);
    }
}
