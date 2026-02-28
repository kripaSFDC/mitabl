<?php

namespace App\Filament\Resources\PreRegistrationResource\Pages;

use App\Filament\Resources\PreRegistrationResource;
use App\Models\PreRegistration;
use App\Services\PreRegistrationService;
use Filament\Resources\Pages\CreateRecord;
use Illuminate\Database\Eloquent\Model;

class CreatePreRegistration extends CreateRecord
{
    protected static string $resource = PreRegistrationResource::class;

    protected function handleRecordCreation(array $data): Model
    {
        /** @var PreRegistrationService $service */
        $service = app(PreRegistrationService::class);

        $result = $service->create([
            'first_name' => $data['first_name'] ?? null,
            'last_name' => $data['last_name'] ?? null,
            'email' => $data['email'] ?? null,
            'phone' => $data['phone'] ?? null,
            'city' => $data['city'] ?? null,
            'interested_as' => $data['interested_as'] ?? 'foodie',
            'consent_to_contact' => (bool) ($data['consent_to_contact'] ?? false),
            'communication_preference' => $data['communication_preference'] ?? 'email',
            'notes' => $data['notes'] ?? null,
        ], (string) ($data['source'] ?? 'admin_panel'));

        /** @var PreRegistration $registration */
        $registration = $result['registration'];

        if (! empty($data['status']) && in_array((string) $data['status'], PreRegistration::statuses(), true)) {
            $registration->status = (string) $data['status'];
            $registration->save();
        }

        return $registration;
    }
}
