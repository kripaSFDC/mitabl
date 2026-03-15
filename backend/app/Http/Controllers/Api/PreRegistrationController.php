<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\PreRegistration;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class PreRegistrationController extends Controller
{
    public function store(Request $request)
    {
        $validated = $request->validate([
            'first_name' => ['required', 'string', 'max:255'],
            'last_name' => ['required', 'string', 'max:255'],
            'email' => ['nullable', 'email', 'max:255'],
            'phone' => ['nullable', 'string', 'max:40'],
            'city' => ['nullable', 'string', 'max:255'],
            'interested_as' => ['required', Rule::in(['cook', 'foodie', 'both'])],
            'consent_to_contact' => ['nullable', 'boolean'],
            'communication_preference' => ['nullable', Rule::in(['email', 'phone', 'either'])],
            'notes' => ['nullable', 'string'],
        ]);

        if (empty($validated['email']) && empty($validated['phone'])) {
            return response()->json([
                'status' => 422,
                'isSuccess' => false,
                'isError' => 'Either email or phone is required.',
            ], 422);
        }

        $email = isset($validated['email']) ? strtolower(trim((string) $validated['email'])) : null;
        $phone = isset($validated['phone']) ? preg_replace('/\D+/', '', (string) $validated['phone']) : null;
        $fingerprint = hash('sha256', implode('|', [
            strtolower(trim($validated['first_name'])),
            strtolower(trim($validated['last_name'])),
            $email ?: '-',
            $phone ?: '-',
            strtolower(trim($validated['interested_as'])),
        ]));

        $duplicateQuery = PreRegistration::query()
            ->where(function ($query) use ($email, $phone, $fingerprint): void {
                if ($email !== null) {
                    $query->where('email', $email);
                }

                if ($phone !== null) {
                    $query->orWhere('phone', $phone);
                }

                // Backstop for rows that were created before contact normalization.
                $query->orWhere('duplicate_fingerprint', $fingerprint);
            });

        $payload = [
            'first_name' => trim($validated['first_name']),
            'last_name' => trim($validated['last_name']),
            'email' => $email,
            'phone' => $phone,
            'city' => $validated['city'] ?? null,
            'interested_as' => $validated['interested_as'],
            'source' => 'website',
            'status' => PreRegistration::STATUS_NEW,
            'notes' => $validated['notes'] ?? null,
            'consent_to_contact' => (bool) ($validated['consent_to_contact'] ?? false),
            'communication_preference' => $validated['communication_preference'] ?? 'email',
            'consent_captured_at' => ($validated['consent_to_contact'] ?? false) ? now() : null,
            'duplicate_fingerprint' => $fingerprint,
        ];

        $result = DB::transaction(function () use ($payload, $duplicateQuery): array {
            $duplicate = $duplicateQuery
                ->latest('id')
                ->first();

            if ($duplicate) {
                return [$duplicate, true];
            }

            return [PreRegistration::query()->create($payload), false];
        });

        [$preRegistration, $duplicate] = $result;

        return $this->responser([
            'id' => $preRegistration->id,
            'status' => $preRegistration->status,
            'duplicate' => $duplicate,
        ], 'Pre-registration received successfully.');
    }
}
