<?php

namespace App\Filament\Resources\CertificateResource\Pages;

use App\Filament\Resources\CertificateResource;
use Filament\Facades\Filament;
use Filament\Resources\Pages\CreateRecord;
use Illuminate\Validation\ValidationException;

class CreateCertificate extends CreateRecord
{
    protected static string $resource = CertificateResource::class;

    protected function mutateFormDataBeforeCreate(array $data): array
    {
        $status = (int) ($data['status'] ?? 0);

        if ($status === 1 && ! $this->hasValidDocument((string) ($data['certificate_doc'] ?? ''))) {
            throw ValidationException::withMessages([
                'certificate_doc' => 'Certificate document is missing or invalid. Approval requires a valid file.',
            ]);
        }

        if ($status === 2 && trim((string) ($data['rejection_reason'] ?? '')) === '') {
            throw ValidationException::withMessages([
                'rejection_reason' => 'Rejection reason is required when status is Rejected.',
            ]);
        }

        if (in_array($status, [1, 2], true)) {
            $data['reviewed_by'] = Filament::auth()->id();
            $data['reviewed_at'] = now();
        } else {
            $data['reviewed_by'] = null;
            $data['reviewed_at'] = null;
            $data['rejection_reason'] = null;
        }

        if ($status === 1) {
            $data['rejection_reason'] = null;
        }

        return $data;
    }

    private function hasValidDocument(string $documentPath): bool
    {
        $documentPath = trim($documentPath);
        if ($documentPath === '') {
            return false;
        }

        $extension = strtolower((string) pathinfo(parse_url($documentPath, PHP_URL_PATH) ?: $documentPath, PATHINFO_EXTENSION));

        return in_array($extension, ['pdf', 'jpg', 'jpeg', 'png', 'webp'], true);
    }
}
