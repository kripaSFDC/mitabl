<?php

namespace App\Filament\Resources\CertificateResource\Pages;

use App\Filament\Resources\CertificateResource;
use App\Jobs\SendCertificateReviewOutcomeJob;
use Filament\Facades\Filament;
use Filament\Actions;
use Filament\Resources\Pages\EditRecord;
use Illuminate\Validation\ValidationException;

class EditCertificate extends EditRecord
{
    protected static string $resource = CertificateResource::class;

    private bool $shouldDispatchOutcomeNotification = false;

    protected function getHeaderActions(): array
    {
        return [
            Actions\DeleteAction::make()
                ->requiresConfirmation()
                ->visible(fn (): bool => CertificateResource::canDelete($this->record)),
        ];
    }

    protected function mutateFormDataBeforeSave(array $data): array
    {
        $currentStatus = (int) $this->record->status;
        $nextStatus = (int) ($data['status'] ?? $currentStatus);

        if ($nextStatus === 1 && ! $this->hasValidDocument((string) ($data['certificate_doc'] ?? $this->record->certificate_doc))) {
            throw ValidationException::withMessages([
                'certificate_doc' => 'Certificate document is missing or invalid. Approval requires a valid file.',
            ]);
        }

        if ($nextStatus === 2 && trim((string) ($data['rejection_reason'] ?? '')) === '') {
            throw ValidationException::withMessages([
                'rejection_reason' => 'Rejection reason is required when status is Rejected.',
            ]);
        }

        if ($nextStatus === 1) {
            $data['rejection_reason'] = null;
            $data['reviewed_by'] = Filament::auth()->id();
            $data['reviewed_at'] = now();
        } elseif ($nextStatus === 2) {
            $data['reviewed_by'] = Filament::auth()->id();
            $data['reviewed_at'] = now();
        } elseif ($nextStatus === 0) {
            $data['reviewed_by'] = null;
            $data['reviewed_at'] = null;
            $data['rejection_reason'] = null;
        }

        $this->shouldDispatchOutcomeNotification = $nextStatus !== $currentStatus && in_array($nextStatus, [1, 2], true);

        return $data;
    }

    protected function afterSave(): void
    {
        if (! $this->shouldDispatchOutcomeNotification) {
            return;
        }

        $recipient = optional($this->record->mikitchn)->user;
        if ($recipient && $recipient->email) {
            SendCertificateReviewOutcomeJob::dispatch($this->record->id)->afterCommit();
        }
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
