<?php

namespace App\Services;

use App\Models\SupportTicket;
use App\Models\SupportTicketAttachment;
use App\Models\SupportTicketMessage;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use InvalidArgumentException;

class SupportAttachmentPolicyService
{
    /**
     * @param array<int, UploadedFile|string> $files
     */
    public function storeForMessage(
        SupportTicket $ticket,
        SupportTicketMessage $message,
        array $files,
        string $actorType,
        ?int $actorId
    ): void {
        if ($files === []) {
            return;
        }

        $this->validate($files);

        foreach ($files as $file) {
            if ($file instanceof UploadedFile) {
                $this->storeUploadedFile($ticket, $message, $file, $actorType, $actorId);
                continue;
            }

            if (is_string($file) && $file !== '') {
                $this->storeTemporaryPath($ticket, $message, $file, $actorType, $actorId);
            }
        }
    }

    /**
     * @param array<int, UploadedFile|string> $files
     */
    private function validate(array $files): void
    {
        $maxFiles = (int) config('support.attachments.max_files', 5);
        if (count($files) > $maxFiles) {
            throw new InvalidArgumentException("A maximum of {$maxFiles} attachments is allowed.");
        }

        $maxSizeBytes = (int) config('support.attachments.max_size_kb', 5120) * 1024;
        $allowedMimeTypes = array_values(array_filter(array_map(
            static fn ($value): string => strtolower(trim((string) $value)),
            (array) config('support.attachments.allowed_mime_types', [])
        )));

        foreach ($files as $file) {
            if ($file instanceof UploadedFile) {
                $size = (int) $file->getSize();
                $mime = strtolower(trim((string) $file->getMimeType()));
            } elseif (is_string($file) && $file !== '') {
                if (! Storage::disk('public')->exists($file)) {
                    throw new InvalidArgumentException('Attachment file does not exist.');
                }
                $size = (int) Storage::disk('public')->size($file);
                $mime = strtolower(trim((string) Storage::disk('public')->mimeType($file)));
            } else {
                throw new InvalidArgumentException('Attachment payload is invalid.');
            }

            if ($size <= 0 || $size > $maxSizeBytes) {
                throw new InvalidArgumentException('Attachment exceeds the allowed size limit.');
            }
            if ($mime === '' || ! in_array($mime, $allowedMimeTypes, true)) {
                throw new InvalidArgumentException('Attachment type is not allowed.');
            }
        }
    }

    private function assertMalwareSafe(UploadedFile $file): void
    {
        $blockedExtensions = array_values(array_filter(array_map(
            static fn ($value): string => strtolower(trim((string) $value)),
            (array) config('support.attachments.blocked_extensions', [])
        )));

        $extension = strtolower((string) $file->getClientOriginalExtension());
        if ($extension !== '' && in_array($extension, $blockedExtensions, true)) {
            throw new InvalidArgumentException('Attachment extension is blocked by security policy.');
        }

        $path = $file->getRealPath();
        if (! is_string($path) || $path === '' || ! is_file($path)) {
            throw new InvalidArgumentException('Attachment file is invalid.');
        }

        $sample = (string) file_get_contents($path, false, null, 0, 4096);
        $sampleLower = strtolower($sample);

        if (str_contains($sampleLower, '<?php') || str_contains($sampleLower, 'powershell')) {
            throw new InvalidArgumentException('Attachment content failed malware policy checks.');
        }

        $looksLikeExecutable = str_starts_with($sample, 'MZ');
        $mime = strtolower((string) $file->getMimeType());
        if ($looksLikeExecutable && ! in_array($mime, ['application/pdf'], true)) {
            throw new InvalidArgumentException('Attachment content failed malware policy checks.');
        }
    }

    private function storeUploadedFile(
        SupportTicket $ticket,
        SupportTicketMessage $message,
        UploadedFile $file,
        string $actorType,
        ?int $actorId
    ): void {
        $this->assertMalwareSafe($file);

        $safeName = Str::uuid() . '_' . preg_replace('/[^A-Za-z0-9._-]/', '_', $file->getClientOriginalName());
        $path = $file->storeAs('support-tickets/' . $ticket->ticket_number, $safeName, 'public');
        if (! is_string($path) || $path === '') {
            throw new InvalidArgumentException('Attachment upload failed.');
        }

        SupportTicketAttachment::create([
            'ticket_id' => $ticket->id,
            'message_id' => $message->id,
            'disk' => 'public',
            'path' => $path,
            'original_name' => (string) $file->getClientOriginalName(),
            'mime_type' => (string) $file->getMimeType(),
            'size' => (int) $file->getSize(),
            'uploaded_by_type' => $actorType,
            'uploaded_by_id' => $actorId,
            'sha256' => hash_file('sha256', $file->getRealPath()),
            'scan_status' => 'clean',
            'scanned_at' => now(),
        ]);
    }

    private function storeTemporaryPath(
        SupportTicket $ticket,
        SupportTicketMessage $message,
        string $temporaryPath,
        string $actorType,
        ?int $actorId
    ): void {
        $normalizedPath = ltrim(str_replace('\\', '/', $temporaryPath), '/');
        if (
            ! str_starts_with($normalizedPath, 'tmp/support-ticket-intake/')
            && ! str_starts_with($normalizedPath, 'tmp/support-ticket-replies/')
            && ! str_starts_with($normalizedPath, 'tmp/support-ticket-notes/')
        ) {
            throw new InvalidArgumentException('Attachment payload is invalid.');
        }

        $disk = Storage::disk('public');
        $stream = $disk->readStream($normalizedPath);
        if (! is_resource($stream)) {
            throw new InvalidArgumentException('Attachment upload failed.');
        }

        $filename = basename($normalizedPath);
        $this->assertFilenameExtensionAllowed($filename);
        $targetPath = 'support-tickets/' . $ticket->ticket_number . '/' . Str::uuid() . '_' . $filename;
        $written = $disk->writeStream($targetPath, $stream);
        if (is_resource($stream)) {
            fclose($stream);
        }
        if (! $written) {
            throw new InvalidArgumentException('Attachment upload failed.');
        }

        $contents = (string) $disk->get($targetPath);
        $lower = strtolower(substr($contents, 0, 4096));
        if (str_contains($lower, '<?php') || str_contains($lower, 'powershell')) {
            $disk->delete($targetPath);
            throw new InvalidArgumentException('Attachment content failed malware policy checks.');
        }

        $disk->delete($normalizedPath);

        SupportTicketAttachment::create([
            'ticket_id' => $ticket->id,
            'message_id' => $message->id,
            'disk' => 'public',
            'path' => $targetPath,
            'original_name' => $filename,
            'mime_type' => (string) $disk->mimeType($targetPath),
            'size' => (int) $disk->size($targetPath),
            'uploaded_by_type' => $actorType,
            'uploaded_by_id' => $actorId,
            'sha256' => hash('sha256', $contents),
            'scan_status' => 'clean',
            'scanned_at' => now(),
        ]);
    }

    private function assertFilenameExtensionAllowed(string $filename): void
    {
        $extension = strtolower((string) pathinfo($filename, PATHINFO_EXTENSION));
        if ($extension === '') {
            return;
        }

        $blockedExtensions = array_values(array_filter(array_map(
            static fn ($value): string => strtolower(trim((string) $value)),
            (array) config('support.attachments.blocked_extensions', [])
        )));

        if (in_array($extension, $blockedExtensions, true)) {
            throw new InvalidArgumentException('Attachment extension is blocked by security policy.');
        }
    }
}
