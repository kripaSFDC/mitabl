<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\PreRegistration;
use App\Services\PreRegistrationService;
use Illuminate\Http\Client\ConnectionException;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class WebApiToCurlController extends Controller
{
    public function __construct(
        private PreRegistrationService $preRegistrationService
    ) {
    }

    public function preRegister(Request $request)
    {
        $payload = $request->all();
        if (! isset($payload['mobile']) && isset($payload['phone'])) {
            $payload['mobile'] = $payload['phone'];
        }
        $request->merge($payload);

        $honeypotField = (string) config('support.honeypot_field', 'website');
        $honeypotValue = $request->input($honeypotField);
        if (
            (is_string($honeypotValue) && trim($honeypotValue) !== '')
            || (is_array($honeypotValue) && $honeypotValue !== [])
        ) {
            return $this->responser(['accepted' => true], 'Your Registration Created Successfully');
        }

        $validated = $request->validate([
            'first_name' => ['nullable', 'string', 'max:255'],
            'last_name' => ['nullable', 'string', 'max:255'],
            'email' => ['nullable', 'email', 'max:255'],
            'mobile' => ['nullable', 'string', 'max:40'],
            'city' => ['nullable', 'string', 'max:120'],
            'interested_as' => ['nullable', Rule::in(['cook', 'foodie', 'both'])],
            'consent_to_contact' => ['nullable', 'boolean'],
            'communication_preference' => ['nullable', Rule::in(['email', 'sms', 'phone', 'none'])],
            'captcha_token' => ['nullable', 'string'],
            'g-recaptcha-response' => ['nullable', 'string'],
            $honeypotField => ['nullable'],
        ]);

        $this->validateCaptchaToken($validated['captcha_token'] ?? $validated['g-recaptcha-response'] ?? null);

        $result = $this->preRegistrationService->create([
            'first_name' => $validated['first_name'] ?? null,
            'last_name' => $validated['last_name'] ?? null,
            'email' => $validated['email'] ?? null,
            'phone' => $validated['mobile'] ?? null,
            'city' => $validated['city'] ?? null,
            'interested_as' => $validated['interested_as'] ?? 'foodie',
            'consent_to_contact' => (bool) ($validated['consent_to_contact'] ?? false),
            'communication_preference' => $validated['communication_preference'] ?? null,
        ], 'preregister_api');

        /** @var PreRegistration $registration */
        $registration = $result['registration'];

        return $this->responser([
            'id' => $registration->id,
            'status' => $registration->status,
            'duplicate' => $result['duplicate'],
        ], 'Your Registration Created Successfully');
    }

    private function validateCaptchaToken(?string $captchaToken): void
    {
        $secret = (string) config('services.recaptcha.secret');
        if ($secret === '' || ! $captchaToken) {
            return;
        }

        try {
            $response = Http::asForm()->post('https://www.google.com/recaptcha/api/siteverify', [
                'secret' => $secret,
                'response' => $captchaToken,
            ])->json();
        } catch (ConnectionException|\Throwable) {
            throw ValidationException::withMessages([
                'captcha_token' => [
                    'Captcha verification is temporarily unavailable.',
                ],
            ])->status(422);
        }

        if (! is_array($response) || ! ($response['success'] ?? false)) {
            throw ValidationException::withMessages([
                'captcha_token' => [
                    'Captcha verification failed.',
                ],
            ])->status(422);
        }
    }

}
