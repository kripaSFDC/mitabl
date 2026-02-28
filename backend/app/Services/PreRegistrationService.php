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
        $phone = $this->normalizePhone((string) ($payload['phone'] ?? ''));
        $city = trim((string) ($payload['city'] ?? ''));
        $interestedAs = $this->normalizeInterestedAs((string) ($payload['interested_as'] ?? 'foodie'));
        $notes = trim((string) ($payload['notes'] ?? ''));
        $consentToContact = (bool) ($payload['consent_to_contact'] ?? false);
        $communicationPreference = $this->normalizeCommunicationPreference($payload['communication_preference'] ?? null);
        if (! $consentToContact) {
            $communicationPreference = 'none';
        }

        $spamScore = $this->detectSpamScore($firstName, $lastName, $email, $notes);
        $status = $spamScore >= 90 ? PreRegistration::STATUS_SPAM : PreRegistration::STATUS_NEW;

        return [
            'first_name' => $firstName === '' ? 'Unknown' : $firstName,
            'last_name' => $lastName === '' ? 'User' : $lastName,
            'email' => $email !== '' ? $email : null,
            'phone' => $phone,
            'city' => $city !== '' ? $city : null,
            'interested_as' => $interestedAs,
            'source' => $this->normalizeSource($source),
            'status' => $status,
            'notes' => $notes !== '' ? $notes : null,
            'consent_to_contact' => $consentToContact,
            'consent_captured_at' => $consentToContact ? now() : null,
            'communication_preference' => $communicationPreference,
            'duplicate_fingerprint' => $this->buildDuplicateFingerprint(
                $email !== '' ? $email : null,
                $phone,
                $firstName,
                $lastName,
                $city
            ),
            'spam_score' => $spamScore,
            'spam_detected_at' => $status === PreRegistration::STATUS_SPAM ? now() : null,
        ];
    }

    private function buildDuplicateFingerprint(
        ?string $email,
        ?string $phone,
        string $firstName,
        string $lastName,
        string $city
    ): string {
        // Prefer contact channels so duplicate ingestion still works if optional profile fields vary.
        if ($email !== null || $phone !== null) {
            return hash('sha256', implode('|', [
                $email ?? 'no-email',
                $phone ?? 'no-phone',
            ]));
        }

        return hash('sha256', implode('|', [
            'no-email',
            'no-phone',
            Str::lower(trim($firstName)),
            Str::lower(trim($lastName)),
            Str::lower(trim($city)),
        ]));
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

    private function normalizePhone(string $phone): ?string
    {
        $phone = trim($phone);
        if ($phone === '') {
            return null;
        }

        $hasPlus = str_starts_with($phone, '+');
        $digits = preg_replace('/\D+/', '', $phone) ?? '';
        if ($digits === '') {
            return null;
        }

        return $hasPlus ? '+' . $digits : $digits;
    }

    private function normalizeInterestedAs(string $interestedAs): string
    {
        $normalized = Str::lower(trim($interestedAs));
        if (! in_array($normalized, ['cook', 'foodie', 'both'], true)) {
            return 'foodie';
        }

        return $normalized;
    }

    private function normalizeSource(string $source): string
    {
        $normalized = Str::lower(trim($source));
        $map = [
            'preregister_api' => 'website',
            'admin_panel' => 'admin',
            'website' => 'website',
            'referral' => 'referral',
            'campaign' => 'campaign',
            'admin' => 'admin',
        ];

        return $map[$normalized] ?? 'website';
    }

    private function normalizeCommunicationPreference(mixed $value): string
    {
        $normalized = Str::lower(trim((string) $value));
        if (! in_array($normalized, ['email', 'sms', 'phone', 'none'], true)) {
            return 'email';
        }

        return $normalized;
    }
}
